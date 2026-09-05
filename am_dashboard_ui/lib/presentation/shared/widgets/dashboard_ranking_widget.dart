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
    final isDark = context.isDark;
    final onSurface = context.colors.textPrimary;
    final onSurfaceVariant = context.colors.textSecondary;
    final toggleBgColor = isDark
        ? context.colors.surface.withValues(alpha: 0.5)
        : context.colors.actionPrimaryBg.withValues(alpha: 0.1);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final headerStyle = context.text.caption().copyWith(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
    final rowStyle = context.text.label().copyWith(color: onSurface);

    return AmGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Movers',
            style: context.text.sectionTitle(compact: true).copyWith(
                  color: onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: toggleBgColor,
              borderRadius: AppRadii.button,
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('Gainers', true, isDark),
                _buildToggleButton('Losers', false, isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              if (isMobile) {
                return _buildMobileList(items, isDark, currencyFormat, onSurface, onSurfaceVariant);
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
              headerBackgroundColor:
                  isDark ? Colors.transparent : context.colors.actionPrimaryBg.withValues(alpha: 0.05),
              rowHoverColor:
                  isDark ? Colors.white.withOpacity(0.04) : context.colors.actionPrimaryBg.withValues(alpha: 0.05),
              emptyMessage: 'No data available',
              columns: [
                SortableColumn<MoverItem>(
                  title: 'Ticker',
                  flex: 3,
                  sortBy: (item) => item.symbol,
                  builder: (item) {
                    final isIsinTicker = _looksLikeIsin(item.symbol);
                    // When legacy data still has ISIN as symbol, show company name as primary label.
                    final primaryLabel = (isIsinTicker && item.name.isNotEmpty)
                        ? item.name
                        : item.symbol;
                    final subtitle = isIsinTicker && item.name.isNotEmpty
                        ? item.symbol
                        : (item.name.isNotEmpty && item.name != item.symbol
                            ? item.name
                            : null);

                    return Row(
                      children: [
                        Flexible(
                          child: Text(
                            primaryLabel,
                            style: rowStyle.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: rowStyle.copyWith(color: onSurfaceVariant),
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
                            ? context.colors.statusSuccess
                            : context.colors.statusError,
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
                            ? context.colors.statusSuccess
                            : context.colors.statusError,
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
          child: Text('No data available', style: TextStyle(color: onSurfaceVariant)),
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
        color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final item = displayItems[index];
        final positive = item.changePercentage >= 0;
        final changeColor = positive ? context.colors.statusSuccess : context.colors.statusError;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : context.colors.actionPrimaryBg.withValues(alpha: 0.1),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  /// Indian equity ISIN pattern (e.g. INE002A01018) — used when Mongo still has legacy symbol values.
  static bool _looksLikeIsin(String value) {
    if (value.length != 12) return false;
    return RegExp(r'^[A-Z]{2}[A-Z0-9]{10}$').hasMatch(value.toUpperCase());
  }

  Widget _buildToggleButton(String label, bool isGainers, bool isDark) {
    final isSelected = _showGainers == isGainers;
    final onSurfaceVariant = context.colors.textSecondary;
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
                ? (isDark ? Colors.black : context.colors.textPrimary)
                : onSurfaceVariant,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
