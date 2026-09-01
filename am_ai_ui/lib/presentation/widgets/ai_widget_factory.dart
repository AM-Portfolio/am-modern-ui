import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../data/ai_intent_response.dart';
import '../providers/ai_chat_provider.dart';
import 'ai_message_format.dart';

/// Maps widgetId strings from AiIntentResponse to rendered Flutter widgets.
/// Uses design system [AppColors] and theme-aware context extensions.
class AiWidgetFactory {
  const AiWidgetFactory._();

  static Map<String, dynamic>? _coerceDataMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('ok') && raw['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(raw['data'] as Map);
      }
      return raw;
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map.containsKey('ok') && map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return _coerceDataMap(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Agent sends tool payloads under [widgetParams.data]; legacy paths may flatten keys.
  static Map<String, dynamic> _resolvedData(Map<String, dynamic> widgetParams) {
    return _coerceDataMap(widgetParams['data']) ?? widgetParams;
  }

  static Map<String, dynamic> _normalizePortfolioData(Map<String, dynamic> data) {
    num? pick(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value is num) return value;
      }
      return null;
    }

    final holdingsRaw = data['totalHoldings'];
    final assetsRaw = data['totalAssets'];
    num? totalHoldings;
    if (holdingsRaw is num && holdingsRaw > 0) {
      totalHoldings = holdingsRaw;
    } else if (assetsRaw is num) {
      totalHoldings = assetsRaw;
    } else if (holdingsRaw is num) {
      totalHoldings = holdingsRaw;
    }

    final assetsRaw2 = data['totalAssets'];
    num? totalAssets;
    if (assetsRaw2 is num && assetsRaw2 > 0) {
      totalAssets = assetsRaw2;
    } else if (totalHoldings != null) {
      totalAssets = totalHoldings;
    }

    return {
      ...data,
      'totalValue': pick(['totalValue', 'currentValue']),
      'totalInvested': pick(['totalInvested', 'investmentValue']),
      'totalGainLoss': pick(['totalGainLoss']),
      'totalGainLossPercentage': pick(['totalGainLossPercentage']),
      'dayChange': pick(['dayChange', 'todayGainLoss']),
      'dayChangePercentage': pick(['dayChangePercentage', 'todayGainLossPercentage']),
      'totalHoldings': totalHoldings,
      'totalAssets': totalAssets,
      'totalPortfolios': data['totalPortfolios'] ?? 1,
    };
  }

  static List<dynamic> _extractHoldingsList(
    Map<String, dynamic> data, {
    String? messageText,
  }) {
    for (final key in ['holdings', 'items', 'stocks', 'equityHoldings']) {
      final raw = data[key];
      if (raw is List && raw.isNotEmpty) return raw;
      if (raw is String && raw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List && decoded.isNotEmpty) return decoded;
        } catch (_) {}
      }
    }
    if (messageText != null && messageText.contains('|')) {
      final rows = AiMessageFormat.parseMarkdownTable(messageText);
      if (rows.isNotEmpty) {
        return rows
            .map((row) => {
                  'symbol': row['Symbol'] ?? row['symbol'] ?? row['Name'] ?? '',
                  'name': row['Name'] ?? row['name'] ?? '',
                  'quantity': row['Quantity'] ?? row['quantity'] ?? '',
                  'avgPrice': row['Avg. Price (₹)'] ?? row['Avg Price'] ?? '',
                  'currentValue': row['Investment Value (₹)'] ??
                      row['Current Value (₹)'] ??
                      '',
                })
            .where((h) => (h['symbol'] ?? '').toString().isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  static Widget build(
    AiIntentResponse response, {
    String? messageText,
    bool embedded = false,
  }) {
    switch (response.widgetId) {
      case 'PORTFOLIO_SUMMARY':
        return _PortfolioSummaryCard(
          widgetParams: response.widgetParams,
          embedded: embedded,
        );
      case 'ORDER_PREVIEW':
        return _OrderPreviewCard(widgetParams: response.widgetParams);
      case 'BASKET_CARD':
        return _BasketCard(widgetParams: response.widgetParams);
      case 'HOLDINGS_TABLE':
        return _HoldingsTableCard(
          widgetParams: response.widgetParams,
          messageText: messageText,
        );
      case 'ALLOCATION_PIE_CHART':
        return _AllocationCard(widgetParams: response.widgetParams);
      case 'TOP_MOVERS':
        return _TopMoversCard(widgetParams: response.widgetParams);
      case 'RECENT_ACTIVITY':
        return _RecentActivityCard(widgetParams: response.widgetParams);
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
        return _ErrorBanner(
          message: response.message,
          traceId: response.traceId,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Basket Card ─────────────────────────────────────────────────────────────

class _BasketCard extends StatelessWidget {
  final Map<String, dynamic> widgetParams;

  const _BasketCard({required this.widgetParams});

  static final _currencyFmt =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final basket = (widgetParams['basket'] as Map<String, dynamic>?) ?? widgetParams;
    final name = basket['name'] as String? ?? basket['basket_name'] as String? ?? 'Investment Basket';
    final description = basket['description'] as String? ?? 'Curated portfolio basket';
    final items = (basket['items'] as List<dynamic>?) ?? (basket['constituents'] as List<dynamic>?) ?? [];
    final totalValue = basket['total_value'] as num? ?? basket['totalValue'] as num?;
    final rebalanceFreq = basket['rebalance_frequency'] as String? ?? 'Monthly';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shopping_basket_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(fontSize: 11, color: context.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (totalValue != null)
                  Text(
                    _currencyFmt.format(totalValue),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: context.dividerColor),
          if (items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                'Constituents (${items.length}) · $rebalanceFreq rebalancing',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
            ),
            ...items.take(3).map((item) {
              final m = item as Map<String, dynamic>;
              final symbol = m['symbol'] as String? ?? '—';
              final weight = m['weight'] as num? ?? m['weightage'] as num?;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      symbol,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.textPrimary),
                    ),
                    if (weight != null)
                      Text(
                        '${weight.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                  ],
                ),
              );
            }),
            if (items.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Text(
                  '+${items.length - 3} more assets',
                  style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Top Movers Card ─────────────────────────────────────────────────────────

class _TopMoversCard extends StatelessWidget {
  final Map<String, dynamic> widgetParams;
  const _TopMoversCard({required this.widgetParams});

  List<dynamic> _moversList(Map<String, dynamic> data, String key) {
    final raw = data[key];
    return raw is List<dynamic> ? raw : const [];
  }

  String _symbol(dynamic item) {
    if (item is Map) {
      return (item['symbol'] ?? item['tradingsymbol'] ?? item['name'] ?? '').toString();
    }
    return item.toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = AiWidgetFactory._resolvedData(widgetParams);
    var gainers = _moversList(data, 'gainers');
    var losers = _moversList(data, 'losers');
    if (gainers.isEmpty && losers.isEmpty) {
      gainers = _moversList(data, 'movers');
    }
    final isMarket = data['source'] == 'market' || (data.containsKey('movers') && gainers.isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.profit.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: AppColors.profit, size: 18),
              const SizedBox(width: 6),
              Text(
                isMarket ? 'Market Top Movers' : 'Portfolio Top Movers',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (gainers.isEmpty && losers.isEmpty)
            Text(
              'No movers to display',
              style: TextStyle(fontSize: 11, color: context.textSecondary),
            ),
          if (gainers.isNotEmpty) ...[
            Text('Top Gainers', style: TextStyle(fontSize: 11, color: AppColors.profit, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: gainers.take(5).map((g) {
                final sym = _symbol(g);
                if (sym.isEmpty) return const SizedBox.shrink();
                return Chip(
                  label: Text(sym, style: const TextStyle(fontSize: 10)),
                  backgroundColor: AppColors.profit.withValues(alpha: 0.1),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
          if (losers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Top Losers', style: TextStyle(fontSize: 11, color: AppColors.loss, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: losers.take(5).map((l) {
                final sym = _symbol(l);
                if (sym.isEmpty) return const SizedBox.shrink();
                return Chip(
                  label: Text(sym, style: const TextStyle(fontSize: 10)),
                  backgroundColor: AppColors.loss.withValues(alpha: 0.1),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Holdings Table Card ─────────────────────────────────────────────────────

class _HoldingsTableCard extends StatelessWidget {
  final Map<String, dynamic> widgetParams;
  final String? messageText;

  const _HoldingsTableCard({
    required this.widgetParams,
    this.messageText,
  });

  String _holdingLabel(dynamic item) {
    if (item is! Map) return item.toString();
    return (item['symbol'] ?? item['sourceId'] ?? item['name'] ?? '').toString();
  }

  String _cell(dynamic item, List<String> keys) {
    if (item is! Map) return '';
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final data = AiWidgetFactory._resolvedData(widgetParams);
    final holdings = AiWidgetFactory._extractHoldingsList(
      data,
      messageText: messageText,
    );
    final count = data['count'] is num
        ? (data['count'] as num).toInt()
        : holdings.length;

    if (holdings.isEmpty) return const SizedBox.shrink();

    final displayCount = count > 0 ? count : holdings.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.tradeAccent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart_rounded, color: AppColors.tradeAccent, size: 18),
              const SizedBox(width: 6),
              Text(
                'Holdings ($displayCount)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...holdings.take(6).map((h) {
            final symbol = _holdingLabel(h);
            if (symbol.isEmpty) return const SizedBox.shrink();
            final qty = _cell(h, ['quantity', 'qty', 'Quantity']);
            final value = _cell(h, [
              'currentValue',
              'investmentValue',
              'Investment Value (₹)',
              'Current Value (₹)',
            ]);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      symbol,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  if (qty.isNotEmpty)
                    Expanded(
                      child: Text(
                        qty,
                        style: TextStyle(fontSize: 11, color: context.textSecondary),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  if (value.isNotEmpty)
                    Expanded(
                      flex: 2,
                      child: Text(
                        value,
                        style: TextStyle(fontSize: 11, color: context.textSecondary),
                        textAlign: TextAlign.end,
                      ),
                    ),
                ],
              ),
            );
          }),
          if (displayCount > 6)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${displayCount - 6} more holdings',
                style: TextStyle(fontSize: 11, color: context.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Allocation Card ─────────────────────────────────────────────────────────

class _AllocationCard extends StatelessWidget {
  final Map<String, dynamic> widgetParams;
  const _AllocationCard({required this.widgetParams});

  List<MapEntry<String, dynamic>> _sortedEntries(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const [];
    final entries = map.entries.toList();
    entries.sort((a, b) {
      final av = a.value is num ? (a.value as num).toDouble() : 0.0;
      final bv = b.value is num ? (b.value as num).toDouble() : 0.0;
      return bv.compareTo(av);
    });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final data = AiWidgetFactory._resolvedData(widgetParams);
    final sectorMap = data['sectorAllocation'] as Map<String, dynamic>?;
    final capMap = data['marketCapAllocation'] as Map<String, dynamic>?;
    final entries = sectorMap != null && sectorMap.isNotEmpty
        ? _sortedEntries(sectorMap)
        : _sortedEntries(capMap);
    final title = sectorMap != null && sectorMap.isNotEmpty
        ? 'Sector Allocation'
        : 'Market Cap Allocation';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.portfolioAccent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: AppColors.portfolioAccent, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
            ],
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No allocation data available',
                style: TextStyle(fontSize: 11, color: context.textSecondary),
              ),
            )
          else
            ...entries.take(6).map((e) {
              final pct = e.value is num ? '${(e.value as num).toStringAsFixed(1)}%' : e.value.toString();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: TextStyle(fontSize: 11, color: context.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      pct,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.portfolioAccent,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Recent Activity Card ────────────────────────────────────────────────────

class _RecentActivityCard extends StatelessWidget {
  final Map<String, dynamic> widgetParams;
  const _RecentActivityCard({required this.widgetParams});

  String _activityLine(dynamic item) {
    if (item is! Map) return item.toString();
    final symbol = (item['symbol'] ?? item['tradingsymbol'] ?? '').toString();
    final side = (item['side'] ?? item['transactionType'] ?? item['type'] ?? '').toString();
    final qty = item['quantity'] ?? item['qty'];
    final parts = <String>[];
    if (side.isNotEmpty) parts.add(side.toUpperCase());
    if (symbol.isNotEmpty) parts.add(symbol);
    if (qty != null) parts.add('×$qty');
    return parts.isEmpty ? 'Activity' : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final data = AiWidgetFactory._resolvedData(widgetParams);
    final activities = (data['activities'] as List<dynamic>?) ??
        (data['trades'] as List<dynamic>?) ??
        const [];
    final count = data['count'] is num ? (data['count'] as num).toInt() : activities.length;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.marketAccent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: AppColors.marketAccent, size: 18),
              const SizedBox(width: 6),
              Text(
                'Recent Activity ($count)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
            ],
          ),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No recent transactions',
                style: TextStyle(fontSize: 11, color: context.textSecondary),
              ),
            )
          else
            ...activities.take(5).map((a) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _activityLine(a),
                    style: TextStyle(fontSize: 11, color: context.textPrimary),
                  ),
                )),
        ],
      ),
    );
  }
}

// ─── Portfolio Summary Card ───────────────────────────────────────────────────

class _PortfolioSummaryCard extends StatelessWidget {
  final Map<String, dynamic> widgetParams;
  final bool embedded;

  const _PortfolioSummaryCard({
    required this.widgetParams,
    this.embedded = false,
  });

  static final _currencyFmt =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static final _currencyFmt2 =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  String _formatCurrency(dynamic raw) {
    if (raw == null) return '₹—';
    final value = (raw as num).toDouble();
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

  String _todayLabel(num? dayChange, num? dayChangePct) {
    final parts = <String>['Today'];
    if (dayChange != null) parts.add(_formatCurrency(dayChange));
    if (dayChangePct != null) parts.add('(${_formatPct(dayChangePct)})');
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final resolved = AiWidgetFactory._resolvedData(widgetParams);
    final hasMetrics = resolved.containsKey('totalValue') ||
        resolved.containsKey('currentValue') ||
        resolved.containsKey('totalInvested') ||
        resolved.containsKey('investmentValue');
    final data = hasMetrics
        ? AiWidgetFactory._normalizePortfolioData(resolved)
        : null;

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
    final totalHoldings = data['totalHoldings'] as int? ?? 0;
    final totalAssets = data['totalAssets'] as int? ?? totalHoldings;
    final breakdown = (data['portfolioBreakdown'] as List<dynamic>?) ?? const [];
    final best = data['bestPerformer'] as Map<String, dynamic>?;
    final worst = data['worstPerformer'] as Map<String, dynamic>?;

    final gainIsPositive = (totalGainLoss?.toDouble() ?? 0.0) >= 0;
    final dayIsPositive = (dayChange?.toDouble() ?? 0.0) >= 0;

    return Container(
      margin: embedded ? EdgeInsets.zero : const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: embedded ? Colors.transparent : context.cardColor,
        borderRadius: BorderRadius.circular(embedded ? 12 : 16),
        border: embedded
            ? null
            : Border.all(color: context.borderColor.withValues(alpha: 0.55)),
        boxShadow: embedded
            ? null
            : [
                BoxShadow(
                  color: context.shadow(context.isDark ? 0.32 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryPanel(
            context,
            embedded: embedded,
            totalValue: totalValue,
            totalInvested: totalInvested,
            totalGainLoss: totalGainLoss,
            totalGainLossPct: totalGainLossPct,
            gainIsPositive: gainIsPositive,
            totalHoldings: totalHoldings,
            totalAssets: totalAssets,
            dayChange: dayChange,
            dayChangePct: dayChangePct,
            dayIsPositive: dayIsPositive,
          ),
          if (breakdown.isNotEmpty || best != null || worst != null)
            _buildExtras(context, breakdown, best, worst),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel(
    BuildContext context, {
    required bool embedded,
    required num? totalValue,
    required num? totalInvested,
    required num? totalGainLoss,
    required num? totalGainLossPct,
    required bool gainIsPositive,
    required int totalHoldings,
    required int totalAssets,
    required num? dayChange,
    required num? dayChangePct,
    required bool dayIsPositive,
  }) {
    final pad = embedded ? 10.0 : 14.0;
    final valueSize = embedded ? 22.0 : 24.0;
    final dayColor = dayIsPositive ? AppColors.profit : AppColors.loss;

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Portfolio Summary',
            color: AppColors.portfolioAccent,
          ),
          const SizedBox(height: 10),
          Text(
            'Current Value',
            style: TextStyle(fontSize: 10, color: context.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            totalValue != null ? _formatCurrency(totalValue) : '₹—',
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          if (dayChange != null || dayChangePct != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dayColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _todayLabel(dayChange, dayChangePct),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: dayColor,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _GridMetric(
                  label: 'Invested',
                  value: _formatCurrency(totalInvested),
                  valueColor: context.textPrimary,
                  compact: embedded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GridMetric(
                  label: 'Gain / Loss',
                  value: totalGainLoss != null
                      ? _formatCurrency(totalGainLoss)
                      : '₹—',
                  valueColor: _gainColor(totalGainLoss, context),
                  subValue: totalGainLossPct != null
                      ? _formatPct(totalGainLossPct)
                      : null,
                  subPositive: gainIsPositive,
                  compact: embedded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _IconStat(
                  icon: Icons.grid_view_rounded,
                  label: 'Holdings',
                  value: '$totalHoldings',
                ),
              ),
              Expanded(
                child: _IconStat(
                  icon: Icons.home_work_outlined,
                  label: 'Assets',
                  value: '$totalAssets',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtras(
    BuildContext context,
    List<dynamic> breakdown,
    Map<String, dynamic>? best,
    Map<String, dynamic>? worst,
  ) {
    return Column(
      children: [
        if (breakdown.isNotEmpty) ...[
          Divider(height: 1, color: context.dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Breakdown',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          ...breakdown
              .take(4)
              .map((item) => _buildBreakdownRow(context, item as Map<String, dynamic>)),
          if (breakdown.length > 4)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: Text(
                '+${breakdown.length - 4} more portfolios',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
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
    );
  }

  Widget _buildBreakdownRow(BuildContext context, Map<String, dynamic> item) {
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
            child: Text(name, style: TextStyle(fontSize: 12, color: context.textPrimary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(value != null ? _formatCurrency(value) : '₹—', style: TextStyle(fontSize: 12, color: context.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          if (gainPct != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: gainColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
              child: Text(_formatPct(gainPct), style: TextStyle(fontSize: 10, color: gainColor, fontWeight: FontWeight.w600)),
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

// ── Panel helpers ─────────────────────────────────────────────────────────────

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PanelTitle({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _GridMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String? subValue;
  final bool subPositive;
  final bool compact;

  const _GridMetric({
    required this.label,
    required this.value,
    required this.valueColor,
    this.subValue,
    this.subPositive = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = subPositive ? AppColors.profit : AppColors.loss;
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: context.textSecondary)),
          SizedBox(height: compact ? 2 : 4),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          if (subValue != null)
            Text(
              subValue!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: subColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _IconStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _IconStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: context.textSecondary)),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
      ],
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
        Text(label, style: TextStyle(fontSize: 10, color: context.textSecondary)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor), overflow: TextOverflow.ellipsis),
        if (badge != null)
          Text(badge!, style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

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
          Text('$label: $symbol', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          if (pctText.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(pctText, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
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
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: context.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: color.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final String traceId;

  const _ErrorBanner({required this.message, this.traceId = ''});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message, style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          if (traceId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Trace ID: $traceId',
              style: TextStyle(color: context.textSecondary, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}



class _OrderPreviewCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> widgetParams;
  const _OrderPreviewCard({required this.widgetParams});
  @override
  ConsumerState<_OrderPreviewCard> createState() => _OrderPreviewCardState();
}

class _OrderPreviewCardState extends ConsumerState<_OrderPreviewCard> {
  bool _confirmed = false;
  bool _loading = false;
  String? _error;

  Future<void> _confirmOrder() async {
    final token = widget.widgetParams['confirmToken']?.toString();
    final userId = widget.widgetParams['userId']?.toString() ?? 'user';
    if (token == null || token.isEmpty) return;

    setState(() { _loading = true; _error = null; });
    try {
      final success = await ref.read(aiChatProvider.notifier).confirmAction(
        confirmToken: token,
        userId: userId,
      );
      if (success) {
        setState(() { _confirmed = true; _loading = false; });
      } else {
        setState(() { _error = 'Failed to execute order. Action rejected.'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.widgetParams['data']?['order'] ?? widget.widgetParams['order'] ?? {};
    final symbol = data['symbol'] ?? 'Unknown';
    final action = data['action'] ?? 'BUY';
    final qty = data['quantity'] ?? 1;
    final val = data['totalValue'] ?? 0.0;
    final token = widget.widgetParams['confirmToken'];
    
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tradeAccent.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel_rounded, color: AppColors.tradeAccent),
              const SizedBox(width: 8),
              Text('Smart Order Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text('$action $qty shares of $symbol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Estimated Value: ₹$val', style: TextStyle(fontSize: 14, color: context.textSecondary)),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 12))),
          if (_confirmed)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.profit.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.check_circle, color: AppColors.profit),
                const SizedBox(width: 8),
                Text('Order Placed Successfully!', style: TextStyle(color: AppColors.profit, fontWeight: FontWeight.bold))
              ]),
            )
          else if (token != null)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.tradeAccent, foregroundColor: Colors.white),
                    onPressed: _loading ? null : _confirmOrder,
                    child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Confirm Order'),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }
}