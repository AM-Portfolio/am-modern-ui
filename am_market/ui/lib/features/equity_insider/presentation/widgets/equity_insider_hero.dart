import '../../../../core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../providers/equity_insider_provider.dart';
import 'equity_insider_header_card.dart';

/// Full hero (bar + description). Prefer [EquityInsiderHeroBar] /
/// [EquityInsiderHeroDescription] when the bar is pinned separately.
class EquityInsiderHero extends ConsumerWidget {
  final String symbol;

  const EquityInsiderHero({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EquityInsiderHeroBar(symbol: symbol),
        EquityInsiderHeroDescription(symbol: symbol),
      ],
    );
  }
}

/// Sticky identity strip: logo, name, exchange chips, LTP, star.
class EquityInsiderHeroBar extends ConsumerWidget {
  final String symbol;
  final VoidCallback? onBack;

  const EquityInsiderHeroBar({
    super.key,
    required this.symbol,
    this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeExchange = ref.watch(selectedExchangeProvider);
    final asyncData = ref.watch(fundamentalProfileProvider(
      EquityFundamentalQuery(symbol: symbol, exchange: activeExchange),
    ));

    return asyncData.when(
      data: (data) {
        if (data == null) return const Text('No profile data');
        return Align(
          alignment: Alignment.topCenter,
          child: EquityInsiderHeaderCard(
            symbol: symbol,
            companyName: data.companyName ?? data.symbol ?? symbol,
            currentPrice: data.currentPrice,
            dayChange: data.dayChange,
            dayChangePercent: data.dayChangePercent,
          ),
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Text(
        'Error loading profile: $e',
        style: TextStyle(color: context.statusError),
      ),
    );
  }
}

/// Company description + sector/industry (scrolls under pin).
class EquityInsiderHeroDescription extends ConsumerWidget {
  final String symbol;

  const EquityInsiderHeroDescription({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeExchange = ref.watch(selectedExchangeProvider);
    final asyncData = ref.watch(fundamentalProfileProvider(
      EquityFundamentalQuery(symbol: symbol, exchange: activeExchange),
    ));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return asyncData.when(
          data: (data) {
            final description = data?.description;
            final hasDescription =
                description != null && description.isNotEmpty;

            final sector = data?.sector;
            final industry = data?.industry;
            final hasSector = sector != null && sector.isNotEmpty;
            final hasIndustry = industry != null && industry.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasSector || hasIndustry)
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xs),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (hasSector) _MetaBadge(text: sector),
                        if (hasIndustry) _MetaBadge(text: industry),
                      ],
                    ),
                  ),
                if (hasDescription)
                  Padding(
                    padding: EdgeInsets.only(
                      top: isMobile ? AppSpacing.xs : AppSpacing.sm,
                    ),
                    child: _ExpandableDescription(
                      text: description,
                      collapsedLines: 2,
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final fg = context.marketTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: context.text.caption(compact: true).copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String text;
  final int collapsedLines;

  const _ExpandableDescription({
    required this.text,
    this.collapsedLines = 2,
  });

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.market;
    final textStyle = context.text.bodyMuted(compact: true).copyWith(
          color: context.textSecondary,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: textStyle),
          maxLines: widget.collapsedLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;
        if (!isOverflowing) {
          return Text(widget.text, style: textStyle);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                maxLines: _isExpanded ? null : widget.collapsedLines,
                overflow:
                    _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadii.xs),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xxs,
                  horizontal: AppSpacing.xxs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Show less' : 'See more',
                      style: context.text.label(compact: true).copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(width: AppSpacing.xxs),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: AppTypeScale.h5,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
