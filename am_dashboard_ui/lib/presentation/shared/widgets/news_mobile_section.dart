import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/news_models.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/glass_card.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_feed_header.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_feed_tab.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_story_tiles.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

class NewsMobileSection extends StatelessWidget {
  const NewsMobileSection({
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
  Widget build(BuildContext context) {
    final cards = tab == NewsFeedTab.currentAffairs
        ? data.currentAffairs
        : data.holdings;
    final featured = cards.isEmpty ? null : cards.first;
    final rest = cards.length > 1 ? cards.sublist(1) : const <NewsCard>[];

    return AmGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NewsFeedHeader(tab: tab, onTabChanged: onTabChanged),
          const SizedBox(height: AppSpacing.sm),
          if (cards.isEmpty)
            Text(
              tab.emptyLabel,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontFamily: 'Inter',
              ),
            )
          else ...[
            if (featured != null)
              NewsFeaturedStory(
                card: featured,
                quotes: quotes,
                compact: true,
              ),
            for (final card in rest)
              NewsCompactRow(
                card: card,
                quotes: quotes,
                compact: true,
              ),
          ],
        ],
      ),
    );
  }
}
