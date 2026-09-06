import 'dart:async';

import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/news_models.dart';
import 'package:am_dashboard_ui/presentation/providers/news_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/glass_card.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_feed_tab.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_mobile_section.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_web_section.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardNewsSection extends ConsumerStatefulWidget {
  const DashboardNewsSection({super.key});

  @override
  ConsumerState<DashboardNewsSection> createState() =>
      _DashboardNewsSectionState();
}

class _DashboardNewsSectionState extends ConsumerState<DashboardNewsSection> {
  NewsFeedTab _tab = NewsFeedTab.currentAffairs;
  Set<String> _subscribed = {};

  Future<void> _subscribeQuotes(InsightNews data) async {
    final symbols = uniqueNewsSymbols(data);
    final next = symbols.toSet();
    if (next.isEmpty || setEquals(_subscribed, next)) return;
    _subscribed = next;
    try {
      final service = await ref.read(priceServiceProvider.future);
      final indexes = symbols.where(isNewsIndexSymbol).toList();
      final stocks = symbols.where((s) => !isNewsIndexSymbol(s)).toList();
      if (stocks.isNotEmpty) {
        await service.subscribe(stocks);
      }
      if (indexes.isNotEmpty) {
        await service.subscribe(indexes, isIndexSymbol: true);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(newsUiEnabledProvider);
    ref.listen(newsInsightProvider, (prev, next) {
      final data = next.asData?.value;
      if (data != null) unawaited(_subscribeQuotes(data));
    });
    final insight = ref.watch(newsInsightProvider);
    final quotes = ref.watch(priceStreamProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <String, QuoteChange>{},
        );

    if (!enabled) {
      return const SizedBox.shrink();
    }

    return insight.when(
      loading: () => const AmGlassCard(
        padding: EdgeInsets.all(16),
        child: _NewsSkeleton(),
      ),
      error: (_, __) => AmGlassCard(
        padding: const EdgeInsets.all(16),
        child: AmErrorWidget(
          message: 'News is unavailable',
          onRetry: () => ref.invalidate(newsInsightProvider),
        ),
      ),
      data: (data) {
        unawaited(_subscribeQuotes(data));
        final isMobile = AmBreakpoints.isMobileContext(context);
        if (isMobile) {
          return NewsMobileSection(
            data: data,
            quotes: quotes,
            tab: _tab,
            onTabChanged: (tab) => setState(() => _tab = tab),
          );
        }
        return NewsWebSection(
          data: data,
          quotes: quotes,
          tab: _tab,
          onTabChanged: (tab) => setState(() => _tab = tab),
        );
      },
    );
  }
}

class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
