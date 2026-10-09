import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../providers/equity_insider_provider.dart';

class EquityInsiderEmptyView extends StatelessWidget {
  final ValueChanged<String> onSelectSymbol;

  const EquityInsiderEmptyView({
    super.key,
    required this.onSelectSymbol,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = ModuleColors.market;
    final surfaceColor = context.colors.cardSurface;
    final borderColor = context.colors.border;

    return Consumer(
      builder: (context, ref, _) {
        final recommendationsAsync =
            ref.watch(dynamicStockRecommendationsProvider);
        final rawSymbols = recommendationsAsync.maybeWhen(
          data: (d) => d,
          orElse: () => const <String>[],
        );
        final recSymbols = rawSymbols.isNotEmpty
            ? rawSymbols.take(6).toList()
            : const [
                'RELIANCE',
                'TCS',
                'HDFCBANK',
                'ICICIBANK',
                'INFY',
                'BHARTIARTL'
              ];

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: surfaceColor.withValues(alpha: 0.7),
                      border: Border.all(color: borderColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.insights_rounded,
                      size: 38,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'EQUITY INSIDER',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the search icon above for deep fundamental analysis, valuation & peers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (recSymbols.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: recSymbols
                          .map(
                            (s) => ActionChip(
                              label: Text(
                                s,
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: context.colors.cardSurface,
                              side: BorderSide(color: context.colors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onPressed: () => onSelectSymbol(s),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
