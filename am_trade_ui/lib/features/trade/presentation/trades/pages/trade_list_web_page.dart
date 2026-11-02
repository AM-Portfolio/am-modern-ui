import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_news_ui/am_news_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../journal_providers.dart';
import '../../../providers/trade_internal_providers.dart';
import '../../journal/utils/journal_this_trade.dart';
import '../../models/trade_holding_view_model.dart';
import 'trade_detail_view_page.dart';

import '../widgets/mobile_trade_list_view.dart';

/// Web page for displaying all trades in a list view
class TradeListWebPage extends ConsumerStatefulWidget {
  const TradeListWebPage({
    required this.portfolioId,
    this.initialTradeId,
    this.onNavigateToChart,
    super.key,
  });

  final String portfolioId;
  final String? initialTradeId;
  final Function(String symbol)? onNavigateToChart;

  @override
  ConsumerState<TradeListWebPage> createState() => _TradeListWebPageState();
}

class _TradeListWebPageState extends ConsumerState<TradeListWebPage> {
  TradeHoldingViewModel? _selectedTrade;
  bool _isListVisible = true;
  bool _hasInitializedSelection = false;
  String? _journalingTradeId;
  String _sidebarSearchQuery = '';

  @override
  void didUpdateWidget(TradeListWebPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTradeId != null &&
        widget.initialTradeId != oldWidget.initialTradeId) {
      final holdingsAsync =
          ref.read(tradeHoldingsStreamProvider(widget.portfolioId));
      holdingsAsync.whenData((tradeHoldings) {
        final match = tradeHoldings.holdings
            .cast<TradeHoldingViewModel?>()
            .firstWhere(
              (h) => h?.tradeId == widget.initialTradeId,
              orElse: () => null,
            );
        if (match != null && mounted) {
          setState(() {
            _selectedTrade = match;
          });
        }
      });
    }
  }

  Future<void> _journalThis(TradeHoldingViewModel holding) async {
    if (_journalingTradeId != null) return;
    setState(() => _journalingTradeId = holding.tradeId);
    try {
      final cubit = await ref.read(journalCubitProvider.future);
      if (!mounted) return;
      await openJournalThisTrade(
        context,
        cubit: cubit,
        tradeId: holding.tradeId,
        portfolioId: widget.portfolioId,
        holding: holding,
      );
    } finally {
      if (mounted) setState(() => _journalingTradeId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolioId = widget.portfolioId;
    final holdingsAsync = ref.watch(tradeHoldingsStreamProvider(portfolioId));

    return Scaffold(
      body: holdingsAsync.when(
        data: (tradeHoldings) {
          final holdings = tradeHoldings.holdings;

          if (holdings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No Trades Found', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Add your first trade to get started', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).scale();
          }

          // Auto-select initial trade or the first trade on initial load
          if (!_hasInitializedSelection && holdings.isNotEmpty) {
            _hasInitializedSelection = true;
            final initialTrade = widget.initialTradeId != null
                ? holdings.firstWhere(
                    (h) => h.tradeId == widget.initialTradeId,
                    orElse: () => holdings.first,
                  )
                : holdings.first;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedTrade = initialTrade;
                });
              }
            });
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800; // Mobile breakpoint at 800px

              if (isMobile) {
                return MobileTradeListView(
                  holdings: holdings,
                  onSelectTrade: (selected) {
                    setState(() {
                      _selectedTrade = selected;
                    });
                  },
                  onJournalThis: _journalThis,
                );
              }

              return Row(
                children: [
                  // Left sidebar - Trade list
                  _buildTradeSidebar(holdings),

                  // Right side - Trade detail or placeholder
                  Expanded(
                    child: _selectedTrade != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildTradeDetailView()),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(
                                      AppSpacing.md,
                                      0,
                                      AppSpacing.md,
                                      AppSpacing.sm + AppSpacing.xs,
                                    ),
                                child: SymbolNewsSection(
                                  symbol: _selectedTrade!.symbol,
                                  surface: NewsUiSurface.tradeTrades,
                                ),
                              ),
                            ],
                          )
                        : _buildEmptyState(),
                  ),
                ],
              );
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: ModuleColors.trade),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: context.statusError),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Error loading trades',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.colors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                text: 'Retry',
                icon: Icons.refresh,
                onPressed: () {
                  ref.invalidate(tradeHoldingsStreamProvider(portfolioId));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TradeHoldingViewModel> _filterSidebarHoldings(
    List<TradeHoldingViewModel> holdings,
  ) {
    final q = _sidebarSearchQuery.trim().toLowerCase();
    if (q.isEmpty) return holdings;
    return holdings.where((h) {
      return h.displaySymbol.toLowerCase().contains(q) ||
          h.displayCompanyName.toLowerCase().contains(q) ||
          h.symbol.toLowerCase().contains(q);
    }).toList();
  }

  // Trade sidebar - expanded or collapsed
  Widget _buildTradeSidebar(List<TradeHoldingViewModel> holdings) {
    // If trade is selected and list is not visible, show only expand icon
    if (_selectedTrade != null && !_isListVisible) {
      return Container(
        width: 56,
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(right: BorderSide(color: context.colors.divider)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            IconButton(
              icon: Icon(Icons.menu, color: ModuleColors.trade),
              onPressed: () {
                setState(() {
                  _isListVisible = true;
                });
              },
              tooltip: 'Show trade list',
            ),
            const SizedBox(height: AppSpacing.sm),
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                'All Trades (${holdings.length})',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ModuleColors.trade,
                    ),
              ),
            ),
          ],
        ),
      ).animate().slideX(begin: -0.2, end: 0, duration: 300.ms);
    }

    // Full sidebar with trade list
    final colors = context.colors;
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.divider)),
        boxShadow: [
          BoxShadow(
            color: context.shadow(0.05),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: ModuleColors.trade.withValues(alpha: 0.08),
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: ModuleColors.trade),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Trades',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                      ),
                      Text(
                        '${holdings.length} trades',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (_selectedTrade != null)
                  IconButton(
                    icon: Icon(Icons.close, color: context.textSecondary),
                    onPressed: () {
                      setState(() {
                        _isListVisible = false;
                      });
                    },
                    tooltip: 'Hide trade list',
                  ),
              ],
            ),
          ),

          // Search within All Trades
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SizedBox(
              height: 36,
              child: TextField(
                onChanged: (value) => setState(() => _sidebarSearchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search symbol or company...',
                  hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textSecondary,
                      ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 16,
                    color: context.textSecondary,
                  ),
                  suffixIcon: _sidebarSearchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: Icon(
                            Icons.clear,
                            size: 16,
                            color: context.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _sidebarSearchQuery = ''),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: AppSpacing.md,
                  ),
                  filled: true,
                  fillColor: context.colors.border.withValues(alpha: 0.12),
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.button,
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadii.button,
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadii.button,
                    borderSide: BorderSide(
                      color: ModuleColors.trade,
                      width: 1.5,
                    ),
                  ),
                  isDense: true,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: AppTypeScale.md,
                    ),
              ),
            ),
          ),

          // Trade list
          Expanded(
            child: Builder(
              builder: (context) {
                final filtered = _filterSidebarHoldings(holdings);
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        _sidebarSearchQuery.trim().isEmpty
                            ? 'No trades'
                            : 'No trades match your search',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final holding = filtered[index];
                    final isSelected =
                        _selectedTrade?.tradeId == holding.tradeId;

                    return _buildTradeSidebarItem(holding, isSelected)
                        .animate()
                        .fadeIn(delay: (30 * index).ms)
                        .slideX(begin: -0.1, end: 0);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: -0.1, end: 0, duration: 300.ms);
  }

  Widget _buildTradeSidebarItem(TradeHoldingViewModel holding, bool isSelected) {
    final isProfit = holding.isProfit;
    final statusColor = _getStatusColor(holding.status);
    final colors = context.colors;
    final muted = context.textSecondary;
    final pnlColor =
        isProfit ? context.marketPositive : context.marketNegative;
    final accent = ModuleColors.trade;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? accent.withValues(alpha: 0.12)
            : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isSelected ? accent : Colors.transparent,
            width: 4,
          ),
          bottom: BorderSide(color: colors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTrade = holding;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: AppRadii.button,
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(holding.status),
                            size: 12,
                            color: statusColor,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            holding.displaySymbol,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontSize: AppTypeScale.sm,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        holding.displayStatus.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: AppTypeScale.xs - 1,
                              fontWeight: FontWeight.bold,
                              color: statusColor.withValues(alpha: 0.75),
                            ),
                      ),
                    ),
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: _journalingTradeId == holding.tradeId
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accent,
                                ),
                              )
                            : Icon(
                                Icons.menu_book_outlined,
                                size: 16,
                                color: muted,
                              ),
                        tooltip: 'Journal this',
                        color: muted,
                        onPressed: _journalingTradeId != null
                            ? null
                            : () => _journalThis(holding),
                      ),
                    ),
                    if (widget.onNavigateToChart != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.show_chart,
                            size: 16,
                            color: muted,
                          ),
                          tooltip: 'View Chart',
                          color: muted,
                          onPressed: () => widget
                              .onNavigateToChart!(holding.displaySymbol),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  holding.displayCompanyName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Qty: ${holding.displayQuantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up : Icons.trending_down,
                      color: pnlColor,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      holding.displayProfitLossPercentage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: pnlColor,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      holding.displayProfitLoss,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontSize: AppTypeScale.sm,
                            fontWeight: FontWeight.w600,
                            color: pnlColor,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.touch_app,
          size: 64,
          color: ModuleColors.trade.withValues(alpha: 0.5),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Select a Trade',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Choose a trade from the sidebar to view details',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textSecondary,
              ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 600.ms);

  Widget _buildTradeDetailView() {
    if (_selectedTrade == null) return const SizedBox();

    return TradeDetailViewPage(
      key: ValueKey(_selectedTrade!.tradeId),
      trade: _selectedTrade!,
      portfolioId: widget.portfolioId,
      onNavigateToChart: widget.onNavigateToChart,
      onClose: () {
        setState(() {
          _selectedTrade = null;
        });
      },
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toUpperCase()) {
      case 'WIN':
        return Icons.check_circle;
      case 'LOSS':
        return Icons.cancel;
      case 'BREAK_EVEN':
        return Icons.remove_circle;
      case 'OPEN':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'WIN':
        return context.marketPositive;
      case 'LOSS':
        return context.marketNegative;
      case 'BREAK_EVEN':
        return context.statusWarning;
      case 'OPEN':
      case 'ACTIVE':
        return ModuleColors.trade;
      default:
        return context.statusNeutral;
    }
  }
}
