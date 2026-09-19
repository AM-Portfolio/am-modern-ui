import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewsSymbolChip extends StatelessWidget {
  const NewsSymbolChip({
    super.key,
    required this.symbol,
    this.quote,
  });

  final String symbol;
  final QuoteChange? quote;

  @override
  Widget build(BuildContext context) {
    final price = quote?.lastPrice;
    final changePct = quote?.changePercent;
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final onSurface = context.colors.textPrimary;
    final positive = (changePct ?? 0) >= 0;
    final changeColor = changePct == null
        ? context.colors.textSecondary
        : (positive ? context.colors.statusSuccess : context.colors.statusError);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ModuleColors.dashboard.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.xs + 2),
        border: Border.all(
          color: ModuleColors.dashboard.withValues(alpha: 0.5),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: symbol,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                fontFamily: 'Inter',
                color: onSurface,
              ),
            ),
            if (price != null)
              TextSpan(
                text: '  ${currency.format(price)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  color: onSurface,
                ),
              ),
            if (changePct != null)
              TextSpan(
                text:
                    '  ${positive ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  color: changeColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
