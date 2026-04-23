import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../data/ai_intent_response.dart';

/// Maps widgetId strings from AiIntentResponse to rendered Flutter widgets.
/// Uses design system [AppColors] and theme-aware context extensions.
class AiWidgetFactory {
  const AiWidgetFactory._();

  static Widget build(AiIntentResponse response) {
    switch (response.widgetId) {
      case 'PORTFOLIO_SUMMARY':
        return _PortfolioSummaryCard(widgetParams: response.widgetParams);
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

// ─── Portfolio Summary Card ───────────────────────────────────────────────────

class _PortfolioSummaryCard extends StatelessWidget {
  final Map<String, dynamic> widgetParams;

  const _PortfolioSummaryCard({required this.widgetParams});

  // Currency formatter — INR locale with ₹ symbol, no decimal places for large values
  static final _currencyFmt =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static final _currencyFmt2 =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  String _formatCurrency(dynamic raw) {
    if (raw == null) return '₹—';
    final value = (raw as num).toDouble();
    // Use no-decimal for values above 1000, else 2 dp for small amounts
    return value.abs() >= 1000
        ? _currencyFmt.format(value)
        : _currencyFmt2.format(value);
  }

  String _formatPct(dynamic raw) {
    if (raw == null) return '—%';
    final value = (raw as num).toDouble();
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  Color _gainColor(dynamic raw, BuildContext context) {
    if (raw == null) return context.textSecondary;
    return (raw as num).toDouble() >= 0 ? AppColors.profit : AppColors.loss;
  }

  @override
  Widget build(BuildContext context) {
    final data = widgetParams['data'] as Map<String, dynamic>?;

    // Fallback when data is absent (intent detected but data not yet loaded)
    if (data == null) {
      return _buildFallback(context);
    }

    final totalValue = data['totalValue'] as num?;
    final totalInvested = data['totalInvested'] as num?;
    final totalGainLoss = data['totalGainLoss'] as num?;
    final totalGainLossPct = data['totalGainLossPercentage'] as num?;
    final dayChange = data['dayChange'] as num?;
    final dayChangePct = data['dayChangePercentage'] as num?;
    final totalPortfolios = data['totalPortfolios'] as int? ?? 0;
    final totalHoldings = data['totalHoldings'] as int? ?? 0;
    final breakdown =
        (data['portfolioBreakdown'] as List<dynamic>?) ?? const [];
    final best = data['bestPerformer'] as Map<String, dynamic>?;
    final worst = data['worstPerformer'] as Map<String, dynamic>?;

    final dayIsPositive = (dayChange?.toDouble() ?? 0.0) >= 0;
    final gainIsPositive = (totalGainLoss?.toDouble() ?? 0.0) >= 0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.portfolioAccent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          _buildHeader(
            context,
            totalValue: totalValue,
            dayChange: dayChange,
            dayChangePct: dayChangePct,
            dayIsPositive: dayIsPositive,
          ),

          Divider(height: 1, color: context.dividerColor),

          // ── Key Metrics Row ───────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _MetricCell(
                    label: 'Invested',
                    value: _formatCurrency(totalInvested),
                    valueColor: context.textPrimary,
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _MetricCell(
                    label: 'Gain / Loss',
                    value: totalGainLoss != null
                        ? _formatCurrency(totalGainLoss)
                        : '₹—',
                    valueColor: _gainColor(totalGainLoss, context),
                    badge: totalGainLossPct != null
                        ? _formatPct(totalGainLossPct)
                        : null,
                    badgePositive: gainIsPositive,
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _MetricCell(
                    label: 'Today',
                    value: dayChange != null
                        ? _formatCurrency(dayChange)
                        : '₹—',
                    valueColor: _gainColor(dayChange, context),
                    badge: dayChangePct != null
                        ? _formatPct(dayChangePct)
                        : null,
                    badgePositive: dayIsPositive,
                  ),
                ),
              ],
            ),
          ),

          // ── Portfolio / Holdings Stats ─────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.only(left: 12, right: 12, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.folder_outlined,
                    size: 13, color: context.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '$totalPortfolios ${totalPortfolios == 1 ? 'Portfolio' : 'Portfolios'}',
                  style: TextStyle(
                      fontSize: 11, color: context.textSecondary),
                ),
                const SizedBox(width: 12),
                Icon(Icons.show_chart_rounded,
                    size: 13, color: context.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '$totalHoldings ${totalHoldings == 1 ? 'Holding' : 'Holdings'}',
                  style: TextStyle(
                      fontSize: 11, color: context.textSecondary),
                ),
              ],
            ),
          ),

          // ── Portfolio Breakdown ────────────────────────────────────────
          if (breakdown.isNotEmpty) ...[
            Divider(height: 1, color: context.dividerColor),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Breakdown',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                    letterSpacing: 0.4),
              ),
            ),
            ...breakdown
                .take(4) // cap at 4 rows to stay compact inside chat bubble
                .map((item) => _buildBreakdownRow(
                    context, item as Map<String, dynamic>)),
            if (breakdown.length > 4)
              Padding(
                padding: const EdgeInsets.only(
                    left: 12, right: 12, bottom: 8),
                child: Text(
                  '+${breakdown.length - 4} more portfolios',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500),
                ),
              ),
          ],

          // ── Best / Worst Performers ────────────────────────────────────
          if (best != null || worst != null) ...[
            Divider(height: 1, color: context.dividerColor),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (best != null)
                    _PerformerChip(
                      symbol: best['symbol'] as String? ?? '—',
                      pct: best['changePercent'] as num?,
                      isPositive: true,
                    ),
                  if (worst != null)
                    _PerformerChip(
                      symbol: worst['symbol'] as String? ?? '—',
                      pct: worst['changePercent'] as num?,
                      isPositive: false,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required num? totalValue,
    required num? dayChange,
    required num? dayChangePct,
    required bool dayIsPositive,
  }) {
    final dayColor = dayIsPositive ? AppColors.profit : AppColors.loss;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Wallet icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.portfolioAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.portfolioAccent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio Summary',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalValue != null
                      ? _formatCurrency(totalValue)
                      : '₹—',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          // Day change badge
          if (dayChange != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: dayColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    dayIsPositive
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: dayColor,
                    size: 16,
                  ),
                  Text(
                    dayChangePct != null
                        ? '${(dayChangePct.toDouble()).abs().toStringAsFixed(2)}%'
                        : _formatCurrency(dayChange),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dayColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
      BuildContext context, Map<String, dynamic> item) {
    final name = item['portfolioName'] as String? ?? '—';
    final value = item['currentValue'] as num?;
    final gainPct = item['gainLossPercent'] as num?;
    final gainIsPos = (gainPct?.toDouble() ?? 0.0) >= 0;
    final gainColor = gainIsPos ? AppColors.profit : AppColors.loss;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                  fontSize: 12,
                  color: context.textPrimary,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value != null ? _formatCurrency(value) : '₹—',
            style: TextStyle(
                fontSize: 12,
                color: context.textPrimary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          if (gainPct != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: gainColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatPct(gainPct),
                style: TextStyle(
                    fontSize: 10,
                    color: gainColor,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.portfolioAccent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.portfolioAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.portfolioAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio Summary',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.portfolioAccent,
                      fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to view portfolio',
                  style: TextStyle(
                      color: context.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.portfolioAccent.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

// ── Metric Cell ───────────────────────────────────────────────────────────────

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String? badge;
  final bool badgePositive;

  const _MetricCell({
    required this.label,
    required this.value,
    required this.valueColor,
    this.badge,
    this.badgePositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = badgePositive ? AppColors.profit : AppColors.loss;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              TextStyle(fontSize: 10, color: context.textSecondary),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor),
          overflow: TextOverflow.ellipsis,
        ),
        if (badge != null)
          Text(
            badge!,
            style: TextStyle(
                fontSize: 10,
                color: badgeColor,
                fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

// ── Vertical Divider Helper ───────────────────────────────────────────────────

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: context.dividerColor,
    );
  }
}

// ── Performer Chip ─────────────────────────────────────────────────────────────

class _PerformerChip extends StatelessWidget {
  final String symbol;
  final num? pct;
  final bool isPositive;

  const _PerformerChip({
    required this.symbol,
    required this.pct,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.profit : AppColors.loss;
    final label = isPositive ? 'Best' : 'Worst';
    final icon =
        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final pctText = pct != null
        ? '${isPositive ? '+' : ''}${pct!.toStringAsFixed(2)}%'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $symbol',
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600),
          ),
          if (pctText.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              pctText,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
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
