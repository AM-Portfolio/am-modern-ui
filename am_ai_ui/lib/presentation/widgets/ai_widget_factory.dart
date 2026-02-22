import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../data/ai_intent_response.dart';

/// Maps widgetId strings from AiIntentResponse to rendered Flutter widgets.
/// Uses design system [AppColors] and theme-aware context extensions.
class AiWidgetFactory {
  const AiWidgetFactory._();

  static Widget build(AiIntentResponse response) {
    switch (response.widgetId) {
      case 'PORTFOLIO_SUMMARY':
        return _IntentCard(
          title: 'Portfolio Summary',
          subtitle: 'Total value, P&L, and invested amount',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.primary,
        );
      case 'HOLDINGS_TABLE':
        return _IntentCard(
          title: 'Holdings Table',
          subtitle: 'All positions with gain/loss breakdown',
          icon: Icons.table_chart_rounded,
          color: AppColors.tradeAccent,
        );
      case 'ALLOCATION_PIE_CHART':
        return _IntentCard(
          title: 'Allocation Breakdown',
          subtitle: 'Sector and asset type distribution',
          icon: Icons.pie_chart_rounded,
          color: AppColors.portfolioAccent,
        );
      case 'TOP_MOVERS':
        return _IntentCard(
          title: 'Top Movers',
          subtitle: 'Best and worst performers today',
          icon: Icons.trending_up_rounded,
          color: AppColors.profit,
        );
      case 'RECENT_ACTIVITY':
        return _IntentCard(
          title: 'Recent Activity',
          subtitle: 'Buy/sell transactions and events',
          icon: Icons.receipt_long_rounded,
          color: AppColors.marketAccent,
        );
      case 'ETF_ANALYSIS':
        return _IntentCard(
          title: 'ETF Analysis',
          subtitle: 'Overlap and hidden stock exposure',
          icon: Icons.analytics_rounded,
          color: AppColors.userAccent,
        );
      case 'BENCHMARK_COMPARISON':
        return _IntentCard(
          title: 'Benchmark Comparison',
          subtitle: 'Portfolio vs NIFTY 50',
          icon: Icons.compare_arrows_rounded,
          color: AppColors.accent,
        );
      case 'ERROR':
        return _ErrorBanner(message: response.message);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Intent Preview Card ──────────────────────────────────────────────────────

class _IntentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _IntentCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: context.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios,
              size: 14, color: color.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
