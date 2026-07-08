import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/domain/models/recent_activity_response.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'glass_card.dart';

/// Maps UI column index + direction to API [sortBy] query param.
String activitySortByForColumn(int columnIndex, SortDirection direction) {
  switch (columnIndex) {
    case 0:
      return 'SYMBOL';
    case 1:
      return 'QUANTITY';
    case 2:
      return 'TIMESTAMP';
    case 3:
      return 'CURRENT_VALUE';
    case 4:
      return direction == SortDirection.ascending
          ? 'PROFIT_LOSS_ASC'
          : 'PROFIT_LOSS_PERCENT';
    default:
      return 'TIMESTAMP';
  }
}

/// Recent activity with server-side sort and pagination.
class DashboardRecentActivitySection extends ConsumerStatefulWidget {
  const DashboardRecentActivitySection({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<DashboardRecentActivitySection> createState() =>
      _DashboardRecentActivitySectionState();
}

class _DashboardRecentActivitySectionState
    extends ConsumerState<DashboardRecentActivitySection> {
  int _page = 0;
  int _pageSize = 10;
  String _sortBy = 'TIMESTAMP';
  int _sortColumnIndex = 2;
  SortDirection _sortDirection = SortDirection.descending;

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(
      recentActivityProvider(
        widget.userId,
        page: _page,
        size: _pageSize,
        sortBy: _sortBy,
      ),
    );

    return activityAsync.when(
      data: (response) => DashboardRecentActivityWidget(
        response: response,
        pageSize: _pageSize,
        sortColumnIndex: _sortColumnIndex,
        sortDirection: _sortDirection,
        onPageChanged: (page) => setState(() => _page = page),
        onPageSizeChanged: (size) => setState(() {
          _pageSize = size;
          _page = 0;
        }),
        onSort: (columnIndex, direction) {
          setState(() {
            _sortColumnIndex = columnIndex;
            _sortDirection = direction;
            _sortBy = activitySortByForColumn(columnIndex, direction);
            _page = 0;
          });
        },
        onViewAll: () => setState(() {
          _pageSize = 25;
          _page = 0;
        }),
      ),
      loading: () => const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => AmGlassCard(
        padding: const EdgeInsets.all(16),
        child: AmErrorWidget(
          message: 'Failed to load recent activity',
          onRetry: () => ref.invalidate(
            recentActivityProvider(
              widget.userId,
              page: _page,
              size: _pageSize,
              sortBy: _sortBy,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lumina recent activity table — server paginated when [response] metadata is set.
class DashboardRecentActivityWidget extends StatelessWidget {
  const DashboardRecentActivityWidget({
    super.key,
    required this.response,
    this.pageSize = 10,
    this.sortColumnIndex = 2,
    this.sortDirection = SortDirection.descending,
    this.onPageChanged,
    this.onPageSizeChanged,
    this.onSort,
    this.onViewAll,
  });

  final RecentActivityResponse response;
  final int pageSize;
  final int sortColumnIndex;
  final SortDirection sortDirection;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;
  final void Function(int columnIndex, SortDirection direction)? onSort;
  final VoidCallback? onViewAll;

  List<ActivityItem> get activities => response.items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy');
    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: onSurfaceVariant,
      fontFamily: 'Inter',
    );
    final rowStyle = TextStyle(
      fontSize: 12,
      color: onSurface,
      fontFamily: 'Inter',
    );

    return AmGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: onSurface,
                  fontFamily: 'Inter',
                ),
              ),
              if (response.totalItems > pageSize)
                InkWell(
                  onTap: onViewAll,
                  hoverColor: Colors.transparent,
                  child: Text(
                    'View All (${response.totalItems}) →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2E3192),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final table = PaginatedSortableTable<ActivityItem>(
                  items: activities,
                  pageSize: pageSize,
                  pageSizeOptions: const [10, 25, 50],
                  initialSortColumnIndex: sortColumnIndex,
                  initialSortDirection: sortDirection,
                  serverPagination: true,
                  serverTotalItems: response.totalItems,
                  serverTotalPages: response.totalPages,
                  serverCurrentPage: response.page,
                  onServerPageChanged: onPageChanged,
                  onServerPageSizeChanged: onPageSizeChanged,
                  onServerSort: onSort,
                  headerTextStyle: headerStyle,
                  rowTextStyle: rowStyle,
                  headerBackgroundColor:
                      isDark ? Colors.transparent : const Color(0xFFF8FAFC),
                  rowHoverColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF8FAFC),
                  emptyMessage: 'No recent activity',
                  columns: [
                    SortableColumn<ActivityItem>(
                      title: 'Symbol',
                      flex: 2,
                      sortBy: (item) => item.symbol ?? item.title,
                      builder: (item) => Text(
                        (item.symbol ?? item.title).toUpperCase(),
                        style: rowStyle.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SortableColumn<ActivityItem>(
                      title: 'Units',
                      flex: 2,
                      sortBy: (item) => item.quantity ?? 0,
                      builder: (item) => Text(
                        item.quantity != null
                            ? item.quantity!.toStringAsFixed(0)
                            : item.description,
                        style: rowStyle.copyWith(color: onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SortableColumn<ActivityItem>(
                      title: 'Date',
                      flex: 2,
                      sortBy: (item) => item.timestamp,
                      builder: (item) => Text(
                        dateFormat.format(item.timestamp),
                        style: rowStyle.copyWith(
                          fontSize: 11,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ),
                    SortableColumn<ActivityItem>(
                      title: 'Amount',
                      flex: 2,
                      textAlign: TextAlign.end,
                      sortBy: (item) => item.currentValue ?? 0,
                      builder: (item) => Text(
                        item.amount ??
                            (item.currentValue != null
                                ? currencyFormat.format(item.currentValue)
                                : '—'),
                        textAlign: TextAlign.right,
                        style: rowStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SortableColumn<ActivityItem>(
                      title: 'P&L %',
                      flex: 2,
                      textAlign: TextAlign.end,
                      sortBy: (item) => item.profitLossPercent ?? 0,
                      builder: (item) {
                        final pct = item.profitLossPercent;
                        if (pct == null) {
                          return const Text('—', textAlign: TextAlign.right);
                        }
                        final positive = pct >= 0;
                        return Text(
                          '${positive ? '+' : ''}${pct.toStringAsFixed(2)}%',
                          textAlign: TextAlign.right,
                          style: rowStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: positive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        );
                      },
                    ),
                  ],
                );

                if (constraints.maxWidth < 520) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: 520, child: table),
                  );
                }
                return table;
              },
            ),
          ),
        ],
      ),
    );
  }
}
