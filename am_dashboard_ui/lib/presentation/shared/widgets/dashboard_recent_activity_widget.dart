import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/domain/models/recent_activity_response.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/activity_status_filter.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/recent_activity_mobile_section.dart';
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
          _pageSize = response.totalItems > 20 ? 50 : 25;
          _page = 0;
        }),
        onJumpToLatest: () {
          // Newest rows: page 0 for TIMESTAMP desc; last page when ascending.
          final lastPage = (response.totalPages - 1).clamp(0, 1 << 30);
          final target = _sortBy == 'TIMESTAMP' &&
                  _sortDirection == SortDirection.ascending
              ? lastPage
              : 0;
          setState(() => _page = target);
        },
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
class DashboardRecentActivityWidget extends StatefulWidget {
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
    this.onJumpToLatest,
  });

  final RecentActivityResponse response;
  final int pageSize;
  final int sortColumnIndex;
  final SortDirection sortDirection;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;
  final void Function(int columnIndex, SortDirection direction)? onSort;
  final VoidCallback? onViewAll;
  final VoidCallback? onJumpToLatest;

  @override
  State<DashboardRecentActivityWidget> createState() =>
      _DashboardRecentActivityWidgetState();
}

class _DashboardRecentActivityWidgetState
    extends State<DashboardRecentActivityWidget> {
  ActivityStatusFilter _filter = ActivityStatusFilter.all;
  final ScrollController _tableScroll = ScrollController();

  @override
  void dispose() {
    _tableScroll.dispose();
    super.dispose();
  }

  List<ActivityItem> get _filtered =>
      filterActivitiesByStatus(widget.response.items, _filter);

  static bool _isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  void _jumpToLatest() {
    final response = widget.response;
    final lastPage = (response.totalPages - 1).clamp(0, 1 << 30);
    final newestOnLastPage =
        widget.sortColumnIndex == 2 &&
        widget.sortDirection == SortDirection.ascending;
    final targetPage = newestOnLastPage ? lastPage : 0;
    if (response.page != targetPage) {
      widget.onJumpToLatest?.call();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tableScroll.hasClients) return;
      final offset = newestOnLastPage
          ? _tableScroll.position.maxScrollExtent
          : _tableScroll.position.minScrollExtent;
      _tableScroll.animateTo(
        offset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile(context)) {
      return RecentActivityMobileSection(
        activities: _filtered,
        totalItems: widget.response.totalItems,
        pageSize: widget.pageSize,
        currentPage: widget.response.page,
        totalPages: widget.response.totalPages,
        statusFilter: _filter,
        onStatusFilterChanged: (f) => setState(() => _filter = f),
        onViewAll: widget.onViewAll,
        onPageChanged: widget.onPageChanged,
      );
    }

    return _buildDesktopTable(context);
  }

  Widget _buildFilterChips(BuildContext context) {
    final chips = <(ActivityStatusFilter, String)>[
      (ActivityStatusFilter.all, 'All'),
      (ActivityStatusFilter.win, 'Win'),
      (ActivityStatusFilter.loss, 'Loss'),
      (ActivityStatusFilter.neutral, 'Neutral'),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final (value, label) in chips)
          FilterChip(
            label: Text(label, style: context.text.caption()),
            selected: _filter == value,
            onSelected: (_) => setState(() => _filter = value),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    final isDark = context.isDark;
    final onSurface = context.colors.textPrimary;
    final onSurfaceVariant = context.colors.textSecondary;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy');
    final headerStyle = context.text.caption().copyWith(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
    final rowStyle = context.text.label().copyWith(color: onSurface);
    final activities = _filtered;
    final showJump = widget.response.totalItems > widget.pageSize ||
        widget.response.totalItems > 20;

    return AmGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: context.text.sectionTitle(compact: true).copyWith(
                      color: onSurface,
                    ),
              ),
              if (widget.response.totalItems > widget.pageSize)
                InkWell(
                  onTap: widget.onViewAll,
                  hoverColor: Colors.transparent,
                  child: Text(
                    'View All (${widget.response.totalItems}) →',
                    style: context.text.link(compact: true).copyWith(
                          color: context.colors.actionPrimaryBg,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFilterChips(context),
          const SizedBox(height: AppSpacing.sm + 4),
          LayoutBuilder(
            builder: (context, constraints) {
              final table = SizedBox(
                height: 450,
                child: PaginatedSortableTable<ActivityItem>(
                  items: activities,
                  pageSize: widget.pageSize,
                  pageSizeOptions: const [10, 25, 50],
                  initialSortColumnIndex: widget.sortColumnIndex,
                  initialSortDirection: widget.sortDirection,
                  serverPagination: true,
                  serverTotalItems: widget.response.totalItems,
                  serverTotalPages: widget.response.totalPages,
                  serverCurrentPage: widget.response.page,
                  onServerPageChanged: widget.onPageChanged,
                  onServerPageSizeChanged: widget.onPageSizeChanged,
                  onServerSort: widget.onSort,
                  scrollController: _tableScroll,
                  footerTrailing: showJump
                      ? TextButton(
                          onPressed: _jumpToLatest,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            'Jump to latest',
                            style: context.text.caption().copyWith(
                                  color: context.colors.actionPrimaryBg,
                                ),
                          ),
                        )
                      : null,
                  headerTextStyle: headerStyle,
                  rowTextStyle: rowStyle,
                  headerBackgroundColor: isDark
                      ? Colors.transparent
                      : context.colors.actionPrimaryBg.withValues(alpha: 0.05),
                  rowHoverColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : context.colors.actionPrimaryBg.withValues(alpha: 0.05),
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
                                ? context.colors.statusSuccess
                                : context.colors.statusError,
                          ),
                        );
                      },
                    ),
                  ],
                ),
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
        ],
      ),
    );
  }
}
