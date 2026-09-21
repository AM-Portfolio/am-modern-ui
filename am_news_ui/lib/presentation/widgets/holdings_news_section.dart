import 'dart:async';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_news_ui/domain/models/news_models.dart';
import 'package:am_news_ui/presentation/providers/news_provider.dart';
import 'package:am_news_ui/presentation/widgets/glass_card.dart';
import 'package:am_news_ui/presentation/widgets/news_section_viewport.dart';
import 'package:am_news_ui/presentation/widgets/news_story_tiles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Multi-symbol holdings / basket / book news (holdings symbols only).
class HoldingsNewsSection extends ConsumerStatefulWidget {
  const HoldingsNewsSection({
    super.key,
    required this.symbols,
    required this.surface,
    this.title = 'News',
    this.emptyMessage = 'No recent news for these symbols',
    this.embedInScroll = false,
  });

  final List<String> symbols;
  final NewsUiSurface surface;
  final String title;
  final String emptyMessage;

  /// When true, skip [NewsSectionViewport] (natural height inside a parent scroll).
  final bool embedInScroll;

  @override
  ConsumerState<HoldingsNewsSection> createState() =>
      _HoldingsNewsSectionState();
}

class _HoldingsNewsSectionState extends ConsumerState<HoldingsNewsSection> {
  Set<String> _subscribed = {};

  Future<void> _subscribeQuotes(List<NewsCard> cards) async {
    final symbols = <String>{};
    for (final card in cards) {
      for (final s in card.symbols) {
        final t = s.trim().toUpperCase();
        if (t.isNotEmpty) symbols.add(t);
      }
    }
    for (final s in widget.symbols) {
      final t = s.trim().toUpperCase();
      if (t.isNotEmpty) symbols.add(t);
    }
    if (symbols.isEmpty || setEquals(_subscribed, symbols)) return;
    _subscribed = symbols;
    try {
      final service = await ref.read(priceServiceProvider.future);
      final list = symbols.toList();
      final indexes = list.where(isNewsIndexSymbol).toList();
      final stocks = list.where((s) => !isNewsIndexSymbol(s)).toList();
      if (stocks.isNotEmpty) await service.subscribe(stocks);
      if (indexes.isNotEmpty) {
        await service.subscribe(indexes, isIndexSymbol: true);
      }
    } catch (_) {}
  }

  Widget _maybeViewport(Widget child) {
    if (widget.embedInScroll) return child;
    return NewsSectionViewport(child: child);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(newsUiSurfaceEnabledProvider(widget.surface));
    final key = newsSymbolsProviderKey(widget.symbols);
    if (!enabled || key.isEmpty) return const SizedBox.shrink();

    final insight = ref.watch(newsInsightForSymbolsProvider(key));
    final quotes = ref.watch(priceStreamProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <String, QuoteChange>{},
        );

    return _maybeViewport(
      insight.when(
        loading: () => const AmGlassCard(
          surfaceAlpha: 0.32,
          padding: EdgeInsets.all(16),
          child: SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (_, __) => AmGlassCard(
          surfaceAlpha: 0.32,
          padding: const EdgeInsets.all(16),
          child: AmErrorWidget(
            message: 'News unavailable',
            onRetry: () => ref.invalidate(newsInsightForSymbolsProvider(key)),
          ),
        ),
        data: (data) {
          final cards = filterHoldingsNewsForSymbols(data, widget.symbols);
          unawaited(_subscribeQuotes(cards));
          return AmGlassCard(
            surfaceAlpha: 0.32,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (cards.isEmpty)
                  Text(
                    widget.emptyMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else ...[
                  NewsFeaturedStory(card: cards.first, quotes: quotes),
                  for (final card in cards.skip(1).take(4))
                    NewsCompactRow(card: card, quotes: quotes),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
