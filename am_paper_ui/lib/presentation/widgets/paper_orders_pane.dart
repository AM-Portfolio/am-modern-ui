import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/oms_models.dart';
import '../paper_oms_cubit.dart';
import '../paper_oms_state.dart';
import 'paper_order_mobile_card.dart';

enum _OrdersFilter { all, pending, executed, failed }

const _typeOptions = <String>['ALL', 'MARKET', 'LIMIT', 'SUPER', 'TRAIL', 'STOP'];

class _OrderRow {
  const _OrderRow({
    required this.order,
    required this.side,
    required this.symbol,
    required this.orderType,
    required this.qtyLabel,
    required this.price,
    required this.displayStatus,
    required this.time,
    required this.timeLabel,
  });

  final OmsOrder order;
  final String side;
  final String symbol;
  final String orderType;
  final String qtyLabel;
  final double price;
  final String displayStatus;
  final DateTime time;
  final String timeLabel;
}

/// Today's paper orders — unified table matching docs/paper-orders-session/order.png.
class PaperOrdersPane extends StatefulWidget {
  const PaperOrdersPane({super.key, this.onReorder});

  /// Opens ticket prefilled for Re-order / Retry.
  final void Function(OmsOrder order)? onReorder;

  @override
  State<PaperOrdersPane> createState() => _PaperOrdersPaneState();
}

class _PaperOrdersPaneState extends State<PaperOrdersPane> {
  static const _defaultPageSize = 25;
  static const _pageSizeOptions = <int>[25, 50];

  _OrdersFilter _filter = _OrdersFilter.all;
  String _typeFilter = 'ALL';
  final _search = TextEditingController();
  int _pageSize = _defaultPageSize;
  int _page = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _resetPage() => _page = 0;

  List<_OrderRow> _pageSlice(List<_OrderRow> rows) {
    if (rows.isEmpty) return const [];
    final pages = (rows.length / _pageSize).ceil().clamp(1, 0x7fffffff);
    final page = _page.clamp(0, pages - 1);
    final start = page * _pageSize;
    final end = (start + _pageSize).clamp(0, rows.length);
    return rows.sublist(start, end);
  }

  Widget _paginationFooter(BuildContext context, int totalItems) {
    if (totalItems == 0) return const SizedBox.shrink();
    final colors = context.colors;
    final totalPages = (totalItems / _pageSize).ceil().clamp(1, 0x7fffffff);
    final page = _page.clamp(0, totalPages - 1);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.textSecondary,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
      child: Row(
        children: [
          Text('${page + 1}/$totalPages · $totalItems', style: labelStyle),
          const Spacer(),
          Text('Rows', style: labelStyle),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: CustomDropdown<int>(
              value: _pageSize,
              height: 32,
              fontSize: 12,
              iconSize: 16,
              borderRadius: 6,
              isExpanded: true,
              primaryColor: colors.actionPrimaryBg,
              backgroundColor: colors.cardSurface,
              borderColor: colors.divider,
              textColor: colors.textPrimary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              items: [
                for (final s in _pageSizeOptions)
                  s.toSimpleDropdownItem(text: '$s', fontSize: 12),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _pageSize = v;
                  _resetPage();
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: page > 0
                ? () => setState(() => _page = page - 1)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: page < totalPages - 1
                ? () => setState(() => _page = page + 1)
                : null,
          ),
        ],
      ),
    );
  }

  List<_OrderRow> _todayRows(PaperOmsState state) {
    final timeFmt = DateFormat('HH:mm:ss');
    final today = state.orders.where((o) {
      if (!o.isCreatedToday) return false;
      return o.isFilled || o.isWorking || o.isRejected || o.isCancelled;
    }).toList()
      ..sort((a, b) {
        final ac = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bc = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bc.compareTo(ac);
      });

    return [
      for (final o in today)
        _OrderRow(
          order: o,
          side: o.side.toUpperCase(),
          symbol: o.symbol.trim().toUpperCase(),
          orderType: o.orderType.toUpperCase(),
          qtyLabel: o.qtyDisplayLabel,
          price: o.displayPrice,
          displayStatus: o.displayStatus,
          time: o.createdAtLocal ?? DateTime.fromMillisecondsSinceEpoch(0),
          timeLabel: o.createdAtLocal != null
              ? timeFmt.format(o.createdAtLocal!)
              : '—',
        ),
    ];
  }

  List<_OrderRow> _applyFilters(List<_OrderRow> rows) {
    final q = _search.text.trim().toUpperCase();
    return rows.where((r) {
      switch (_filter) {
        case _OrdersFilter.all:
          break;
        case _OrdersFilter.pending:
          if (!r.order.isWorking) return false;
        case _OrdersFilter.executed:
          if (!r.order.isFilled) return false;
        case _OrdersFilter.failed:
          if (!r.order.isRejected && !r.order.isCancelled) return false;
      }
      if (_typeFilter != 'ALL' && r.orderType != _typeFilter) return false;
      if (q.isNotEmpty && !r.symbol.contains(q)) return false;
      return true;
    }).toList();
  }

  Color _sideColor(BuildContext context, String side) {
    final colors = context.colors;
    return side == 'SELL'
        ? colors.statusError
        : colors.marketPositiveIndicator;
  }

  Color _statusColor(BuildContext context, String displayStatus) {
    final colors = context.colors;
    switch (displayStatus) {
      case 'OPEN':
        return colors.statusWarning;
      case 'FILLED':
        return colors.marketPositiveIndicator;
      case 'REJECTED':
      case 'CANCELLED':
        return colors.statusError;
      default:
        return colors.textSecondary;
    }
  }

  Widget _sideChip(BuildContext context, String side) {
    final c = _sideColor(context, side);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.55)),
      ),
      child: Text(
        side,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: c,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _statusPill(BuildContext context, String displayStatus) {
    final c = _statusColor(context, displayStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            displayStatus,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: c,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _symbolCell(BuildContext context, String symbol) {
    return Row(
      children: [
        Flexible(
          child: Text(
            symbol,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: context.colors.divider.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            'NSE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  fontSize: 10,
                ),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: context.colors.divider.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            'CNC',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  fontSize: 10,
                ),
          ),
        ),
      ],
    );
  }

  Widget _statChip(BuildContext context, String label, int n, {Color? valueColor}) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            TextSpan(
              text: '$n',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: valueColor ?? colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    Color? countColor,
  }) {
    final colors = context.colors;
    final accent = colors.actionPrimaryBg;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? accent : colors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (countColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: countColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? accent : colors.textSecondary,
                  ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: countColor ??
                        (selected ? accent : colors.textSecondary),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, PaperOmsState state, _OrderRow r) {
    final o = r.order;
    final busy = state.submitting;
    if (o.isWorking) {
      return TextButton(
        onPressed: busy ? null : () => context.read<PaperOmsCubit>().cancel(o.orderId),
        style: TextButton.styleFrom(
          foregroundColor: context.colors.statusError,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Cancel'),
      );
    }
    if (o.isFilled) {
      return TextButton(
        onPressed: widget.onReorder == null ? null : () => widget.onReorder!(o),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Re-order'),
      );
    }
    if (o.isRejected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _showDetails(context, o),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Details'),
          ),
          TextButton(
            onPressed: widget.onReorder == null ? null : () => widget.onReorder!(o),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry'),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  void _showDetails(BuildContext context, OmsOrder o) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${o.displayStatus} · ${o.symbol}'),
        content: Text(
          o.rejectReason == null || o.rejectReason!.isEmpty
              ? 'No reject reason.'
              : omsRejectMessage(o.rejectReason),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, PaperOmsState state, List<_OrderRow> items) {
    final fmt = NumberFormat('#,##0.00');
    return PaginatedSortableTable<_OrderRow>(
      items: items,
      pageSize: _defaultPageSize,
      pageSizeOptions: _pageSizeOptions,
      initialSortColumnIndex: 0,
      initialSortDirection: SortDirection.descending,
      emptyMessage: 'No orders today.',
      columns: [
        SortableColumn(
          title: 'Time',
          sortBy: (r) => r.time.millisecondsSinceEpoch,
          builder: (r) => Text(r.timeLabel),
        ),
        SortableColumn(
          title: 'Side',
          sortBy: (r) => r.side,
          builder: (r) => _sideChip(context, r.side),
        ),
        SortableColumn(
          title: 'Symbol',
          flex: 2,
          sortBy: (r) => r.symbol,
          builder: (r) => _symbolCell(context, r.symbol),
        ),
        SortableColumn(
          title: 'Type',
          sortBy: (r) => r.orderType,
          builder: (r) => Text(r.orderType),
        ),
        SortableColumn(
          title: 'Qty',
          sortBy: (r) => r.order.quantityAsDouble,
          textAlign: TextAlign.end,
          builder: (r) => Text(r.qtyLabel, textAlign: TextAlign.end),
        ),
        SortableColumn(
          title: 'Price',
          sortBy: (r) => r.price,
          textAlign: TextAlign.end,
          builder: (r) => Text(
            r.price > 0 ? '₹${fmt.format(r.price)}' : '—',
            textAlign: TextAlign.end,
          ),
        ),
        SortableColumn(
          title: 'Status',
          sortBy: (r) => r.displayStatus,
          builder: (r) => _statusPill(context, r.displayStatus),
        ),
        SortableColumn(
          title: 'Actions',
          sortBy: (r) => r.displayStatus,
          builder: (r) => _actions(context, state, r),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, PaperOmsState state, _OrderRow r) {
    return PaperOrderMobileCard(
      side: r.side,
      symbol: r.symbol,
      orderType: r.orderType,
      qtyLabel: r.qtyLabel,
      price: r.price,
      status: r.displayStatus,
      timeLabel: r.timeLabel,
      trailing: _actions(context, state, r),
    );
  }

  Widget _typeDropdown(BuildContext context) {
    final colors = context.colors;
    final primary = colors.actionPrimaryBg;
    return SizedBox(
      width: 140,
      child: CustomDropdown<String>(
        value: _typeFilter,
        height: 34,
        fontSize: 12,
        iconSize: 16,
        borderRadius: 6,
        isExpanded: true,
        primaryColor: primary,
        backgroundColor: colors.cardSurface,
        borderColor: colors.divider,
        textColor: colors.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        items: [
          for (final t in _typeOptions)
            t.toSimpleDropdownItem(
              text: t == 'ALL' ? 'All Types' : t,
              fontSize: 12,
            ),
        ],
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _typeFilter = v;
            _resetPage();
          });
        },
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 220,
      height: 34,
      child: TextField(
        controller: _search,
        onChanged: (_) => setState(() {
          _resetPage();
        }),
        style: Theme.of(context).textTheme.bodySmall,
        decoration: InputDecoration(
          hintText: 'Search symbol',
          isDense: true,
          prefixIcon: Icon(Icons.search, size: 18, color: colors.textSecondary),
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 34),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colors.actionPrimaryBg),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return BlocBuilder<PaperOmsCubit, PaperOmsState>(
      builder: (context, state) {
        final all = _todayRows(state);
        final pending = all.where((r) => r.order.isWorking).length;
        final filled = all.where((r) => r.order.isFilled).length;
        final failed = all.where((r) => r.order.isRejected || r.order.isCancelled).length;
        final filtered = _applyFilters(all);
        final pageItems = _pageSlice(filtered);

        Future<void> refresh() => context.read<PaperOmsCubit>().refreshBooks();

        final header = Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Today's orders",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: refresh,
                          icon: const Icon(Icons.refresh, size: 20),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    Text(
                      'Executed, pending, and failed for today',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              _statChip(context, 'Total', all.length),
              const SizedBox(width: 6),
              _statChip(
                context,
                'Filled',
                filled,
                valueColor: colors.marketPositiveIndicator,
              ),
              const SizedBox(width: 6),
              _statChip(
                context,
                'Working',
                pending,
                valueColor: colors.statusWarning,
              ),
              if (pending > 0) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: state.submitting
                      ? null
                      : () => context.read<PaperOmsCubit>().cancelAllPending(),
                  child: const Text('Cancel all'),
                ),
              ],
            ],
          ),
        );

        final filters = Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: isMobile
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ..._filterChips(context, all.length, pending, filled, failed),
                    _searchField(context),
                    _typeDropdown(context),
                  ],
                )
              : Row(
                  children: [
                    for (final chip in _filterChips(
                      context,
                      all.length,
                      pending,
                      filled,
                      failed,
                    )) ...[
                      chip,
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    _searchField(context),
                    const SizedBox(width: 8),
                    _typeDropdown(context),
                  ],
                ),
        );

        final empty = Center(
          child: Text(
            filtered.isEmpty && all.isNotEmpty
                ? 'No orders match filters.'
                : 'No orders today.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        );

        if (isMobile) {
          return RefreshIndicator(
            color: colors.actionPrimaryBg,
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                header,
                filters,
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: empty,
                  )
                else ...[
                  for (final row in pageItems) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildCard(context, state, row),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _paginationFooter(context, filtered.length),
                ],
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            filters,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: AmAdaptiveTableCardView<_OrderRow>(
                  items: filtered,
                  breakpoint: 720,
                  spacing: 10,
                  emptyWidget: empty,
                  tableBuilder: (ctx, items) => _buildTable(ctx, state, items),
                  cardBuilder: (ctx, r, i) => _buildCard(ctx, state, r),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _filterChips(
    BuildContext context,
    int total,
    int pending,
    int filled,
    int failed,
  ) {
    final colors = context.colors;
    return [
      _filterChip(
        context,
        label: 'All',
        count: total,
        selected: _filter == _OrdersFilter.all,
        onTap: () => setState(() {
          _filter = _OrdersFilter.all;
          _resetPage();
        }),
      ),
      _filterChip(
        context,
        label: 'Pending / Working',
        count: pending,
        countColor: colors.statusWarning,
        selected: _filter == _OrdersFilter.pending,
        onTap: () => setState(() {
          _filter = _OrdersFilter.pending;
          _resetPage();
        }),
      ),
      _filterChip(
        context,
        label: 'Executed',
        count: filled,
        countColor: colors.marketPositiveIndicator,
        selected: _filter == _OrdersFilter.executed,
        onTap: () => setState(() {
          _filter = _OrdersFilter.executed;
          _resetPage();
        }),
      ),
      _filterChip(
        context,
        label: 'Failed / Cancelled',
        count: failed,
        countColor: colors.statusError,
        selected: _filter == _OrdersFilter.failed,
        onTap: () => setState(() {
          _filter = _OrdersFilter.failed;
          _resetPage();
        }),
      ),
    ];
  }
}
