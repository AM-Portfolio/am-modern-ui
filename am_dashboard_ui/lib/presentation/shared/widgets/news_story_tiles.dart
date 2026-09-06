import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/news_models.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_article_opener.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_relative_time.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_symbol_chip.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/news_thumbnail.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

class NewsFeaturedStory extends StatelessWidget {
  const NewsFeaturedStory({
    super.key,
    required this.card,
    required this.quotes,
    this.compact = false,
  });

  final NewsCard card;
  final Map<String, QuoteChange> quotes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openNewsArticle(card.articleLink),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: compact ? _mobile(context) : _horizontal(context),
    );
  }

  bool get _hasImage => card.thumbnail?.trim().isNotEmpty ?? false;

  Widget _mobile(BuildContext context) {
    if (!_hasImage) {
      return _storyCopy(
        context,
        headingSize: 14,
        summaryLines: 2,
        maxSymbols: 2,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NewsThumbnail(url: card.thumbnail, width: 96, height: 96),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _storyCopy(
            context,
            headingSize: 14,
            summaryLines: 2,
            maxSymbols: 2,
          ),
        ),
      ],
    );
  }

  Widget _horizontal(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_hasImage) {
          return _storyCopy(context, headingSize: 16, summaryLines: 3);
        }
        final imageWidth = constraints.maxWidth * 0.4;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NewsThumbnail(
              url: card.thumbnail,
              width: imageWidth,
              height: 160,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _storyCopy(context, headingSize: 16, summaryLines: 3),
            ),
          ],
        );
      },
    );
  }

  Widget _storyCopy(
    BuildContext context, {
    required double headingSize,
    required int summaryLines,
    int? maxSymbols,
  }) {
    final time = formatNewsRelativeTime(card.publishedAt);
    final symbols = maxSymbols == null
        ? card.symbols
        : card.symbols.take(maxSymbols).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (time.isNotEmpty)
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: time == 'JUST NOW'
                      ? context.colors.statusError
                      : context.colors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            for (final symbol in symbols)
              NewsSymbolChip(
                symbol: symbol,
                quote: quotes[symbol] ?? quotes[symbol.toUpperCase()],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          card.heading,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: headingSize,
            height: 1.3,
            color: context.colors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        if (card.summary.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            card.summary.trim(),
            maxLines: summaryLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: context.colors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Read story',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: ModuleColors.dashboard,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}

class NewsCompactRow extends StatelessWidget {
  const NewsCompactRow({
    super.key,
    required this.card,
    required this.quotes,
    this.compact = false,
  });

  final NewsCard card;
  final Map<String, QuoteChange> quotes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final time = formatNewsRelativeTime(card.publishedAt);
    final thumb = compact ? 56.0 : 72.0;
    final hasImage = card.thumbnail?.trim().isNotEmpty ?? false;
    final symbols = compact ? card.symbols.take(2).toList() : card.symbols;
    return InkWell(
      onTap: () => openNewsArticle(card.articleLink),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              NewsThumbnail(url: card.thumbnail, width: thumb, height: thumb),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final symbol in symbols)
                              NewsSymbolChip(
                                symbol: symbol,
                                quote: quotes[symbol] ??
                                    quotes[symbol.toUpperCase()],
                              ),
                          ],
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.heading,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      height: 1.3,
                      color: context.colors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
