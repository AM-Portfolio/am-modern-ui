import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoEmptyLandingView extends ConsumerWidget {
  const FoEmptyLandingView({
    required this.onSelected,
    super.key,
  });

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final accentColor = ModuleColors.market;
    final surfaceColor = colors.cardSurface;
    final borderColor = colors.border;

    final recommendationsAsync = ref.watch(dynamicFoRecommendationsProvider);
    final rawSymbols = recommendationsAsync.maybeWhen(
      data: (d) => d,
      orElse: () => const <String>[],
    );
    final recSymbols = rawSymbols.isNotEmpty
        ? rawSymbols.take(6).toList()
        : const ['NIFTY', 'BANKNIFTY', 'FINNIFTY', 'MIDCPNIFTY'];

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
                  Icons.candlestick_chart_rounded,
                  size: 38,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'FUTURES & OPTIONS',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the search icon above, or pick a popular index below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
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
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: colors.cardSurface,
                          side: BorderSide(color: colors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onPressed: () => onSelected(s),
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
  }
}
