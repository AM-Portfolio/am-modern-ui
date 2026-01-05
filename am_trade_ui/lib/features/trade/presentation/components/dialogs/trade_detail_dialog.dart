import 'package:flutter/material.dart';

import '../../models/trade_holding_view_model.dart';
import 'sections/trade_info_section.dart';
import 'sections/trade_metrics_section.dart';
import 'sections/trade_performance_section.dart';

/// A comprehensive, modular dialog for displaying detailed trade information.
///
/// This dialog uses a tabbed interface to organize different aspects of trade data:
/// - Overview: Basic trade information (symbol, company, status, etc.)
/// - Metrics: Performance metrics and risk/reward analysis
/// - Performance: Charts and visual performance indicators
///
/// The dialog is fully responsive and adapts to different screen sizes.
class TradeDetailDialog extends StatefulWidget {
  const TradeDetailDialog({required this.holding, super.key});

  final TradeHoldingViewModel holding;

  @override
  State<TradeDetailDialog> createState() => _TradeDetailDialogState();

  /// Helper method to show the dialog
  static Future<void> show(BuildContext context, TradeHoldingViewModel holding) => showDialog(
    context: context,
    builder: (context) => TradeDetailDialog(holding: holding),
  );
}

class _TradeDetailDialogState extends State<TradeDetailDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final dialogWidth = isSmallScreen ? screenSize.width * 0.95 : screenSize.width * 0.7;
    final dialogHeight = isSmallScreen ? screenSize.height * 0.85 : screenSize.height * 0.8;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: dialogWidth.clamp(300.0, 900.0),
        height: dialogHeight.clamp(400.0, 800.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface.withOpacity(0.95)],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context, isSmallScreen),
            _buildTabBar(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  TradeInfoSection(holding: widget.holding),
                  TradeMetricsSection(holding: widget.holding),
                  TradePerformanceSection(holding: widget.holding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    final isProfit = widget.holding.isProfit;
    final statusColor = _getStatusColor(widget.holding.status);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Symbol Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
            ),
            child: Icon(_getStatusIcon(widget.holding.status), color: statusColor, size: isSmallScreen ? 28 : 32),
          ),
          const SizedBox(width: 16),
          // Title and Company
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.holding.displaySymbol,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        widget.holding.displayStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.holding.displayCompanyName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // P&L Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isProfit ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isProfit ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up : Icons.trending_down,
                      color: isProfit ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.holding.displayProfitLossPercentage,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: isProfit ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.holding.displayProfitLoss,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: isProfit ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Close button
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
    ),
    child: TabBar(
      controller: _tabController,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      indicatorColor: Theme.of(context).colorScheme.primary,
      indicatorWeight: 3,
      tabs: const [
        Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
        Tab(icon: Icon(Icons.analytics_outlined), text: 'Metrics'),
        Tab(icon: Icon(Icons.show_chart), text: 'Performance'),
      ],
    ),
  );

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'WIN':
        return Colors.green;
      case 'LOSS':
        return Colors.red;
      case 'BREAK_EVEN':
        return Colors.orange;
      case 'OPEN':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toUpperCase()) {
      case 'WIN':
        return Icons.check_circle;
      case 'LOSS':
        return Icons.cancel;
      case 'BREAK_EVEN':
        return Icons.remove_circle;
      case 'OPEN':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }
}
