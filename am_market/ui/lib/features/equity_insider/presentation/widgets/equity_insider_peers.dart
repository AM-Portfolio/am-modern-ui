import 'dart:math';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart';

class EquityInsiderPeers extends StatefulWidget {
  final List<CompetitorPeer> peers;
  final String currentSymbol;

  const EquityInsiderPeers({
    super.key,
    required this.peers,
    required this.currentSymbol,
  });

  @override
  State<EquityInsiderPeers> createState() => _EquityInsiderPeersState();
}

class _EquityInsiderPeersState extends State<EquityInsiderPeers> {
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

  List<CompetitorPeer> _getSortedPeers() {
    final list = List<CompetitorPeer>.from(widget.peers);
    list.sort((a, b) {
      final aVal = _getSortValue(a, _activeSortColumn);
      final bVal = _getSortValue(b, _activeSortColumn);
      return _sortDescending ? bVal.compareTo(aVal) : aVal.compareTo(bVal);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final sortedPeers = _getSortedPeers();
    final double maxRoe = widget.peers.fold(0.0, (m, p) => max(m, p.roe ?? 0.0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Peer comparison — from API'),
        Container(
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 14,
                  columnSpacing: 24,
                  headingRowHeight: 40,
                  dataRowMinHeight: 50,
                  dataRowMaxHeight: 50,
                  border: TableBorder(
                    horizontalInside: BorderSide(color: context.borderColor.withOpacity(0.5)),
                  ),
                  columns: [
                    _buildColumnHeader('Company', ''),
                    _buildColumnHeader('Price', 'currentPrice', numeric: true),
                    _buildColumnHeader('Day Chg', 'dayChangePercent', numeric: true),
                    _buildColumnHeader('P/E', 'pe', numeric: true),
                    _buildColumnHeader('P/B', 'pb', numeric: true),
                    _buildColumnHeader('ROE %', 'roe', numeric: true),
                    _buildColumnHeader('ROCE %', 'roce', numeric: true),
                    _buildColumnHeader('EV/EBITDA', 'evEbitda', numeric: true),
                  ],
                  rows: sortedPeers.map((p) => _buildRow(p, maxRoe)).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildSortTab(String label, String column) {
    final isActive = _activeSortColumn == column;
    return InkWell(
      onTap: () => _onSortChanged(column),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? context.borderColor.withOpacity(0.3) : Colors.transparent,
          border: Border.all(color: isActive ? context.borderColor : context.borderColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF00C896) : context.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  DataColumn _buildColumnHeader(String label, String column, {bool numeric = false}) {
    final isActive = _activeSortColumn == column;
    String arrow = '↕';
    Color color = context.textTertiary;
    
    if (isActive) {
      arrow = _sortDescending ? '↓' : '↑';
      color = const Color(0xFF00C896);
    }

    return DataColumn(
      label: InkWell(
        onTap: column.isEmpty ? null : () => _onSortChanged(column),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              softWrap: false,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
            if (column.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                arrow,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? color : context.textTertiary.withOpacity(0.5),
                ),
              ),
            ]
          ],
        ),
      ),
      numeric: numeric,
    );
  }

  DataRow _buildRow(CompetitorPeer p, double maxRoe) {
    final isCurrent = p.symbol == widget.currentSymbol;
    
    // Semantic Colors
    final chgColor = (p.dayChangePercent ?? -1) >= 0 ? const Color(0xFF00C896) : const Color(0xFFF87171);
    
    Color roeColor = const Color(0xFFF87171); // Weak
    if ((p.roe ?? 0) > 30) roeColor = const Color(0xFF00C896); // Strong
    else if ((p.roe ?? 0) > 15) roeColor = const Color(0xFF38BDF8); // Medium
    
    Color roceColor = const Color(0xFFF87171);
    if ((p.roce ?? 0) > 30) roceColor = const Color(0xFF00C896);
    else if ((p.roce ?? 0) > 15) roceColor = context.textSecondary; // Medium/Normal

    final roePct = p.roe != null && maxRoe > 0 ? (p.roe! / maxRoe).clamp(0.0, 1.0) : 0.0;

    String formatVal(double? v) => v == null ? '—' : v.toStringAsFixed(2);
    String formatPrice(double? v) => v == null ? '—' : '₹${v.toStringAsFixed(2)}';

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (isCurrent) return const Color(0xFF00C896).withOpacity(0.04);
        if (states.contains(WidgetState.hovered)) return Colors.white.withOpacity(0.02);
        return Colors.transparent;
      }),
      cells: [
        DataCell(
          Container(
            decoration: isCurrent ? const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFF00C896), width: 2))
            ) : null,
            padding: EdgeInsets.only(left: isCurrent ? 8.0 : 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.symbol ?? '—',
                      style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: context.borderColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(color: context.textSecondary, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  p.companyName != null && p.companyName!.length > 28 
                      ? '${p.companyName!.substring(0, 28)}…' 
                      : (p.companyName ?? ''),
                  style: TextStyle(color: context.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        DataCell(Text(formatPrice(p.currentPrice), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500))),
        DataCell(Text(p.dayChangePercent == null ? '—' : '${p.dayChangePercent! >= 0 ? '+' : ''}${p.dayChangePercent!.toStringAsFixed(2)}%', style: TextStyle(color: chgColor))),
        DataCell(Text(formatVal(p.pe), style: TextStyle(color: context.textSecondary))),
        DataCell(Text(formatVal(p.pb), style: TextStyle(color: context.textSecondary))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(formatVal(p.roe), style: TextStyle(color: roeColor)),
              if (p.roe != null) ...[
                const SizedBox(width: 6),
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: roePct,
                    child: Container(
                      decoration: BoxDecoration(
                        color: roeColor,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        DataCell(Text(formatVal(p.roce), style: TextStyle(color: roceColor))),
        DataCell(Text(formatVal(p.evEbitda), style: TextStyle(color: context.textSecondary))),
      ],
    );
  }
}
