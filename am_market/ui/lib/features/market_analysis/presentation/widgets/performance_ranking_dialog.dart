import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/models/indices_performance_model.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';

/// Ranking list body shared by mobile sheet and desktop dialog.
class PerformanceRankingPanel extends StatelessWidget {
  const PerformanceRankingPanel({
    super.key,
    required this.data,
    this.scrollController,
    this.focusSymbol,
  });

  final MonthlyIndicesPerformance data;
  final ScrollController? scrollController;
  final String? focusSymbol;

  @override
  Widget build(BuildContext context) {
    final focus = focusSymbol?.trim().toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 10, 4),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ModuleColors.market.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.leaderboard_rounded,
                  size: 17,
                  color: ModuleColors.market,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance',
                      style: context.text.sectionTitle(compact: true).copyWith(
                            color: MarketColors.textPrimary(context),
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.monthName} ${data.year}',
                      style: context.text.caption().copyWith(
                            color: MarketColors.textMuted(context),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  color: MarketColors.textMuted(context),
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Divider(
            height: 1,
            color: MarketColors.borderDefault(context).withValues(alpha: 0.55),
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
            itemCount: data.allIndices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final perf = data.allIndices[index];
              final isPositive = perf.returnPercentage >= 0;
              final rank = index + 1;
              final isFocus = focus != null &&
                  perf.symbol.trim().toUpperCase() == focus;
              final accent = isPositive
                  ? MarketColors.positive(context)
                  : MarketColors.negative(context);
              final bg = isPositive
                  ? MarketColors.positiveBg(context)
                  : MarketColors.negativeBg(context);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isFocus
                      ? ModuleColors.market.withValues(alpha: isDark ? 0.14 : 0.08)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocus
                        ? ModuleColors.market.withValues(alpha: 0.65)
                        : MarketColors.borderDefault(context)
                            .withValues(alpha: 0.45),
                    width: isFocus ? 1.4 : 1,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: bg,
                    child: Text(
                      '$rank',
                      style: context.text.caption().copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  title: Text(
                    perf.symbol,
                    style: context.text.body().copyWith(
                          color: MarketColors.textPrimary(context),
                          fontWeight:
                              isFocus ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 13.5,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${perf.returnPercentage.toStringAsFixed(2)}%',
                      style: context.text.body().copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Responsive ranking overlay: bottom sheet on mobile, dialog on desktop.
class PerformanceRankingDialog extends StatelessWidget {
  final MonthlyIndicesPerformance data;
  final String? focusSymbol;

  const PerformanceRankingDialog({
    Key? key,
    required this.data,
    this.focusSymbol,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    MonthlyIndicesPerformance data, {
    String? focusSymbol,
  }) async {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final colors = Theme.of(context).extension<AppColorsTheme>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColorsTheme.dark
            : AppColorsTheme.light);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    GlobalBottomNavVisibility.pushModalLock();
    try {
      if (isMobile) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.45),
          builder: (ctx) => DraggableScrollableSheet(
            // 60% viewport — list scrolls inside the sheet.
            initialChildSize: 0.60,
            maxChildSize: 0.85,
            minChildSize: 0.40,
            builder: (ctx, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: colors.cardSurface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Expanded(
                      child: PerformanceRankingPanel(
                        data: data,
                        scrollController: scrollController,
                        focusSymbol: focusSymbol,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
            child: Material(
              color: colors.cardSurface,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              elevation: 8,
              child: PerformanceRankingPanel(
                data: data,
                focusSymbol: focusSymbol,
              ),
            ),
          ),
        ),
      );
    } finally {
      GlobalBottomNavVisibility.popModalLock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PerformanceRankingPanel(data: data, focusSymbol: focusSymbol);
  }
}
