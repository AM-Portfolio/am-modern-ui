import 'dart:async';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_news_ui/domain/models/news_models.dart';
import 'package:am_news_ui/presentation/providers/news_provider.dart';
import 'package:am_news_ui/presentation/widgets/glass_card.dart';
import 'package:am_news_ui/presentation/widgets/news_pending_retry.dart';
import 'package:am_news_ui/presentation/widgets/news_relative_time.dart';
import 'package:am_news_ui/presentation/widgets/news_section_viewport.dart';
import 'package:am_news_ui/presentation/widgets/news_story_tiles.dart';
import 'package:am_news_ui/presentation/widgets/news_thumbnail.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Multi-symbol holdings / basket / book news (holdings symbols only).
///
/// Opens **collapsed** with a compact featured preview bar; tap expands the
/// existing feed. Does not persist expand across page reloads.
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

class _HoldingsNewsSectionState extends ConsumerState<HoldingsNewsSection>
    with NewsPendingRetryMixin {
  Set<String> _subscribed = {};

  /// Collapsed by default so the holdings table keeps vertical space.
  bool _expanded = false;

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

  /// Scrolls [body] only; header stays pinned above.
  Widget _scrollableBody(Widget body) {
    final padded = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: body,
    );
    if (widget.embedInScroll) return padded;
    return NewsSectionViewport(child: padded);
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  Widget _shell({
    required Widget headerPreview,
    Widget? body,
  }) {
    return AmGlassCard(
      surfaceAlpha: 0.32,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _NewsCollapsedBar(
            title: widget.title,
            expanded: _expanded,
            onToggle: _toggleExpanded,
            preview: headerPreview,
          ),
          if (_expanded && body != null) _scrollableBody(body),
        ],
      ),
    );
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

    return insight.when(
      loading: () => _shell(
        headerPreview: const _BarStatusPreview(loading: true),
        body: const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => _shell(
        headerPreview: const _BarStatusPreview(label: 'News unavailable'),
        body: AmErrorWidget(
          message: 'News unavailable',
          onRetry: () => ref.invalidate(newsInsightForSymbolsProvider(key)),
        ),
      ),
      data: (data) {
        final cards = filterHoldingsNewsForSymbols(data, widget.symbols);
        schedulePendingIngestRetry(
          data: data,
          cards: cards,
          invalidate: () =>
              ref.invalidate(newsInsightForSymbolsProvider(key)),
        );
        unawaited(_subscribeQuotes(cards));

        final emptyLabel = holdingsNewsEmptyLabel(
          data: data,
          fallback: widget.emptyMessage,
          pendingRetryDone: pendingIngestRetryDone,
        );

        if (cards.isEmpty) {
          return _shell(
            headerPreview: _BarStatusPreview(label: emptyLabel),
            body: Text(
              emptyLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final featured = cards.first;
        return _shell(
          headerPreview: _FeaturedBarPreview(card: featured),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              NewsFeaturedStory(card: featured, quotes: quotes),
              for (final card in cards.skip(1).take(4))
                NewsCompactRow(card: card, quotes: quotes),
            ],
          ),
        );
      },
    );
  }
}

class _NewsCollapsedBar extends StatelessWidget {
  const _NewsCollapsedBar({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.preview,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.portfolio;
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final barH = isCompact ? 48.0 : 52.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: SizedBox(
          height: barH,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 12,
              vertical: 6,
            ),
            child: Row(
              children: [
                Icon(Icons.newspaper_rounded, size: 18, color: accent),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 13 : 14,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 22,
                  color: context.colors.divider.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 8),
                Expanded(child: preview),
                const SizedBox(width: 6),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedBarPreview extends StatelessWidget {
  const _FeaturedBarPreview({required this.card});

  final NewsCard card;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final thumb = isCompact ? 40.0 : 48.0;
    final time = formatNewsRelativeTime(card.publishedAt);
    final hasThumb = card.thumbnail?.trim().isNotEmpty ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showTime = time.isNotEmpty && constraints.maxWidth >= 220;
        return Row(
          children: [
            if (hasThumb) ...[
              NewsThumbnail(
                url: card.thumbnail,
                width: thumb,
                height: thumb * 0.72,
              ),
              SizedBox(width: isCompact ? 6 : 8),
            ],
            Expanded(
              child: Text(
                card.heading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: isCompact ? 12 : 13,
                  height: 1.2,
                ),
              ),
            ),
            if (showTime) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: context.colors.textSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BarStatusPreview extends StatelessWidget {
  const _BarStatusPreview({
    this.label,
    this.loading = false,
  });

  final String? label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ModuleColors.portfolio,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading…',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Text(
      label ?? 'No news available',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: context.colors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
