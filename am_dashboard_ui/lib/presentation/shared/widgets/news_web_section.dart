import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/news_models.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/glass_card.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_feed_header.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_feed_tab.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_pager.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_story_tiles.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

class NewsWebSection extends StatefulWidget {
  const NewsWebSection({
    super.key,
    required this.data,
    required this.quotes,
    required this.tab,
    required this.onTabChanged,
  });

  final InsightNews data;
  final Map<String, QuoteChange> quotes;
  final NewsFeedTab tab;
  final ValueChanged<NewsFeedTab> onTabChanged;

  @override
  State<NewsWebSection> createState() => _NewsWebSectionState();
}

class _NewsWebSectionState extends State<NewsWebSection> {
  static const _pageSize = 10;
  int _page = 0;

  @override
  void didUpdateWidget(covariant NewsWebSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab) {
      _page = 0;
    }
  }

  List<NewsCard> get _cards => widget.tab == NewsFeedTab.currentAffairs
      ? widget.data.currentAffairs
      : widget.data.holdings;

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    final pageCount =
        cards.isEmpty ? 1 : ((cards.length + _pageSize - 1) ~/ _pageSize);
    final safePage = _page.clamp(0, pageCount - 1);
    if (safePage != _page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _page = safePage);
      });
    }
    final pageCards =
        cards.skip(safePage * _pageSize).take(_pageSize).toList();
    final featured = pageCards.isEmpty ? null : pageCards.first;
    final rest =
        pageCards.length > 1 ? pageCards.sublist(1) : const <NewsCard>[];

    return AmGlassCard(
      surfaceAlpha: 0.32,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NewsFeedHeader(
            tab: widget.tab,
            onTabChanged: (tab) {
              setState(() => _page = 0);
              widget.onTabChanged(tab);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (cards.isEmpty)
            Text(
              widget.tab.emptyLabel,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontFamily: 'Inter',
              ),
            )
          else ...[
            if (featured != null)
              NewsFeaturedStory(card: featured, quotes: widget.quotes),
            for (final card in rest)
              NewsCompactRow(card: card, quotes: widget.quotes),
            if (cards.length > _pageSize)
              NewsPager(
                page: safePage,
                pageCount: pageCount,
                onPrevious: safePage > 0
                    ? () => setState(() => _page = safePage - 1)
                    : null,
                onNext: safePage < pageCount - 1
                    ? () => setState(() => _page = safePage + 1)
                    : null,
              ),
          ],
        ],
      ),
    );
  }
}
