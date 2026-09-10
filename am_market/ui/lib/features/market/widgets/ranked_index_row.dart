import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';

/// One ranked index row: rank · name · tag · LTP/change · bar · % badge.
class RankedIndexRow extends StatelessWidget {
  const RankedIndexRow({
    super.key,
    required this.rank,
    required this.data,
    required this.category,
    required this.ltp,
    required this.change,
    required this.pChange,
    required this.barFraction,
    required this.isSelected,
    required this.onTap,
  });

  final int rank;
  final StockIndicesMarketData data;
  final String category;
  final double ltp;
  final double change;
  final double pChange;
  final double barFraction;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsTheme>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColorsTheme.dark
            : AppColorsTheme.light);
    // Gains follow theme accent (Imperial Gold); only losses use red.
    final positive = pChange >= 0;
    final accent =
        positive ? colors.actionPrimaryBg : MarketColors.negative(context);
    final accentBg = positive
        ? colors.actionPrimaryBg.withValues(alpha: 0.16)
        : MarketColors.negativeBg(context);
    final fmt = NumberFormat('#,##0.00');
    final sign = positive ? '+' : '';
    final frac = barFraction.clamp(0.0, 1.0);
    final selectedBorder = colors.actionPrimaryBg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: MarketColors.cardSurface(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? selectedBorder
                  : MarketColors.borderDefault(context),
              width: MarketColors.borderWidth(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rank.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: MarketColors.textMuted(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          data.indexSymbol.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: MarketColors.textPrimary(context),
                            letterSpacing: 0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.actionPrimaryBg.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: colors.actionPrimaryBg.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: colors.actionPrimaryBg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmt.format(ltp),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MarketColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$sign${fmt.format(change)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final fillW =
                            (constraints.maxWidth * frac).clamp(0.0, constraints.maxWidth);
                        return SizedBox(
                          height: 10,
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.actionPrimaryBg
                                        .withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                              if (fillW > 0)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: fillW,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: accent,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${positive ? '▲' : '▼'} $sign${pChange.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
