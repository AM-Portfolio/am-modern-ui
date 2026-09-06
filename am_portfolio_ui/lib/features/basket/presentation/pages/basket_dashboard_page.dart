import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/services.dart';

import '../../domain/models/basket_detail.dart';
import '../providers/basket_providers.dart';
import '../basket_navigation.dart';
import '../widgets/dashboard/bd_allocation_sheet.dart';
import '../widgets/dashboard/bd_dashboard_math.dart';
import '../widgets/dashboard/bd_footer_bar.dart';
import '../widgets/dashboard/bd_holdings_section.dart';
import '../widgets/dashboard/bd_identity_card.dart';
import '../widgets/dashboard/bd_kpi_row.dart';
import '../widgets/dashboard/bd_page_header.dart';
import '../utils/basket_portfolio_sync.dart';
import '../utils/basket_responsive.dart';

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
  BdHoldingsFilter _filter = BdHoldingsFilter.active;
  DateTime _lastFetchedAt = DateTime.now();

  Future<void> _refresh() async {
    ref.invalidate(basketDetailProvider(basketId: widget.basketId, userId: widget.userId));
    setState(() => _lastFetchedAt = DateTime.now());
    await ref.read(basketDetailProvider(basketId: widget.basketId, userId: widget.userId).future);
  }

  void _shareBasket(BasketDetail basket) {
    final summary = 'Basket: ${basket.name}\n'
        'ETF: ${basket.etfName}\n'
        'Invested: ₹${basket.totalInvestedValue.toStringAsFixed(0)}\n'
        'Current: ₹${basket.totalCurrentValue.toStringAsFixed(0)}\n'
        'Coverage: ${BdDashboardMath.coverageAtCreation(basket).toStringAsFixed(0)}%';
    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Basket summary copied to clipboard')),
    );
  }

  void _downloadCsv(BasketDetail basket) {
    final buf = StringBuffer('Symbol,Company,Status,Units,AvgPrice,CurrentPrice,Value,PnL,Weight%\n');
    final total = basket.totalCurrentValue;
    for (final line in basket.lines) {
      final weight = BdDashboardMath.basketWeightPercent(line, total);
      final value = BdDashboardMath.lineCurrentValue(line);
      buf.writeln(
        '${line.symbol},${line.companyName ?? ""},${line.status},${line.quantity},'
        '${line.avgPrice},${line.currentPrice},$value,${line.pnl},${weight.toStringAsFixed(2)}',
      );
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Holdings CSV copied to clipboard')),
    );
  }

  Future<void> _showMoreMenu(BasketDetail basket) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.share_outlined, color: ModuleColors.portfolio),
              title: const Text('Share'),
              onTap: () => Navigator.pop(ctx, 'share'),
            ),
            ListTile(
              leading:
                  Icon(Icons.download_outlined, color: ModuleColors.portfolio),
              title: const Text('Download'),
              onTap: () => Navigator.pop(ctx, 'download'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete basket'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'share') {
      _shareBasket(basket);
      return;
    }
    if (action == 'download') {
      _downloadCsv(basket);
      return;
    }
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete basket?'),
          content: Text('Remove "${basket.name}" permanently?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
          ],
        ),
      );
      if (confirm == true && mounted) {
        try {
          await ref.read(deleteBasketProvider(
            basketId: widget.basketId,
            userId: widget.userId,
          ).future);
          ref.invalidate(myBasketsProvider(userId: widget.userId, portfolioId: ''));
          if (mounted) {
            await BasketPortfolioSync.afterBasketMutation(
              context,
              deletedBasketId: widget.basketId,
            );
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete basket: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(basketDetailProvider(
      basketId: widget.basketId,
      userId: widget.userId,
    ));
    final isMobile = BasketResponsive.isMobile(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: detailAsync.when(
        data: (basket) {
          if (basket.id.isEmpty) {
            return const Center(child: Text('Basket not found'));
          }
          final activeLines = basket.lines.where((l) => l.quantity > 0 || l.status.toUpperCase() != 'MISSING').toList();
          final stockCount = BdDashboardMath.filterLines(basket.lines, BdHoldingsFilter.active).length;

          return Column(
            children: [
              if (!isMobile)
                BdPageHeader(
                  onBack: widget.embedded
                      ? () => BasketNavigation.returnToMyBaskets(
                            context,
                            userId: widget.userId,
                          )
                      : null,
                  onShare: () => _shareBasket(basket),
                  onDownload: () => _downloadCsv(basket),
                  onMore: () => _showMoreMenu(basket),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      isMobile ? AppSpacing.sm : 16,
                      16,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BdIdentityCard(
                          basket: basket,
                          stockCount: stockCount,
                          onMore: isMobile
                              ? () => _showMoreMenu(basket)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        BdKpiRow(basket: basket),
                        const SizedBox(height: 20),
                        BdHoldingsSection(
                          lines: basket.lines,
                          totalCurrentValue: basket.totalCurrentValue,
                          filter: _filter,
                          onFilterChanged: (f) => setState(() => _filter = f),
                          onViewAllocation: () => BdAllocationSheet.show(
                            context,
                            lines: activeLines,
                            totalCurrentValue: basket.totalCurrentValue,
                          ),
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        // Space so last table rows aren't hidden behind sticky footer
                        SizedBox(height: isMobile ? 88 : 72),
                      ],
                    ),
                  ),
                ),
              ),
              BdFooterBar(basket: basket, lastFetchedAt: _lastFetchedAt),
            ],
          );
        },
        loading: () => Column(
          children: [
            if (!isMobile) const BdPageHeader(),
            Expanded(child: _DashboardSkeleton(isMobile: isMobile)),
          ],
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.statusError),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load dashboard'),
              TextButton(onPressed: _refresh, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  final bool isMobile;

  const _DashboardSkeleton({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(height: 80, decoration: BoxDecoration(color: context.colors.border.withValues(alpha: 0.3), borderRadius: AppRadii.card)),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            crossAxisCount: isMobile ? 2 : 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.5,
            children: List.generate(isMobile ? 4 : 5, (_) =>
              Container(decoration: BoxDecoration(color: context.colors.border.withValues(alpha: 0.3), borderRadius: AppRadii.card)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(5, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(color: context.colors.border.withValues(alpha: 0.2), borderRadius: AppRadii.card),
                ),
              )),
        ],
      ),
    );
  }
}
