import '../../../../core/styles/market_theme_extension.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:intl/intl.dart';
import '../../providers/equity_insider_provider.dart';

class EquityInsiderPeers extends ConsumerStatefulWidget {
  final String symbol;

  const EquityInsiderPeers({
    super.key,
    required this.symbol,
  });

  @override
  ConsumerState<EquityInsiderPeers> createState() => _EquityInsiderPeersState();
}

class _EquityInsiderPeersState extends ConsumerState<EquityInsiderPeers> {
  String _activeSortColumn = 'currentPrice';
  bool _sortDescending = true;

  void _onSortChanged(String column) {
    setState(() {
      if (_activeSortColumn == column) {
        _sortDescending = !_sortDescending;
      } else {
        _activeSortColumn = column;
        _sortDescending = true; // Default to descending for new columns
      }
    });
  }

  double _getSortValue(CompetitorPeer peer, String column) {
    switch (column) {
      case 'currentPrice':
        return peer.currentPrice ?? double.negativeInfinity;
      case 'dayChangePercent':
        return peer.dayChangePercent ?? double.negativeInfinity;
      case 'pe':
        return peer.pe ?? double.negativeInfinity;
      case 'pb':
        return peer.pb ?? double.negativeInfinity;
      case 'roe':
        return peer.roe ?? double.negativeInfinity;
      case 'roce':
        return peer.roce ?? double.negativeInfinity;
      case 'evEbitda':
        return peer.evEbitda ?? double.negativeInfinity;
      default:
        return double.negativeInfinity;
    }
  }

  List<CompetitorPeer> _getSortedPeers(List<CompetitorPeer> peers) {
    final list = List<CompetitorPeer>.from(peers);
    list.sort((a, b) {
      final aVal = _getSortValue(a, _activeSortColumn);
      final bVal = _getSortValue(b, _activeSortColumn);
      return _sortDescending ? bVal.compareTo(aVal) : aVal.compareTo(bVal);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(fundamentalPeersProvider(widget.symbol));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Peer comparison'),
        asyncData.when(
          data: (peers) {
            if (peers == null || peers.isEmpty) {
              return const Text('No peers available');
            }

            final sortedPeers = _getSortedPeers(peers);
            final double maxRoe = peers.fold(0.0, (m, p) => max(m, p.roe ?? 0.0));

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: context.cardColor,
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildSortTab('Price', 'currentPrice'),
                        _buildSortTab('P/E', 'pe'),
                        _buildSortTab('P/B', 'pb'),
                        _buildSortTab('ROE %', 'roe'),
                        _buildSortTab('ROCE %', 'roce'),
                        _buildSortTab('EV/EBITDA', 'evEbitda'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Use LayoutBuilder to dynamically expand the width of the table
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            headingRowHeight: 40,
                            dataRowMaxHeight: 65,
                            dataRowMinHeight: 65,
                            columnSpacing: 24, // adjust to let columns breathe
                            horizontalMargin: 14,
                            headingTextStyle: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.8,
                              color: context.textTertiary,
                              textBaseline: TextBaseline.alphabetic,
                            ),
                            border: TableBorder(
                              bottom: BorderSide.none,
                              horizontalInside: BorderSide(
                                color: context.borderColor,
                                width: 1,
                              ),
                            ),
                            columns: [
                              _buildColumn('COMPANY', null),
                              _buildColumn('PRICE', 'currentPrice', numeric: true),
                              _buildColumn('DAY CHG', 'dayChangePercent', numeric: true),
                              _buildColumn('P/E', 'pe', numeric: true),
                              _buildColumn('P/B', 'pb', numeric: true),
                              _buildColumn('ROE %', 'roe', numeric: true),
                              _buildColumn('ROCE %', 'roce', numeric: true),
                              _buildColumn('EV/EBITDA', 'evEbitda', numeric: true),
                            ],
                            rows: sortedPeers.map((p) => _buildRow(p, maxRoe)).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error loading peers: $e', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    );
  }

  DataRow _buildRow(CompetitorPeer p, double maxRoe) {
    final isCurrent = p.symbol == widget.symbol;
    final rowBg = isCurrent ? context.marketTheme.positive.withValues(alpha: 0.04) : Colors.transparent;
    final name = p.companyName ?? '';
    final shortName = name.length > 28 ? '${name.substring(0, 25)}...' : name;

    // Build the day change percent string
    String dayChangeStr = '—';
    Color dayChangeColor = context.textSecondary;
    if (p.dayChangePercent != null) {
      final sign = p.dayChangePercent! >= 0 ? '+' : '';
      dayChangeStr = '$sign${p.dayChangePercent!.toStringAsFixed(2)}%';
      dayChangeColor = p.dayChangePercent! >= 0 ? context.marketTheme.positive : context.marketTheme.negative;
    }

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) => rowBg),
      cells: [
        DataCell(
          Container(
            decoration: isCurrent
                ? BoxDecoration(border: Border(left: BorderSide(color: context.marketTheme.positive, width: 2)))
                : null,
            padding: EdgeInsets.only(left: isCurrent ? 8 : 10),
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.symbol ?? '—',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: context.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: context.marketTheme.surface,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(fontSize: 9, color: context.marketTheme.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  shortName,
                  style: TextStyle(fontSize: 10, color: context.marketTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
        DataCell(Container(
          alignment: Alignment.centerRight,
          child: Text(
            p.currentPrice != null ? '₹${NumberFormat('#,##,##0.00', 'en_IN').format(p.currentPrice)}' : '—',
            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500),
          ),
        )),
        DataCell(Container(
          alignment: Alignment.centerRight,
          child: Text(
            dayChangeStr,
            style: TextStyle(color: dayChangeColor),
          ),
        )),
        DataCell(Container(
          alignment: Alignment.centerRight,
          child: Text(
            p.pe != null ? p.pe!.toStringAsFixed(2) : '—',
            style: TextStyle(color: context.textSecondary),
          ),
        )),
        DataCell(Container(
          alignment: Alignment.centerRight,
          child: Text(
            p.pb != null ? p.pb!.toStringAsFixed(2) : '—',
            style: TextStyle(color: context.textSecondary),
          ),
        )),
        DataCell(Container(
          alignment: Alignment.centerRight,
          child: _buildMetricBar(p.roe, maxRoe),
        )),
        DataCell(Container(
          alignment: Alignment.centerRight,
          child: Text(
            p.roce != null ? p.roce!.toStringAsFixed(2) : '—',
            style: TextStyle(
              color: p.roce != null && p.roce! > 30
                  ? context.marketTheme.positive
                  : (p.roce != null && p.roce! > 15 ? context.textSecondary : context.marketTheme.negative),
            ),
          ),
        )),
        DataCell(Container(
          alignment: Alignment.centerRight,
          child: Text(
            p.evEbitda != null ? p.evEbitda!.toStringAsFixed(2) : '—',
            style: TextStyle(color: context.textSecondary),
          ),
        )),
      ],
    );
  }

  Widget _buildMetricBar(double? val, double maxVal) {
    if (val == null) {
      return Text('—', style: TextStyle(color: context.textSecondary));
    }
    final pct = maxVal > 0 ? (val / maxVal).clamp(0.0, 1.0) : 0.0;
    final color = val > 30 ? context.marketTheme.positive : (val > 15 ? context.marketTheme.blue : context.marketTheme.negative);
    final textColor = val > 30 ? context.marketTheme.positive : (val > 15 ? context.textSecondary : context.marketTheme.negative);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(val.toStringAsFixed(2), style: TextStyle(color: textColor)),
        const SizedBox(width: 6),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: context.marketTheme.surface,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              Container(
                width: 40 * pct,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataColumn _buildColumn(String label, String? sortKey, {bool numeric = false}) {
    final isSorted = _activeSortColumn == sortKey;
    return DataColumn(
      numeric: numeric,
      label: GestureDetector(
        onTap: sortKey != null ? () => _onSortChanged(sortKey) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSorted ? context.marketTheme.positive : context.textTertiary,
              ),
            ),
            if (sortKey != null) ...[
              const SizedBox(width: 4),
              Icon(
                isSorted
                    ? (_sortDescending ? Icons.arrow_downward : Icons.arrow_upward)
                    : Icons.unfold_more,
                size: 10,
                color: isSorted ? context.marketTheme.positive : context.textTertiary.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSortTab(String label, String key) {
    final isActive = _activeSortColumn == key;
    return InkWell(
      onTap: () => _onSortChanged(key),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? context.marketTheme.surface : Colors.transparent,
          border: Border.all(
            color: isActive ? context.marketTheme.border : context.borderColor,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isActive ? context.marketTheme.positive : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: context.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: context.borderColor,
            ),
          ),
        ],
      ),
    );
  }
}
