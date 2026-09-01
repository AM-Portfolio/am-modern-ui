import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../providers/equity_insider_provider.dart';

class EquityInsiderHero extends ConsumerWidget {
  final String symbol;

  const EquityInsiderHero({super.key, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(fundamentalProfileProvider(symbol));

    return asyncData.when(
      data: (data) {
        if (data == null) return const Text('No profile data');
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.symbol ?? symbol,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.sector ?? 'Unknown'} · NSE',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.textSecondary,
                          textBaseline: TextBaseline.alphabetic,
                          letterSpacing: 0.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildBadge(context, 'Large Cap', isNeutral: true),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_formatCurrency(data.currentPrice)}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: context.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.dayChangePercent != null && data.dayChangePercent! >= 0 ? '+' : ''}${_formatNum(data.dayChange)} today',
                      style: TextStyle(
                        fontSize: 12,
                        color: data.dayChangePercent != null && data.dayChangePercent! >= 0
                            ? const Color(0xFF00C896)
                            : const Color(0xFFF87171),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NSE · Live',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (data.description != null && data.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                data.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(height: 1, color: context.borderColor),
          ],
        );
      },
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (e, st) => Text('Error loading profile: $e', style: TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }

  String _formatCurrency(num? val) {
    if (val == null) return '---';
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(val);
  }

  String _formatNum(num? val) {
    if (val == null) return '---';
    return val.toStringAsFixed(2);
  }

  Widget _buildBadge(BuildContext context, String text, {bool isPos = false, bool isNeg = false, bool isNeutral = false}) {
    Color bg;
    Color fg;
    if (isPos) {
      fg = const Color(0xFF00C896);
      bg = fg.withOpacity(0.10);
    } else if (isNeg) {
      fg = const Color(0xFFF87171);
      bg = fg.withOpacity(0.10);
    } else {
      fg = const Color(0xFF64748B);
      bg = fg.withOpacity(0.15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}
