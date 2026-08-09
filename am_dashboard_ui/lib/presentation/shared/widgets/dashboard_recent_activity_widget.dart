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
    final onSurface = context.colors.textPrimary;
    final onSurfaceVariant = context.colors.textSecondary;
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
                      color: context.colors.actionPrimaryBg,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = MediaQuery.of(context).size.width < 600;
                if (isMobile) {
                  return _buildMobileList(activities, isDark, currencyFormat, dateFormat, onSurface, onSurfaceVariant);
                }
                
                final table = SizedBox(
                  height: 300,
                  child: PaginatedSortableTable<ActivityItem>(
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
                      isDark ? Colors.transparent : context.colors.actionPrimaryBg.withValues(alpha: 0.05),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(
    List<ActivityItem> items,
    bool isDark,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
    Color onSurface,
    Color onSurfaceVariant,
  ) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('No recent activity', style: TextStyle(color: onSurfaceVariant)),
        ),
      );
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isBuy = item.description.toLowerCase().contains('buy') || 
                      item.description.toLowerCase().contains('deposit') ||
                      (item.quantity != null && item.quantity! > 0);
        final isSell = item.description.toLowerCase().contains('sell') || 
                       item.description.toLowerCase().contains('withdraw') ||
                       (item.quantity != null && item.quantity! < 0);
        
        final iconColor = isBuy 
            ? context.colors.statusSuccess 
            : isSell 
                ? context.colors.statusError 
                : context.colors.textSecondary;

        final iconData = isBuy 
            ? Icons.arrow_downward_rounded 
            : isSell 
                ? Icons.arrow_upward_rounded 
                : Icons.swap_horiz_rounded;

        final symbol = (item.symbol ?? item.title).toUpperCase();
        
        final subtitleDesc = item.description.contains('@') 
            ? item.description.split('@').last.trim() 
            : item.description;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Body (Title and Date)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item.symbol ?? item.title).toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: onSurface,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subtitleDesc • ${dateFormat.format(item.timestamp)}',
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Trailing (Amount and Status)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.currentValue != null 
                        ? currencyFormat.format(item.currentValue) 
                        : (item.quantity != null ? '${item.quantity} units' : ''),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: onSurface,
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (item.status != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : context.colors.actionPrimaryBg.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.status!,
                        style: TextStyle(
                          color: onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
