import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_portfolio_scope.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/glass_card.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Compact Your Portfolios panel: table (default) or dense cards + Overall XIRR.
///
/// Must sit in a **bounded-height** parent (chart row). [PaginatedSortableTable]
/// uses [Expanded] and cannot live in an unbounded vertical constraint.
class DashboardPortfoliosPanel extends ConsumerStatefulWidget {
  const DashboardPortfoliosPanel({
    super.key,
    required this.hub,
  });

  final AccountsHub hub;

  @override
  ConsumerState<DashboardPortfoliosPanel> createState() =>
      _DashboardPortfoliosPanelState();
}

class _DashboardPortfoliosPanelState
    extends ConsumerState<DashboardPortfoliosPanel> {
  bool _tableView = true;

  static final _inr = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  static final _pct = NumberFormat('0.00');

  List<_PortfolioRow> get _rows {
    final out = <_PortfolioRow>[];
    for (final row in widget.hub.portfolios) {
      if (row.isCdslAggregator) continue;
      final label =
          (row.displayName != null && row.displayName!.trim().isNotEmpty)
              ? row.displayName!.trim()
              : (row.brokerType ?? 'Portfolio');
      out.add(
        _PortfolioRow(
          id: row.portfolioId,
          name: label,
          invested: row.invested ?? 0,
          current: row.current ?? 0,
          returnAbs: row.returnAbs ??
              ((row.current ?? 0) - (row.invested ?? 0)),
          returnPct: row.returnPct ?? 0,
          hasHoldings: row.hasHoldings,
          isPaper: row.dummy == true ||
              label.toLowerCase() == 'paper' ||
              (row.portfolioKind ?? '').toUpperCase() == 'PAPER',
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final xirr = widget.hub.stats?.overallXirrPct;

    return AmGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Portfolios',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: ModuleColors.dashboard,
                  ),
                ),
              ),
              if (xirr != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ModuleColors.dashboard.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: Text(
                    'Overall XIRR ${_pct.format(xirr)}%',
                    style: context.text.caption().copyWith(
                          fontWeight: FontWeight.w700,
                          color: ModuleColors.dashboard,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                tooltip: _tableView ? 'Card view' : 'Table view',
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                onPressed: () => setState(() => _tableView = !_tableView),
                icon: Icon(
                  _tableView ? Icons.view_agenda_outlined : Icons.table_rows,
                  color: ModuleColors.dashboard,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No broker books yet.',
                  style: context.text.caption(),
                ),
              ),
            )
          else if (_tableView)
            Expanded(
              child: PaginatedSortableTable<_PortfolioRow>(
                items: rows,
                pageSize: 10,
                pageSizeOptions: const [5, 10, 25],
                rowHeight: 40,
                showPagination: rows.length > 5,
                onItemTap: (row) {
                  if (!row.hasHoldings && !row.isPaper) return;
                  ref
                      .read(dashboardPortfolioScopeProvider.notifier)
                      .select(row.id);
                },
                columns: [
                  SortableColumn<_PortfolioRow>(
                    title: 'Name',
                    flex: 3,
                    sortBy: (r) => r.name.toLowerCase(),
                    builder: (r) => Text(
                      r.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (!r.hasHoldings && !r.isPaper)
                            ? context.colors.textSecondary
                            : context.colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SortableColumn<_PortfolioRow>(
                    title: 'Invested',
                    flex: 2,
                    sortBy: (r) => r.invested,
                    textAlign: TextAlign.right,
                    builder: (r) => Text(
                      _inr.format(r.invested),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  SortableColumn<_PortfolioRow>(
                    title: 'Current',
                    flex: 2,
                    sortBy: (r) => r.current,
                    textAlign: TextAlign.right,
                    builder: (r) => Text(
                      _inr.format(r.current),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  SortableColumn<_PortfolioRow>(
                    title: 'Return',
                    flex: 2,
                    sortBy: (r) => r.returnAbs,
                    textAlign: TextAlign.right,
                    builder: (r) => Text(
                      _inr.format(r.returnAbs),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: r.returnAbs >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                  SortableColumn<_PortfolioRow>(
                    title: 'Return %',
                    flex: 2,
                    sortBy: (r) => r.returnPct,
                    textAlign: TextAlign.right,
                    builder: (r) => Text(
                      '${_pct.format(r.returnPct)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: r.returnPct >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return _CompactPortfolioCard(
                    row: row,
                    onTap: () {
                      if (!row.hasHoldings && !row.isPaper) return;
                      ref
                          .read(dashboardPortfolioScopeProvider.notifier)
                          .select(row.id);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PortfolioRow {
  const _PortfolioRow({
    required this.id,
    required this.name,
    required this.invested,
    required this.current,
    required this.returnAbs,
    required this.returnPct,
    required this.hasHoldings,
    required this.isPaper,
  });

  final String? id;
  final String name;
  final double invested;
  final double current;
  final double returnAbs;
  final double returnPct;
  final bool hasHoldings;
  final bool isPaper;
}

class _CompactPortfolioCard extends StatelessWidget {
  const _CompactPortfolioCard({required this.row, required this.onTap});

  final _PortfolioRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = !row.hasHoldings && !row.isPaper;
    final inr = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final pct = NumberFormat('0.00');
    return InkWell(
      onTap: muted ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                row.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: muted
                      ? context.colors.textSecondary
                      : context.colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              inr.format(row.current),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              '${pct.format(row.returnPct)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: row.returnPct >= 0
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
