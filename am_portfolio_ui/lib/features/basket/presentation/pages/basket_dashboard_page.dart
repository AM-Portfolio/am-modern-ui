import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_common/am_common.dart';
import 'package:intl/intl.dart';

import '../../domain/models/basket_detail.dart';
import '../providers/basket_providers.dart';

class BasketDashboardPage extends ConsumerWidget {
  final String basketId;
  final String userId;
  final bool embedded;

  const BasketDashboardPage({
    super.key,
    required this.basketId,
    required this.userId,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(basketDetailProvider(
      basketId: basketId,
      userId: userId,
    ));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      appBar: AppBar(
        title: const Text('Basket Dashboard'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
        leading: embedded
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: detailAsync.when(
        data: (basket) {
          if (basket == null) {
            return const Center(child: Text('Basket not found'));
          }

          final colors = context.colors;
          final pnlColor = basket.totalPnL >= 0 ? Colors.greenAccent.shade400 : Colors.redAccent.shade400;
          final pnlSign = basket.totalPnL >= 0 ? '+' : '';
          
          final dateFormat = DateFormat('MMM dd, yyyy');
          // Dummy date since it's not in the model yet, fallback to now
          final createdDateStr = dateFormat.format(DateTime.now());

          final heldLines = basket.lines.where((l) => l.status == 'HELD').toList();
          final substituteLines = basket.lines.where((l) => l.status == 'SUBSTITUTE').toList();
          final missingLines = basket.lines.where((l) => l.status == 'MISSING').toList();
          final underfundedLines = basket.lines.where((l) => l.status == 'UNDERFUNDED').toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section
                      Text(
                        basket.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${basket.etfName}  ●  Created $createdDateStr',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _PremiumSummaryCard(
                              title: 'Invested Value',
                              value: '₹${NumberFormat('#,##,##0.00').format(basket.totalCurrentValue - basket.totalPnL)}',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _PremiumSummaryCard(
                              title: 'Current Value',
                              value: '₹${NumberFormat('#,##,##0.00').format(basket.totalCurrentValue)}',
                              trendIcon: basket.totalPnL >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                              trendColor: pnlColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // Total P&L Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: AppRadii.card,
                          border: Border.all(color: colors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total P&L:', style: Theme.of(context).textTheme.titleMedium),
                            Row(
                              children: [
                                Text(
                                  '$pnlSign₹${NumberFormat('#,##,##0.00').format(basket.totalPnL)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: pnlColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '($pnlSign${basket.pnlPercent.toStringAsFixed(2)}%)',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: pnlColor,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),

                      // Composition Progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Composition',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              _CompactStatusLabel(label: 'Held', count: basket.heldCount, color: Colors.green),
                              const SizedBox(width: 8),
                              _CompactStatusLabel(label: 'Sub', count: substituteLines.length, color: Colors.purple),
                              const SizedBox(width: 8),
                              _CompactStatusLabel(label: 'Missing', count: basket.missingCount, color: Colors.red),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Mock progress bar
                      LinearProgressIndicator(
                        value: 0.82,
                        backgroundColor: colors.divider,
                        color: colors.actionPrimaryBg,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('82% Match', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                    ],
                  ),
                ),
              ),

              if (heldLines.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: Text('Held Assets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: _BasketLineTile(line: heldLines[index]),
                    ),
                    childCount: heldLines.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              ],

              if (substituteLines.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: Text('Substitute Assets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.purple)),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: _BasketLineTile(line: substituteLines[index]),
                    ),
                    childCount: substituteLines.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              ],

              if (underfundedLines.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: Text('Underfunded Assets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: _BasketLineTile(line: underfundedLines[index]),
                    ),
                    childCount: underfundedLines.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              ],

              if (missingLines.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: Text('Missing Assets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: _BasketLineTile(line: missingLines[index]),
                    ),
                    childCount: missingLines.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load dashboard', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.invalidate(basketDetailProvider(
                  basketId: basketId,
                  userId: userId,
                )),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? trendIcon;
  final Color? trendColor;

  const _PremiumSummaryCard({
    required this.title,
    required this.value,
    this.trendIcon,
    this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadii.card,
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trendIcon != null)
                Icon(trendIcon, color: trendColor, size: 24),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactStatusLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CompactStatusLabel({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _HoldingsList extends StatelessWidget {
  final List<BasketLineDetail> lines;

  const _HoldingsList({required this.lines});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const Center(
        child: Text('No assets in this category.', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: lines.length,
      itemBuilder: (context, index) => _BasketLineTile(line: lines[index]),
    );
  }
}

class _BasketLineTile extends StatelessWidget {
  final BasketLineDetail line;

  const _BasketLineTile({required this.line});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (line.status) {
      case 'HELD':
        statusColor = Colors.green;
        break;
      case 'MISSING':
        statusColor = Colors.red;
        break;
      case 'SUBSTITUTE':
        statusColor = Colors.purple;
        break;
      case 'UNDERFUNDED':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    final pnlColor = line.pnl >= 0 ? Colors.green : Colors.red;
    final pnlSign = line.pnl >= 0 ? '+' : '';
    final isMissing = line.status == 'MISSING';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Symbol & Sector
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  line.etfWeight != null ? '${line.etfWeight?.toStringAsFixed(1)}% ETF weight' : 'ETF Stock',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
          
          // Status Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  line.status,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          
          // Price & PnL
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isMissing ? '-' : '₹${NumberFormat('#,##,##0.00').format(line.currentPrice)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  isMissing ? '-' : '$pnlSign₹${NumberFormat('#,##,##0.00').format(line.pnl)}',
                  style: TextStyle(color: isMissing ? Colors.grey : pnlColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Weight
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                line.etfWeight != null ? '${line.etfWeight?.toStringAsFixed(1)}%' : '-',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
