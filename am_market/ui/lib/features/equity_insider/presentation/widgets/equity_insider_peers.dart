import '../../../../core/styles/market_theme_extension.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:intl/intl.dart';
import '../../providers/equity_insider_provider.dart';
import 'equity_insider_peers_columns.dart';

class EquityInsiderPeers extends ConsumerStatefulWidget {
  final String symbol;
  final ValueChanged<String>? onPeerSelected;

  const EquityInsiderPeers({
    super.key,
    required this.symbol,
    this.onPeerSelected,
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
        _sortDescending = true;
      }
    });
  }

  double _getSortValue(CompetitorPeer peer, String column, List<PeerColumnDef> activeCols) {
    if (column == 'currentPrice') return peer.currentPrice ?? double.negativeInfinity;
    if (column == 'dayChangePercent') return peer.dayChangePercent ?? double.negativeInfinity;

    for (final col in activeCols) {
      if (col.key == column) {
        return col.valueGetter(peer) ?? double.negativeInfinity;
      }
    }
    return double.negativeInfinity;
  }

  List<CompetitorPeer> _getSortedPeers(List<CompetitorPeer> peers, List<PeerColumnDef> activeCols) {
    final list = List<CompetitorPeer>.from(peers);
    list.sort((a, b) {
      final aVal = _getSortValue(a, _activeSortColumn, activeCols);
      final bVal = _getSortValue(b, _activeSortColumn, activeCols);
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
              return Text(
                'No peers available',
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              );
            }

            final activeCols = PeerColumnsHelper.resolveActiveColumns(peers);
            final sortedPeers = _getSortedPeers(peers, activeCols);
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSortTab('Price', 'currentPrice'),
                          const SizedBox(width: 8),
                          _buildSortTab('Day Chg', 'dayChangePercent'),
                          ...activeCols.map((col) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _buildSortTab(col.label, col.key),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            headingRowHeight: 32,
                            dataRowMaxHeight: 44,
                            dataRowMinHeight: 44,
                            columnSpacing: 20,
                            horizontalMargin: 12,
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
                              ...activeCols.map(
                                (col) => _buildColumn(col.label.toUpperCase(), col.key, numeric: true),
                              ),
                            ],
                            rows: sortedPeers.map((p) => _buildRow(p, maxRoe, activeCols)).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text(
            'Error loading peers: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }

  DataRow _buildRow(CompetitorPeer p, double maxRoe, List<PeerColumnDef> activeCols) {
    final isCurrent = p.symbol == widget.symbol;
    final rowBg = isCurrent ? context.marketTheme.positive.withValues(alpha: 0.04) : context.cardColor.withValues(alpha: 0);
    final name = p.companyName ?? '';
    final shortName = name.length > 28 ? '${name.substring(0, 25)}...' : name;

    String dayChangeStr = '—';
    Color dayChangeColor = context.textSecondary;
    if (p.dayChangePercent != null) {
      final sign = p.dayChangePercent! >= 0 ? '+' : '';
      dayChangeStr = '$sign${p.dayChangePercent!.toStringAsFixed(2)}%';
      dayChangeColor = p.dayChangePercent! >= 0 ? context.marketTheme.positive : context.marketTheme.negative;
    }

    final targetSymbol = (p.symbol ?? '').trim();

    return DataRow(
      color: WidgetStateProperty.all(rowBg),
      cells: [
        DataCell(
          InkWell(
            onTap: targetSymbol.isNotEmpty && targetSymbol != widget.symbol
                ? () => widget.onPeerSelected?.call(targetSymbol)
                : null,
            child: SizedBox(
              width: 140,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            targetSymbol.isNotEmpty ? targetSymbol : (shortName.isNotEmpty ? shortName : '—'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: isCurrent ? context.marketTheme.positive : context.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: context.marketTheme.positive.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'YOU',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: context.marketTheme.positive),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      targetSymbol.isNotEmpty ? shortName : (p.sector ?? ''),
                      style: TextStyle(fontSize: 10, color: context.marketTheme.textSecondary),
                    ),
                  ],
                ),
              ),
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
            style: TextStyle(color: dayChangeColor, fontWeight: FontWeight.w500),
          ),
        )),
        ...activeCols.map(
          (col) => DataCell(
            Container(
              alignment: Alignment.centerRight,
              child: col.cellBuilder(context, p, maxRoe),
            ),
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
                color: isSorted ? ModuleColors.market : context.textTertiary,
              ),
            ),
            if (sortKey != null) ...[
              const SizedBox(width: 4),
              Icon(
                isSorted
                    ? (_sortDescending ? Icons.arrow_downward : Icons.arrow_upward)
                    : Icons.unfold_more,
                size: 10,
                color: isSorted ? ModuleColors.market : context.textTertiary.withValues(alpha: 0.5),
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
          color: isActive ? ModuleColors.market.withValues(alpha: 0.15) : context.cardColor.withValues(alpha: 0),
          border: Border.all(
            color: isActive ? ModuleColors.market.withValues(alpha: 0.6) : context.borderColor,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? ModuleColors.market : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Peer Comparison',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
