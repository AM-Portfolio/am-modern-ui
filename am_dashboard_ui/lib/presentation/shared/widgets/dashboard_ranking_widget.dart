import 'package:am_dashboard_ui/domain/models/top_movers_response.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'glass_card.dart';

/// Lumina Market Movers widget with sortable columns and pagination.
class DashboardRankingWidget extends StatefulWidget {
  final List<MoverItem> gainers;
  final List<MoverItem> losers;

  const DashboardRankingWidget({
    super.key,
    required this.gainers,
    required this.losers,
  });

  factory DashboardRankingWidget.errorState() {
    return const DashboardRankingWidget(gainers: [], losers: []);
  }

  @override
  State<DashboardRankingWidget> createState() => _DashboardRankingWidgetState();
}

class _DashboardRankingWidgetState extends State<DashboardRankingWidget> {
  bool _showGainers = true;

  @override
  Widget build(BuildContext context) {
    final items = _showGainers ? widget.gainers : widget.losers;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceVariant = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final toggleBgColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
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
          Text(
            'Market Movers',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: onSurface,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: toggleBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('Gainers', true, isDark),
                _buildToggleButton('Losers', false, isDark),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              if (isMobile) {
                return _buildMobileList(
                  items,
                  isDark,
                  currencyFormat,
                  onSurface,
                  onSurfaceVariant,
                );
              }
              return SizedBox(
                height: 280,
                child: PaginatedSortableTable<MoverItem>(
                  items: items,
                  pageSize: 10,
                  pageSizeOptions: const [5, 10, 25],
                  initialSortColumnIndex: 2,
                  initialSortDirection: _showGainers
                      ? SortDirection.descending
                      : SortDirection.ascending,
                  headerTextStyle: headerStyle,
                  rowTextStyle: rowStyle,
                  headerBackgroundColor: isDark
                      ? Colors.transparent
                      : const Color(0xFFF8FAFC),
                  rowHoverColor: isDark
                      ? Colors.white.withOpacity(0.04)
                      : const Color(0xFFF8FAFC),
                  emptyMessage: 'No data available',
                  columns: [
                    SortableColumn<MoverItem>(
                      title: 'Ticker',
                      flex: 3,
                      sortBy: (item) => item.symbol,
                      builder: (item) {
                        final showName =
                            item.name.isNotEmpty && item.name != item.symbol;
                        return Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.symbol,
                                style: rowStyle.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showName) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: rowStyle.copyWith(
                                    color: onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    SortableColumn<MoverItem>(
                      title: 'Price',
                      flex: 2,
                      textAlign: TextAlign.end,
                      sortBy: (item) => item.price,
                      builder: (item) => Text(
                        currencyFormat.format(item.price),
                        textAlign: TextAlign.right,
                        style: rowStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SortableColumn<MoverItem>(
                      title: 'Change %',
                      flex: 2,
                      textAlign: TextAlign.end,
                      sortBy: (item) => item.changePercentage,
                      builder: (item) {
                        final positive = item.changePercentage >= 0;
                        return Text(
                          '${positive ? '+' : ''}${item.changePercentage.toStringAsFixed(2)}%',
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
                    SortableColumn<MoverItem>(
                      title: 'Change ₹',
                      flex: 2,
                      textAlign: TextAlign.end,
                      sortBy: (item) => item.changeAmount,
                      builder: (item) {
                        final positive = item.changeAmount >= 0;
                        return Text(
                          currencyFormat.format(item.changeAmount),
                          textAlign: TextAlign.right,
                          style: rowStyle.copyWith(
                            color: positive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(
    List<MoverItem> items,
    bool isDark,
    NumberFormat currencyFormat,
    Color onSurface,
    Color onSurfaceVariant,
  ) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: onSurfaceVariant),
          ),
        ),
      );
    }

    // Show only up to 5 items on mobile to save vertical space
    final displayItems = items.take(5).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayItems.length,
      separatorBuilder: (context, index) => Divider(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : const Color(0xFFE2E8F0),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final item = displayItems[index];
        final positive = item.changePercentage >= 0;
        final changeColor = positive
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  item.symbol.isNotEmpty ? item.symbol[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Ticker and Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.symbol,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    if (item.name.isNotEmpty && item.name != item.symbol)
                      Text(
                        item.name,
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
              // Price and Change
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(item.price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: onSurface,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${positive ? '+' : ''}${item.changePercentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: changeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleButton(String label, bool isGainers, bool isDark) {
    final isSelected = _showGainers == isGainers;
    final onSurfaceVariant = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    return GestureDetector(
      onTap: () => setState(() => _showGainers = isGainers),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? (isDark ? Colors.black : const Color(0xFF111827))
                : onSurfaceVariant,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
