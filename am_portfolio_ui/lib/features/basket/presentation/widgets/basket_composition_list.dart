import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:am_design_system/am_design_system.dart';

import '../../domain/models/basket_opportunity.dart';
import '../shared/basket_item_status_theme.dart';

class BasketCompositionList extends StatefulWidget {
  final List<BasketItem> items;

  const BasketCompositionList({
    super.key,
    required this.items,
  });

  @override
  State<BasketCompositionList> createState() => _BasketCompositionListState();
}

class _BasketCompositionListState extends State<BasketCompositionList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<BasketItem> get _matchedItems {
    return widget.items.where((item) => item.status == ItemStatus.held).toList();
  }

  List<BasketItem> get _gapItems {
    return widget.items
        .where((item) =>
            item.status == ItemStatus.missing ||
            item.status == ItemStatus.substitute)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.cardSurface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: ModuleColors.portfolio.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            dividerColor: Colors.transparent,
            labelColor: context.colors.textPrimary,
            unselectedLabelColor: context.colors.textSecondary,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 18),
                    const SizedBox(width: 8),
                    Text('Matched (${_matchedItems.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Text('Gaps (${_gapItems.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStockList(context, _matchedItems),
              _buildStockList(context, _gapItems),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockList(BuildContext context, List<BasketItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No items in this category',
          style: TextStyle(color: context.colors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildStockItem(context, item),
        );
      },
    );
  }

  Widget _buildStockItem(BuildContext context, BasketItem item) {
    if (item.status == ItemStatus.substitute) {
      return _buildSubstituteItem(context, item);
    }

    final statusColor = BasketItemStatusTheme.colorFor(context, item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.cardSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon(item.status),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.stockSymbol,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.sector,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${item.etfWeight.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubstituteItem(BuildContext context, BasketItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ModuleColors.portfolio.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ModuleColors.portfolio.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.statusSuccess.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You Hold',
                              style: TextStyle(
                                color: context.statusSuccess,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.userHoldingSymbol ?? item.stockSymbol,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.swap_horiz,
                        color: ModuleColors.portfolio,
                        size: 28,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.statusWarning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ETF Needs',
                              style: TextStyle(
                                color: context.statusWarning,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.stockSymbol,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.reason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ModuleColors.portfolio.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: ModuleColors.portfolio,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.reason!,
                            style: TextStyle(
                              color: ModuleColors.portfolio,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(ItemStatus status) {
    return switch (status) {
      ItemStatus.held => Icons.check_circle,
      ItemStatus.missing => Icons.add_circle_outline,
      ItemStatus.substitute => Icons.swap_horiz,
      ItemStatus.excluded => Icons.remove_circle_outline,
    };
  }
}
