import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_common/am_common.dart';
import 'package:intl/intl.dart';

import '../../domain/models/basket_detail.dart';
import '../providers/basket_providers.dart';

class BasketDashboardPage extends ConsumerStatefulWidget {
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
  ConsumerState<BasketDashboardPage> createState() => _BasketDashboardPageState();
}

class _BasketDashboardPageState extends ConsumerState<BasketDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(basketDetailProvider(
      basketId: widget.basketId,
      userId: widget.userId,
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basket Dashboard'),
        leading: widget.embedded
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
          final pnlColor = basket.totalPnL >= 0 ? Colors.green : Colors.red;
          final pnlSign = basket.totalPnL >= 0 ? '+' : '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Text(
                  basket.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  basket.etfName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Current Value',
                        value: NumberFormat.currency(symbol: '\$').format(basket.totalCurrentValue),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total PnL',
                        value: '$pnlSign${NumberFormat.currency(symbol: '\$').format(basket.totalPnL)}',
                        valueColor: pnlColor,
                        subtitle: '$pnlSign${basket.pnlPercent.toStringAsFixed(2)}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Status breakdown
                Text(
                  'Composition Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatusBadge(label: 'Held', count: basket.heldCount, color: Colors.green),
                    _StatusBadge(label: 'Missing', count: basket.missingCount, color: Colors.red),
                    _StatusBadge(label: 'Underfunded', count: basket.underfundedCount, color: Colors.orange),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Holdings List
                Text(
                  'Holdings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                ...basket.lines.map((line) => _BasketLineTile(line: line)),
              ],
            ),
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
                  basketId: widget.basketId,
                  userId: widget.userId,
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final String? subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.valueColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.colors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
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

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.divider),
      ),
      child: ListTile(
        title: Row(
          children: [
            Text(line.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: AppSpacing.sm),
            Container(
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
          ],
        ),
        subtitle: Text(line.sector ?? 'Unknown Sector'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormat.currency(symbol: '\$').format(line.currentPrice),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '$pnlSign${NumberFormat.currency(symbol: '\$').format(line.pnl)}',
              style: TextStyle(color: pnlColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
