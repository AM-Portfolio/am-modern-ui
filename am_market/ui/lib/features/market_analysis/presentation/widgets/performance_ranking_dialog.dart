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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Performance · ${data.monthName} ${data.year}',
                  style: context.text.sectionTitle(compact: true).copyWith(
                        color: MarketColors.textPrimary(context),
                      ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: MarketColors.textMuted(context),
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        Divider(color: MarketColors.borderDefault(context), height: 16),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            itemCount: data.allIndices.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: MarketColors.borderDefault(context).withValues(alpha: 0.5),
            ),
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

              return Container(
                decoration: isFocus
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ModuleColors.market.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                      )
                    : null,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: CircleAvatar(
                    backgroundColor: bg,
                    child: Text(
                      '$rank',
                      style: context.text.caption().copyWith(
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  title: Text(
                    perf.symbol,
                    style: context.text.body().copyWith(
                          color: MarketColors.textPrimary(context),
                          fontWeight:
                              isFocus ? FontWeight.w700 : FontWeight.w500,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${isPositive ? '+' : ''}${perf.returnPercentage.toStringAsFixed(2)}%',
                    style: context.text.body().copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
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

    if (isMobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.45,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colors.cardSurface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
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
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
          child: Material(
            color: colors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: PerformanceRankingPanel(
              data: data,
              focusSymbol: focusSymbol,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PerformanceRankingPanel(data: data, focusSymbol: focusSymbol);
  }
}
