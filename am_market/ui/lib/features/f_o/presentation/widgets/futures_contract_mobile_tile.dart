import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';

/// Compact two-level futures contract row for viewports under [AmBreakpoints.mobile].
class FuturesContractMobileTile extends StatelessWidget {
  const FuturesContractMobileTile({
    required this.tradingSymbol,
    required this.expiryLabel,
    required this.ltp,
    required this.change,
    required this.pChange,
    required this.oi,
    required this.volume,
    required this.isSelected,
    required this.onTap,
    required this.formatNum,
    super.key,
  });

  final String tradingSymbol;
  final String expiryLabel;
  final double ltp;
  final double change;
  final double pChange;
  final int oi;
  final int volume;
  final bool isSelected;
  final VoidCallback onTap;
  final String Function(int) formatNum;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;
    final deltaColor =
        change >= 0 ? marketTheme.positive : marketTheme.negative;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? ModuleColors.market.withValues(alpha: 0.12)
                  : colors.surface.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? ModuleColors.market.withValues(alpha: 0.45)
                    : colors.border.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tradingSymbol,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ModuleColors.market,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              height: 1.15,
                            ),
                          ),
                          if (expiryLabel.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              expiryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${ltp.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}  '
                          '${pChange >= 0 ? '+' : ''}${pChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: deltaColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'OI  ${formatNum(oi)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Vol  ${formatNum(volume)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
