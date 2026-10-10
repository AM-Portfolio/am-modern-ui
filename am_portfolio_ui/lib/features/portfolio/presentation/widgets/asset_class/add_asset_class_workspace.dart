import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/asset_class/holding_form_state.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/asset_class/asset_type_selector.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/asset_class/holdings_table.dart';
import 'package:am_portfolio_ui/features/portfolio/providers/portfolio_providers.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/intelligence_donut.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/intelligence_currency.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_intelligence.dart';
import 'dart:ui';

class AddAssetClassWorkspace extends ConsumerStatefulWidget {
  const AddAssetClassWorkspace({
    super.key,
    required this.portfolioId,
    required this.portfolioName,
    required this.onComplete,
    this.onOpenDocIntel,
  });

  final String portfolioId;
  final String? portfolioName;
  final VoidCallback onComplete;
  final VoidCallback? onOpenDocIntel;

  @override
  ConsumerState<AddAssetClassWorkspace> createState() =>
      _AddAssetClassWorkspaceState();
}

class _AddAssetClassWorkspaceState
    extends ConsumerState<AddAssetClassWorkspace> {
  bool _isSaving = false;

  void _handleCancel() {
    widget.onComplete();
  }

  Future<void> _handleSave() async {
    final type = ref.read(addAssetClassTypeProvider);
    final holdings = ref.read(addAssetClassHoldingsProvider);
    final theme = Theme.of(context);

    // Basic Validation
    if (holdings.isEmpty) return;
    for (int i = 0; i < holdings.length; i++) {
      final h = holdings[i];
      if (h.name.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Row ${i + 1}: Name is required.'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        return;
      }
      final val = double.tryParse(h.totalValue);
      if (val == null || val <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Row ${i + 1}: Total Value is required and must be > 0.',
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final remote = await ref.read(portfolioRemoteDataSourceProvider.future);

      final items = holdings.map((h) {
        final val = double.parse(h.totalValue.trim());
        final qtyStr = h.quantity.trim();
        final priceStr = h.pricePerUnit.trim();

        return <String, dynamic>{
          'name': h.name.trim(),
          if (h.symbol.trim().isNotEmpty) 'symbol': h.symbol.trim(),
          if (type == 'bonds' && h.segment != null) 'bondType': h.segment,
          if (type == 'commodities' && h.exchange != null)
            'exchangeCode': h.exchange,
          'currency': 'INR',
          'quantity': qtyStr.isNotEmpty ? double.parse(qtyStr) : 1.0,
          'currentPrice': priceStr.isNotEmpty ? double.parse(priceStr) : val,
          'currentValue': val,
        };
      }).toList();

      await remote.replaceAssetClassList(widget.portfolioId, type, items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Asset Class added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cancelButton = TextButton(
      onPressed: _isSaving ? null : _handleCancel,
      child: Text(
        'Cancel',
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );

    final saveButton = FilledButton(
      onPressed: _isSaving ? null : _handleSave,
      style: FilledButton.styleFrom(
        backgroundColor: ModuleColors.portfolio,
        foregroundColor: context.colors.actionPrimaryFg,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: _isSaving
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colors.actionPrimaryFg,
              ),
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
    );

    final stickyBar = Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.95)
            : theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadow(isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(children: [cancelButton, const Spacer(), saveButton]),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1200;
          final isTablet =
              constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
          final isMobile = constraints.maxWidth < 768;

          final topHeader = Padding(
            padding: isMobile
                ? const EdgeInsets.only(bottom: AppSpacing.md)
                : const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Select Asset Class Type',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: _handleCancel,
                ),
              ],
            ),
          );

          if (isMobile) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        topHeader,
                        const AssetTypeSelector(),
                        const SizedBox(height: AppSpacing.lg),
                        HoldingsTable(
                          isDesktop: false,
                          portfolioId: widget.portfolioId,
                          onOpenDocIntel: widget.onOpenDocIntel,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _LiveSummaryCard(
                          portfolioName: widget.portfolioName,
                          isMobile: true,
                        ),
                      ],
                    ),
                  ),
                ),
                stickyBar,
              ],
            );
          }

          // Desktop / Tablet
          final flex = isTablet ? 6 : 7;
          final panelWidth = isTablet ? 280.0 : 340.0;

          return Column(
            children: [
              topHeader,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: flex,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AssetTypeSelector(),
                            const SizedBox(height: 12),
                            HoldingsTable(
                              isDesktop: true,
                              portfolioId: widget.portfolioId,
                              onOpenDocIntel: widget.onOpenDocIntel,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: panelWidth,
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: SingleChildScrollView(
                        child: _LiveSummaryCard(
                          portfolioName: widget.portfolioName,
                          isMobile: false,
                          cancelButton: cancelButton,
                          saveButton: saveButton,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StepBadge extends StatelessWidget {
  const StepBadge(this.step, {super.key});
  final String step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: ModuleColors.portfolio,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          step,
          style: TextStyle(
            color: context.colors.actionPrimaryFg,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _LiveSummaryCard extends ConsumerWidget {
  const _LiveSummaryCard({
    this.portfolioName,
    this.isMobile = false,
    this.cancelButton,
    this.saveButton,
  });
  final String? portfolioName;
  final bool isMobile;
  final Widget? cancelButton;
  final Widget? saveButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final holdings = ref.watch(addAssetClassHoldingsProvider);
    final type = ref.watch(addAssetClassTypeProvider);

    double totalValue = 0;
    double totalQty = 0;
    for (final h in holdings) {
      totalValue += double.tryParse(h.totalValue) ?? 0;
      totalQty += double.tryParse(h.quantity) ?? 0;
    }

    int meaningfulHoldingsCount = holdings
        .where((h) => h.name.trim().isNotEmpty)
        .length;

    String typeTitle = 'Bonds';
    IconData icon = Icons.account_balance;
    if (type == 'commodities') {
      typeTitle = 'Commodities';
      icon = Icons.category;
    } else if (type == 'cash') {
      typeTitle = 'Cash';
      icon = Icons.money;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Asset Class Preview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icon, color: ModuleColors.portfolio, size: 24),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      type == 'bonds'
                          ? 'Bond'
                          : type == 'commodities'
                          ? 'Commodity'
                          : 'Cash',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    'Total $typeTitle',
                    '$meaningfulHoldingsCount',
                  ),
                ),
                if (type != 'cash')
                  Expanded(
                    child: _StatColumn(
                      'Total Qty',
                      totalQty.toStringAsFixed(0),
                    ),
                  ),
                Expanded(
                  child: _StatColumn(
                    'Total Investment',
                    formatIntelligenceCompactInr(totalValue),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            if (holdings.isNotEmpty && !isMobile) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    type == 'bonds' ? 'Bond Name' : 'Name',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Value (INR)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppSpacing.md),

              ...holdings
                  .where((h) => (double.tryParse(h.totalValue) ?? 0) > 0)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                    final index = entry.key;
                    final h = entry.value;
                    final hValue = double.parse(h.totalValue);
                    final weight = totalValue > 0 ? (hValue / totalValue) : 0.0;
                    final color = IntelligenceColors.chartColor(index);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  h.name.trim().isNotEmpty
                                      ? h.name
                                      : 'New Asset',
                                  style: TextStyle(
                                    fontWeight: h.name.trim().isNotEmpty
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: h.name.trim().isNotEmpty
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '₹${hValue.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: weight,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

              const SizedBox(height: AppSpacing.xl),
            ],

            // Donut Chart
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IntelligenceDonutView(
                  weights: holdings
                      .where((h) => (double.tryParse(h.totalValue) ?? 0) > 0)
                      .map((h) {
                        final hValue = double.parse(h.totalValue);
                        return XrayWeight(
                          name: h.name.trim().isNotEmpty ? h.name : 'New Asset',
                          valueInr: hValue,
                          weightPct: totalValue > 0 ? hValue / totalValue : 0,
                        );
                      })
                      .toList(),
                  size: 120,
                  centerLabel: 'Total Value',
                  centerValue: formatIntelligenceCompactInr(totalValue),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: holdings
                        .where((h) => (double.tryParse(h.totalValue) ?? 0) > 0)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                          final index = entry.key;
                          final h = entry.value;
                          final hValue = double.parse(h.totalValue);
                          final weight = totalValue > 0
                              ? (hValue / totalValue)
                              : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: IntelligenceColors.chartColor(index),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    h.name.trim().isNotEmpty
                                        ? h.name
                                        : 'New Asset',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: h.name.trim().isNotEmpty
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${(weight * 100).toStringAsFixed(1)}%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: IntelligenceColors.chartColor(index),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ],
            ),

            if (!isMobile && cancelButton != null && saveButton != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              Row(children: [cancelButton!, const Spacer(), saveButton!]),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
