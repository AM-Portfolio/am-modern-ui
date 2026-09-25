import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../models/trade_holding_view_model.dart';

class ModernTradeHeader extends ConsumerStatefulWidget {
  const ModernTradeHeader({
    required this.trade,
    required this.portfolioId,
    required this.onClose,
    required this.onFilterChanged,
    this.onSymbolTap,
    super.key,
  });

  final TradeHoldingViewModel trade;
  final String portfolioId;
  final VoidCallback? onClose;
  final ValueChanged<String?> onFilterChanged;
  final Function(String symbol)? onSymbolTap;

  @override
  ConsumerState<ModernTradeHeader> createState() => _ModernTradeHeaderState();
}

class _ModernTradeHeaderState extends ConsumerState<ModernTradeHeader> {
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = widget.trade.isProfit;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Back button
            InkWell(
              onTap: widget.onClose,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_back, size: 20, color: context.colors.textPrimary),
              ),
            ),
            const SizedBox(width: 16),

            // Left: Symbol and Company Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      widget.trade.displaySymbol,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: Text(
                        widget.trade.displayStatus.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.trade.displayCompanyName,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textPrimary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Left: Tags
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                    color: Colors.red.withOpacity(0.05),
                  ),
                  child: Text(
                    widget.trade.tradePositionType ?? 'LONG',
                    style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                    color: Colors.blue.withOpacity(0.05),
                  ),
                  child: const Text(
                    'EQUITY',
                    style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            // Middle: Spacer
            const Spacer(),
            
            // Right: Entry Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: context.colors.textPrimary.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      'Entry Date',
                      style: TextStyle(fontSize: 11, color: context.colors.textPrimary.withOpacity(0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.trade.entryTimestamp != null ? _formatDate(widget.trade.entryTimestamp!) : 'N/A',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                ),
              ],
            ),
            const SizedBox(width: 24),

            // Right: PnL Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isProfit
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.red.shade400, Colors.red.shade600],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.trade.displayProfitLossPercentage,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  Text(
                    widget.trade.displayProfitLoss,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const Text(
                    'Unrealized P/L',
                    style: TextStyle(fontSize: 9, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right: Action button
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {},
              color: context.colors.textPrimary,
            ),
          ],
        ),
    );
  }
}
