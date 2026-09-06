import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:intl/intl.dart';
import '../../../../core/styles/market_theme_extension.dart';
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
        _buildSectionHeader(context),
        const SizedBox(height: 12),
        asyncData.when(
          data: (peers) {
            if (peers == null || peers.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No peers available',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
              );
            }

            final activeCols = PeerColumnsHelper.resolveActiveColumns(peers);
            final sortedPeers = _getSortedPeers(peers, activeCols);
            final double maxRoe = peers.fold(0.0, (m, p) => max(m, p.roe ?? 0.0));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
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
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double tableWidth = max(constraints.maxWidth, 1080.0);
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          children: [
                            _buildTableHeader(context, activeCols),
                            const SizedBox(height: 4),
                            ...sortedPeers.map((peer) => _buildTableRow(context, peer, maxRoe, activeCols)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Error loading peers: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context, List<PeerColumnDef> activeCols) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.borderColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 22,
            child: Text(
              'COMPANY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: context.textTertiary,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: _buildColumnHeader('PRICE', 'currentPrice', Alignment.centerRight),
          ),
          Expanded(
            flex: 10,
            child: _buildColumnHeader('DAY CHG', 'dayChangePercent', Alignment.centerRight),
          ),
          ...activeCols.map((col) => Expanded(
                flex: 9,
                child: _buildColumnHeader(col.label.toUpperCase(), col.key, Alignment.centerRight),
              )),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String label, String sortKey, Alignment alignment) {
    final isSorted = _activeSortColumn == sortKey;
    return Align(
      alignment: alignment,
      child: InkWell(
        onTap: () => _onSortChanged(sortKey),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: BoxDecoration(
            color: isSorted
                ? ModuleColors.market.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSorted ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isSorted ? ModuleColors.market : context.textTertiary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isSorted
                    ? (_sortDescending ? Icons.arrow_downward : Icons.arrow_upward)
                    : Icons.unfold_more,
                size: 11,
                color: isSorted ? ModuleColors.market : context.textTertiary.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, CompetitorPeer p, double maxRoe, List<PeerColumnDef> activeCols) {
    final isCurrent = p.symbol == widget.symbol;
    final rowBg = isCurrent ? context.marketTheme.positive.withValues(alpha: 0.05) : Colors.transparent;
    final targetSymbol = (p.symbol ?? '').trim();

    String dayChangeStr = '—';
    Color dayChangeColor = context.textSecondary;
    if (p.dayChangePercent != null) {
      final sign = p.dayChangePercent! >= 0 ? '+' : '';
      dayChangeStr = '$sign${p.dayChangePercent!.toStringAsFixed(2)}%';
      dayChangeColor = p.dayChangePercent! >= 0 ? context.marketTheme.positive : context.marketTheme.negative;
    }

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(
          bottom: BorderSide(
            color: context.borderColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          // COMPANY column (Symbol in Cyan/clickable)
          Expanded(
            flex: 22,
            child: InkWell(
              onTap: targetSymbol.isNotEmpty && targetSymbol != widget.symbol
                  ? () => widget.onPeerSelected?.call(targetSymbol)
                  : null,
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      targetSymbol.isNotEmpty ? targetSymbol : (p.companyName ?? '—'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: targetSymbol.isNotEmpty && targetSymbol != widget.symbol
                            ? ModuleColors.market
                            : (isCurrent ? context.marketTheme.positive : context.textPrimary),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: context.marketTheme.positive.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'YOU',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: context.marketTheme.positive,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // PRICE
          Expanded(
            flex: 12,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _activeSortColumn == 'currentPrice'
                      ? ModuleColors.market.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  p.currentPrice != null ? '₹${NumberFormat('#,##,##0.00', 'en_IN').format(p.currentPrice)}' : '—',
                  style: TextStyle(
                    color: _activeSortColumn == 'currentPrice' ? ModuleColors.market : context.textPrimary,
                    fontWeight: _activeSortColumn == 'currentPrice' ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          // DAY CHG
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _activeSortColumn == 'dayChangePercent'
                      ? ModuleColors.market.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dayChangeStr,
                  style: TextStyle(
                    color: dayChangeColor,
                    fontWeight: _activeSortColumn == 'dayChangePercent' ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          // DYNAMIC METRIC COLS
          ...activeCols.map(
            (col) {
              final isColActive = _activeSortColumn == col.key;
              return Expanded(
                flex: 9,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isColActive
                          ? ModuleColors.market.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: col.cellBuilder(context, p, maxRoe),
                  ),
                ),
              );
            },
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? ModuleColors.market : context.cardColor,
          border: Border.all(
            color: isActive ? ModuleColors.market : context.borderColor,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Text(
      'Peer Comparison',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: context.textPrimary,
      ),
    );
  }
}
