import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';

import '../../domain/models/basket_opportunity.dart';
import '../widgets/minimum_investment_warning_widget.dart';
import '../../../portfolio/providers/portfolio_providers.dart';
import '../../../portfolio/internal/domain/entities/portfolio_holding.dart';
import '../providers/basket_providers.dart';
import 'basket_success_page.dart';
import '../widgets/substitute_selector.dart';
import '../basket_navigation.dart';

// ---------------------------------------------------------------------------
// PAGE WIDGET
// ---------------------------------------------------------------------------
class ManualBasketCreatorPage extends ConsumerStatefulWidget {
  final BasketOpportunity opportunity;
  final String userId;
  final String portfolioId;
  final bool embedded;

  const ManualBasketCreatorPage({
    super.key,
    required this.opportunity,
    required this.userId,
    required this.portfolioId,
    this.embedded = false,
  });

  @override
  ConsumerState<ManualBasketCreatorPage> createState() =>
      _ManualBasketCreatorPageState();
}

class _ManualBasketCreatorPageState
    extends ConsumerState<ManualBasketCreatorPage>
    with SingleTickerProviderStateMixin {
  // --- Core state ---
  late BasketOpportunity _currentOpportunity;
  late List<BasketItem> _items;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _basketNameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _excludedItems = {};
  late TabController _tabController;

  // --- UI state ---
  bool _isCalculating = false;
  bool _hasCalculated = false;
  bool _isCustomAmount = false;
  bool _hasStaleData = false;
  bool _showSummaryDrawer = false; // tablet side panel
  bool _isSidebarCollapsed = false;
  DateTime? _lastCalculatedAt;
  Timer? _debounceTimer;
  double? _actualCost;
  double? _budgetVariance;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _currentOpportunity = widget.opportunity;
    _items = List.from(_currentOpportunity.composition);
    _basketNameController.text = 'My ${_currentOpportunity.etfName} Basket';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _amountController.dispose();
    _basketNameController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data helpers
  // ---------------------------------------------------------------------------
  List<BasketItem> _enrichItemsWithHoldings(
      List<BasketItem> items, PortfolioHoldings? localHoldings) {
    if (localHoldings == null) return items;
    return items.map((item) {
      final holding = localHoldings.holdings
          .where((h) =>
              h.symbol.toLowerCase() == item.stockSymbol.toLowerCase())
          .firstOrNull;
      if (holding != null) {
        return item.copyWith(
          heldQuantity: holding.quantity,
          heldAveragePrice: holding.avgPrice,
        );
      }
      return item;
    }).cast<BasketItem>().toList();
  }

  List<BasketItem> _getTabItems(int tabIndex, List<BasketItem> all) {
    switch (tabIndex) {
      case 0:
        return all;
      case 1:
        return all
            .where((i) =>
                i.status == ItemStatus.held ||
                (i.heldQuantity ?? 0) > 0)
            .toList();
      case 2:
        return all.where((i) => i.status == ItemStatus.substitute).toList();
      case 3:
        return all
            .where((i) =>
                i.status == ItemStatus.missing &&
                !_excludedItems.contains(i.stockSymbol))
            .toList();
      case 4:
        return all
            .where((i) => _excludedItems.contains(i.stockSymbol))
            .toList();
      default:
        return all;
    }
  }

  String _formatPreset(int amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(0)}L';
    return '₹${(amount / 1000).toStringAsFixed(0)}K';
  }

  String _investedText(BasketItem item) {
    if (item.lastPrice == null) return '—';
    // For held items with no additional buy needed, show current holding value
    if ((item.buyQuantity == null || item.buyQuantity == 0) &&
        item.heldQuantity != null && item.heldQuantity! > 0) {
      return '₹${(item.heldQuantity! * item.lastPrice!).toStringAsFixed(0)}';
    }
    if (item.buyQuantity == null || item.buyQuantity == 0) return '—';
    return '₹${(item.lastPrice! * item.buyQuantity!).toStringAsFixed(0)}';
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------
  void _updateQuantity(int index, double newQuantity) {
    setState(() {
      _items[index] = _items[index].copyWith(buyQuantity: newQuantity);
      _hasCalculated = false;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _excludedItems.add(_items[index].stockSymbol);
      _hasCalculated = false;
    });
    _calculateQuantities();
  }

  void _addItem(int index) {
    setState(() {
      _excludedItems.remove(_items[index].stockSymbol);
      _hasCalculated = false;
    });
    _calculateQuantities();
  }

  void _resetBasket() {
    setState(() {
      _excludedItems.clear();
      _items = List.from(widget.opportunity.composition);
      _hasCalculated = false;
    });
  }



  void _setFixedAmount(int amountRs) {
    setState(() {
      _amountController.text = amountRs.toString();
      _isCustomAmount = false;
      _hasCalculated = false;
    });
    _calculateQuantities();
  }

  void _calculateQuantities() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      if (_amountController.text.isEmpty) return;
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) return;

      setState(() {
        _isCalculating = true;
        _hasStaleData = false;
      });

      try {
        final holdingsAsync = ref.read(portfolioHoldingsProvider(widget.portfolioId!));
        final localHoldings = holdingsAsync.asData?.value;
        final itemsToSend = _enrichItemsWithHoldings(_items, localHoldings);

        final updatedOpportunity =
            await ref.read(calculateBasketQuantitiesProvider(
          request: {
            'investmentAmount': amount,
            'opportunity':
                _currentOpportunity.copyWith(composition: itemsToSend).toJson(),
            'includeHeld': true,
            'excludedSymbols': _excludedItems.toList(),
          },
        ).future);

        if (!mounted) return;
        setState(() {
          _currentOpportunity = updatedOpportunity;
          _items = updatedOpportunity.composition.map((item) {
            if (_excludedItems.contains(item.stockSymbol)) {
              return item.copyWith(clearBuyQuantity: true);
            }
            return item;
          }).toList();
          _hasCalculated = true;
          _lastCalculatedAt = DateTime.now();
          _actualCost = updatedOpportunity.actualInvestmentCost;
          _budgetVariance = updatedOpportunity.budgetVariance;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _hasStaleData = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating quantities: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isCalculating = false);
        }
      }
    });
  }

  void _openSubstituteSelectorFor(int originalIdx) {
    final item = _items[originalIdx];
    final targetQty = item.targetQuantity ?? 0;
    final heldQty = item.heldQuantity ?? 0;
    final gapQty = (targetQty - heldQty).clamp(0, double.infinity);
    final targetVal = gapQty * (item.lastPrice ?? 0);
    // Needed weight is etfWeight - replicaWeight (if partially filled) or just etfWeight.
    // Wait, if it's MISSING, replicaWeight is 0. If it's a split substitute, we might want to fill the remaining.
    // For simplicity, we just pass the remaining etfWeight for the item.
    final neededWeight = item.etfWeight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SubstituteSelector(
        originalSymbol: item.stockSymbol,
        originalIsin: item.isin,
        requiredMarketCap: item.marketCapCategory ?? '',
        alternatives: item.alternatives,
        neededWeight: neededWeight,
        neededQty: gapQty.toInt(),
        neededValue: targetVal.toDouble(),
        onMultiSelected: (selections) async {
          Navigator.of(ctx).pop();
          setState(() {
            _isCalculating = true;
          });
          try {
            final assignments = selections.map((s) => {
              'missingIsin': item.isin ?? item.stockSymbol,
              'substituteIsin': s.isin,
              if (s.assignedWeight != null) 'assignedWeight': s.assignedWeight,
            }).toList();

            final updated = await ref.read(applySubstitutesProvider(request: {
              'portfolioId': widget.portfolioId,
              'etfIsin': _currentOpportunity.etfIsin,
              'currentOpportunity': _currentOpportunity.toJson(),
              'assignments': assignments,
            }).future);

            if (!mounted) return;
            setState(() {
              _currentOpportunity = updated;
              _items = updated.composition.map((compItem) {
                if (_excludedItems.contains(compItem.stockSymbol)) {
                  return compItem.copyWith(clearBuyQuantity: true);
                }
                return compItem;
              }).toList();
              _hasCalculated = false;
            });
            _calculateQuantities();
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _isCalculating = false;
              _hasStaleData = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to apply substitutes: $e')),
            );
          }
        },
      ),
    );
  }

  void _openSubstituteSelector() {
    final missingIdx = _items.indexWhere((i) =>
        i.status == ItemStatus.missing &&
        !_excludedItems.contains(i.stockSymbol));
    if (missingIdx == -1) return;
    _openSubstituteSelectorFor(missingIdx);
  }

  void _goToFinalPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter an investment amount first'),
        backgroundColor: context.statusWarning,
      ));
      return;
    }
    if (!_hasCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please click Recalculate before saving.'),
        backgroundColor: context.statusWarning,
      ));
      return;
    }
    final minInvestment = widget.opportunity.minimumInvestmentAmount ?? 50000.0;
    if (amount < minInvestment) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Minimum investment is ₹${minInvestment.toStringAsFixed(0)}'),
        backgroundColor: context.statusWarning,
      ));
      return;
    }

    final basketName = _basketNameController.text.trim();

    BasketNavigation.openFinalPreview(
      context,
      args: BasketFinalPreviewArgs(
        originalOpportunity: widget.opportunity,
        finalOpportunity: _currentOpportunity,
        finalItems: List.unmodifiable(_items),
        investmentAmount: amount,
        basketName: basketName,
        userId: widget.userId,
        portfolioId: widget.portfolioId,
        excludedItems: _excludedItems,
        idempotencyKey: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < AmBreakpoints.mobile; // < 600
    final isDesktop = screenWidth >= AmBreakpoints.tablet; // >= 1100

    final portfolioHoldingsAsync =
        ref.watch(portfolioHoldingsProvider(widget.portfolioId!));
    final localHoldings = portfolioHoldingsAsync.asData?.value;
    final displayItems = _enrichItemsWithHoldings(_items, localHoldings);

    // --- Computed stats ---
    final heldCount = displayItems
        .where((i) =>
            i.status == ItemStatus.held || (i.heldQuantity ?? 0) > 0)
        .length;
    final subCount =
        displayItems.where((i) => i.status == ItemStatus.substitute).length;
    final missingCount = displayItems
        .where((i) =>
            i.status == ItemStatus.missing &&
            !_excludedItems.contains(i.stockSymbol))
        .length;
    final excludedCount = _excludedItems.length;

    final heldWeight = displayItems
        .where((i) => i.status == ItemStatus.held)
        .fold(0.0, (s, i) => s + (i.rebalancedWeight ?? i.etfWeight));
    final subWeight = displayItems
        .where((i) => i.status == ItemStatus.substitute)
        .fold(0.0, (s, i) => s + (i.rebalancedWeight ?? i.etfWeight));
    final missingWeight = displayItems
        .where((i) => i.status == ItemStatus.missing)
        .fold(0.0, (s, i) => s + (i.rebalancedWeight ?? i.etfWeight));
    final coverage = _hasCalculated
        ? _currentOpportunity.replicaScore
        : (heldWeight + subWeight);

    // tab-filtered items
    final tabItems = _getTabItems(_tabController.index, displayItems);

    final body = isDesktop
        ? _buildDesktopLayout(context, displayItems, tabItems, heldCount,
            subCount, missingCount, excludedCount, heldWeight, subWeight,
            missingWeight, coverage)
        : isMobile
            ? _buildMobileLayout(context, displayItems, tabItems, heldCount,
                subCount, missingCount, excludedCount, coverage)
            : _buildTabletLayout(context, displayItems, tabItems, heldCount,
                subCount, missingCount, excludedCount, heldWeight, subWeight,
                missingWeight, coverage);

    return widget.embedded
        ? body
        : Scaffold(backgroundColor: context.backgroundColor, body: body);
  }

  // ---------------------------------------------------------------------------
  // DESKTOP LAYOUT (>= 1100px)
  // ---------------------------------------------------------------------------
  Widget _buildDesktopLayout(
    BuildContext context,
    List<BasketItem> displayItems,
    List<BasketItem> tabItems,
    int heldCount,
    int subCount,
    int missingCount,
    int excludedCount,
    double heldWeight,
    double subWeight,
    double missingWeight,
    double coverage,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildDesktopHeader(context, theme),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left panel
              Expanded(
                flex: 3,
                child: _buildLeftPanel(context, theme, displayItems, tabItems,
                    heldCount, subCount, missingCount, excludedCount,
                    isMobile: false, isTablet: false),
              ),
              // Right sidebar
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isSidebarCollapsed ? 0 : 320,
                child: _isSidebarCollapsed
                    ? const SizedBox.shrink()
                    : _buildRightSidebar(
                        context,
                        theme,
                        displayItems,
                        heldCount,
                        subCount,
                        missingCount,
                        excludedCount,
                        heldWeight,
                        subWeight,
                        missingWeight,
                        coverage),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TABLET LAYOUT (600–1099px)
  // ---------------------------------------------------------------------------
  Widget _buildTabletLayout(
    BuildContext context,
    List<BasketItem> displayItems,
    List<BasketItem> tabItems,
    int heldCount,
    int subCount,
    int missingCount,
    int excludedCount,
    double heldWeight,
    double subWeight,
    double missingWeight,
    double coverage,
  ) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Column(
          children: [
            _buildTabletHeader(context, theme),
            Expanded(
              child: _buildLeftPanel(context, theme, displayItems, tabItems,
                  heldCount, subCount, missingCount, excludedCount,
                  isMobile: false, isTablet: true),
            ),
            _buildStickyBottomBar(context, theme, coverage),
          ],
        ),
        // Slide-out summary drawer
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          right: _showSummaryDrawer ? 0 : -340,
          top: 0,
          bottom: 0,
          width: 320,
          child: Material(
            elevation: 12,
            color: context.cardColor,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Summary', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _showSummaryDrawer = false)),
                    ]),
                    const SizedBox(height: 12),
                    _AllocationSummaryCard(
                      heldFraction: heldWeight / 100.0,
                      subFraction: subWeight / 100.0,
                      missingFraction: missingWeight / 100.0,
                      heldCount: heldCount,
                      subCount: subCount,
                      missingCount: missingCount,
                      excludedCount: _excludedItems.length,
                      heldColor: context.statusSuccess,
                      subColor: context.colors.actionPrimaryBg,
                      missingColor: context.statusError,
                      bgColor: context.dividerColor,
                      coverage: coverage,
                    ),
                    const SizedBox(height: 12),
                    _buildInvestmentSummaryCard(context, theme, coverage),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _goToFinalPreview,
                        style: FilledButton.styleFrom(
                          backgroundColor: context.colors.actionPrimaryBg,
                          foregroundColor: context.colors.actionPrimaryFg,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Review & Confirm',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildWhatYouHaveNeed(context, theme, displayItems),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE LAYOUT (< 600px)
  // ---------------------------------------------------------------------------
  Widget _buildMobileLayout(
    BuildContext context,
    List<BasketItem> displayItems,
    List<BasketItem> tabItems,
    int heldCount,
    int subCount,
    int missingCount,
    int excludedCount,
    double coverage,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildMobileHeader(context, theme, displayItems, heldCount, subCount,
            missingCount, excludedCount, coverage),
        Expanded(
          child: _buildLeftPanel(context, theme, displayItems, tabItems,
              heldCount, subCount, missingCount, excludedCount,
              isMobile: true, isTablet: false),
        ),
        _buildStickyBottomBar(context, theme, coverage),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HEADERS
  // ---------------------------------------------------------------------------
  Widget _buildDesktopHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(children: [
        TextButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back'),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Icon(Icons.auto_awesome, color: context.colors.actionPrimaryBg),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Text('Customize Basket', style: theme.textTheme.titleMedium),
                if (_hasCalculated && _lastCalculatedAt != null) ...[
                  const SizedBox(width: 8),
                  Text('• Prices as of ${DateFormat('hh:mm a').format(_lastCalculatedAt!)}',
                      style: TextStyle(fontSize: 11, color: context.textTertiary)),
                ],
              ],
            ),
            Text(widget.opportunity.etfName,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: context.textSecondary)),
          ]),
        ),
        if (widget.opportunity.remainingPortfolioValue != null) ...[
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Available',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: context.textSecondary)),
            Text(
                '₹${widget.opportunity.remainingPortfolioValue!.toStringAsFixed(0)}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(width: 16),
        ],
        IconButton(
          icon: Icon(_isSidebarCollapsed ? Icons.keyboard_double_arrow_left : Icons.keyboard_double_arrow_right),
          tooltip: _isSidebarCollapsed ? 'Show Summary' : 'Hide Summary',
          onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _isCalculating ? null : _calculateQuantities,
          icon: _isCalculating
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh, size: 16),
          label: const Text('Recalculate'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _goToFinalPreview,
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Review & Confirm'),
          style: FilledButton.styleFrom(
              backgroundColor: context.colors.actionPrimaryBg,
              foregroundColor: context.colors.actionPrimaryFg),
        ),
      ]),
    );
  }

  Widget _buildTabletHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(children: [
        IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop()),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Customize Basket', style: theme.textTheme.titleMedium),
            Text(widget.opportunity.etfName,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: context.textSecondary),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        IconButton(
          icon: Icon(Icons.assessment_outlined,
              color: context.colors.actionPrimaryBg),
          onPressed: () => setState(() => _showSummaryDrawer = !_showSummaryDrawer),
          tooltip: 'Portfolio Summary',
        ),
        OutlinedButton.icon(
          onPressed: _isCalculating ? null : _calculateQuantities,
          icon: _isCalculating
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh, size: 14),
          label: const Text('Recalc'),
        ),
      ]),
    );
  }

  Widget _buildMobileHeader(
    BuildContext context,
    ThemeData theme,
    List<BasketItem> displayItems,
    int heldCount,
    int subCount,
    int missingCount,
    int excludedCount,
    double coverage,
  ) {
    return Container(
      color: context.cardColor,
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop()),
          Expanded(
            child: Text('Customize Basket',
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis),
          ),
          if (_isCalculating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMobileOptionsMenu(
                context, displayItems, heldCount, subCount, missingCount,
                excludedCount, coverage),
          ),
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LEFT PANEL (shared, responsive)
  // ---------------------------------------------------------------------------
  Widget _buildLeftPanel(
    BuildContext context,
    ThemeData theme,
    List<BasketItem> displayItems,
    List<BasketItem> tabItems,
    int heldCount,
    int subCount,
    int missingCount,
    int excludedCount, {
    required bool isMobile,
    required bool isTablet,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Investment controls
              _buildInvestmentControls(context, theme, isMobile: isMobile),
              // Stale data banner
              if (_hasStaleData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: context.statusWarning.withValues(alpha: 0.12),
                  child: Row(children: [
                    Icon(Icons.warning_amber_rounded,
                        color: context.statusWarning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('Calculation failed. Showing previous data.',
                            style: TextStyle(
                                color: context.statusWarning, fontSize: 12))),
                    TextButton(
                      onPressed: () {
                        setState(() => _hasStaleData = false);
                        _calculateQuantities();
                      },
                      child: const Text('Retry'),
                    ),
                  ]),
                ),

              // Tab bar
              Container(
                color: context.cardColor,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: context.textPrimary,
                  unselectedLabelColor: context.textSecondary,
                  indicatorColor: context.colors.actionPrimaryBg,
                  dividerColor: context.borderColor,
                  tabs: [
                    Tab(text: 'All (${displayItems.length})'),
                    Tab(text: 'Held ($heldCount)'),
                    Tab(text: 'Subst. ($subCount)'),
                    Tab(text: 'Missing ($missingCount)'),
                    Tab(text: 'Excl. ($excludedCount)'),
                  ],
                ),
              ),
              // Table header (desktop only)
              if (!isMobile && !isTablet)
                _buildDesktopTableHeader(context, theme),
            ],
          ),
        ),
        // Constituent list
        _buildConstituentList(context, theme, tabItems, displayItems,
            isMobile: isMobile, isTablet: isTablet),
        // Bottom info bar
        SliverToBoxAdapter(
          child: _buildBottomInfoBar(context, theme),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // INVESTMENT CONTROLS
  // ---------------------------------------------------------------------------
  Widget _buildInvestmentControls(BuildContext context, ThemeData theme,
      {required bool isMobile}) {
    final presets = [25000, 50000, 100000, 200000, 500000];
    final chips = <Widget>[
      for (final preset in presets)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _PresetChip(
            label: _formatPreset(preset),
            isActive: !_isCustomAmount &&
                _amountController.text == preset.toString(),
            onTap: () => _setFixedAmount(preset),
          ),
        ),
      _PresetChip(
        label: 'Custom',
        isActive: _isCustomAmount,
        onTap: () => setState(() => _isCustomAmount = true),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      color: context.cardColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Investment Amount', style: theme.textTheme.labelMedium),
          const SizedBox(width: 4),
          Icon(Icons.info_outline, size: 14, color: context.textTertiary),
        ]),
        const SizedBox(height: 8),
        // Amount input row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: AppRadii.button,
          ),
          child: Row(children: [
            Text('₹',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: context.textSecondary)),
            const SizedBox(width: 8),
            Expanded(
              child: _isCustomAmount
                  ? TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration.collapsed(hintText: '0'),
                      onChanged: (v) => setState(() => _hasCalculated = false),
                      onSubmitted: (_) => _calculateQuantities(),
                    )
                  : Text(
                      _amountController.text.isEmpty
                          ? '0'
                          : _amountController.text,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isCustomAmount = true),
              child: Icon(Icons.edit, size: 16, color: context.textSecondary),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        // Chips
        if (isMobile)
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: chips))
        else
          Wrap(spacing: 6, runSpacing: 6, children: chips),
        const SizedBox(height: 8),
        if (_actualCost != null && _budgetVariance != null)
          _ActualCostBanner(
            actualCost: _actualCost!,
            variance: _budgetVariance!,
            investmentAmount: double.tryParse(_amountController.text) ?? 0.0,
            residualCash: _currentOpportunity.residualCash,
            heldCoverage: _currentOpportunity.heldCoverageValue ?? _items
                .where((i) =>
                    (i.status == ItemStatus.held ||
                        i.status == ItemStatus.substitute) &&
                    i.heldQuantity != null &&
                    i.lastPrice != null &&
                    i.targetQuantity != null)
                .fold(0.0, (s, i) => s + (math.min(i.heldQuantity!, i.targetQuantity!) * i.lastPrice!)),
            formatCurrency: (val) => '₹${val.toStringAsFixed(0)}',
          ),
        MinimumInvestmentWarningWidget(
          minimumInvestmentAmount:
              widget.opportunity.minimumInvestmentAmount ?? 50000.0,
          currentInvestmentAmount:
              double.tryParse(_amountController.text) ?? 0.0,
        ),
      ]),
    );
  }

  // ---------------------------------------------------------------------------
  // STATS STRIP
  // ---------------------------------------------------------------------------
  Widget _buildStatsStrip(
    BuildContext context,
    ThemeData theme,
    int totalCount,
    int heldCount,
    int subCount,
    int missingCount,
    int excludedCount, {
    required bool isMobile,
  }) {
    final pills = <Widget>[
      _StatPill(
          label: 'Total', value: totalCount, color: context.textPrimary),
      const SizedBox(width: 8),
      _StatPill(
          label: 'Held', value: heldCount, color: context.statusSuccess),
      const SizedBox(width: 8),
      _StatPill(
          label: 'Sub.',
          value: subCount,
          color: context.colors.actionPrimaryBg),
      const SizedBox(width: 8),
      _StatPill(
          label: 'Missing', value: missingCount, color: context.statusError),
      const SizedBox(width: 8),
      _StatPill(
          label: 'Excl.', value: excludedCount, color: context.textTertiary),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: context.backgroundColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: pills),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP TABLE HEADER
  // ---------------------------------------------------------------------------
  Widget _buildDesktopTableHeader(BuildContext context, ThemeData theme) {
    Widget cell(String label, int flex,
            {TextAlign align = TextAlign.left}) =>
        Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: context.textSecondary,
                  fontWeight: FontWeight.bold),
              textAlign: align,
            ),
          ),
        );

    return Container(
      height: 48,
      color: context.backgroundColor,
      child: Row(children: [
        cell('Asset', 22),
        cell('ETF Weight', 10),
        cell('Current Holding\n(Units | Value)', 16),
        cell('Needed to Match\n(Units | Value)', 16),
        cell('Gap\n(Units)', 8, align: TextAlign.center),
        cell('Investment\nAmount', 13, align: TextAlign.right),
        cell('Action', 9, align: TextAlign.center),
      ]),
    );
  }

  // ---------------------------------------------------------------------------
  // CONSTITUENT LIST
  // ---------------------------------------------------------------------------
  Widget _buildConstituentList(
    BuildContext context,
    ThemeData theme,
    List<BasketItem> tabItems,
    List<BasketItem> displayItems, {
    required bool isMobile,
    required bool isTablet,
  }) {
    // Build grouped items (group headers + rows)
    final directItems = tabItems
        .where((i) =>
            i.status == ItemStatus.held ||
            (i.buyQuantity != null &&
                i.status != ItemStatus.substitute &&
                i.status != ItemStatus.missing))
        .toList();
    final subItems =
        tabItems.where((i) => i.status == ItemStatus.substitute).toList();
    final missingItems = tabItems
        .where((i) =>
            i.status == ItemStatus.missing &&
            !_excludedItems.contains(i.stockSymbol))
        .toList();
    final excludedItems = tabItems
        .where((i) => _excludedItems.contains(i.stockSymbol))
        .toList();

    List<Widget> rows = [];

    void addGroup(String label, Color color, List<BasketItem> items) {
      if (items.isEmpty) return;
      rows.add(_GroupHeaderRow(label: '$label (${items.length})', color: color));
      for (final item in items) {
        final originalIdx = displayItems.indexOf(item);
        if (originalIdx == -1) return;
        if (isMobile) {
          rows.add(_MobileBasketCard(
            item: item,
            investedText: _investedText(item),
            isExcluded: _excludedItems.contains(item.stockSymbol),
            onRemove: () => _removeItem(originalIdx),
            onAdd: () => _addItem(originalIdx),
            onSubstitute: () => _openSubstituteSelectorFor(originalIdx),
            onQtyChanged: (v) => _updateQuantity(originalIdx, v),
          ));
        } else if (isTablet) {
          rows.add(_TabletBasketRow(
            item: item,
            investedText: _investedText(item),
            isExcluded: _excludedItems.contains(item.stockSymbol),
            onRemove: () => _removeItem(originalIdx),
            onAdd: () => _addItem(originalIdx),
            onSubstitute: () => _openSubstituteSelectorFor(originalIdx),
            onQtyChanged: (v) => _updateQuantity(originalIdx, v),
          ));
        } else {
          rows.add(_DenseBasketRow(
            item: item,
            investedText: _investedText(item),
            investmentAmount: double.tryParse(_amountController.text) ?? 0.0,
            isExcluded: _excludedItems.contains(item.stockSymbol),
            originalIdx: originalIdx,
            onRemove: () => _removeItem(originalIdx),
            onAdd: () => _addItem(originalIdx),
            onSubstitute: () => _openSubstituteSelectorFor(originalIdx),
            onQtyChanged: (v) => _updateQuantity(originalIdx, v),
          ));
        }
      }
    }

    addGroup('Direct Match', context.statusSuccess, directItems);
    addGroup('Substituted', context.colors.actionPrimaryBg, subItems);
    addGroup('Missing / Swap', context.statusError, missingItems);
    addGroup('Excluded', context.textTertiary, excludedItems);

    // Total row (desktop only)
    if (!isMobile && !isTablet) {
      rows.add(_buildDesktopTotalRow(context, theme));
    }

    return SliverPadding(
      padding: EdgeInsets.only(
        bottom: isMobile ? 80 : 16,
        left: isMobile ? 8 : 0,
        right: isMobile ? 8 : 0,
        top: 4,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => rows[index],
          childCount: rows.length,
        ),
      ),
    );
  }

  Widget _buildDesktopTotalRow(BuildContext context, ThemeData theme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: context.borderColor, width: 1.5)),
        color: context.cardColor,
      ),
      child: Row(children: [
        Expanded(
            flex: 26,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('Total',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
        Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('100%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right),
            )),
        const Expanded(flex: 16, child: SizedBox()),
        const Expanded(flex: 12, child: SizedBox()),
        Expanded(
            flex: 14,
            child: Text('₹${_amountController.text}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right)),
        const Expanded(flex: 8, child: SizedBox()),
      ]),
    );
  }

  Widget _buildBottomInfoBar(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.cardColor,
      child: Row(children: [
        Icon(Icons.info_outline, size: 14, color: context.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'When you remove a constituent, its allocation is redistributed proportionally.',
            style:
                theme.textTheme.labelSmall?.copyWith(color: context.textTertiary),
          ),
        ),
      ]),
    );
  }

  // ---------------------------------------------------------------------------
  // RIGHT SIDEBAR (desktop)
  // ---------------------------------------------------------------------------
  Widget _buildRightSidebar(
    BuildContext context,
    ThemeData theme,
    List<BasketItem> displayItems,
    int heldCount,
    int subCount,
    int missingCount,
    int excludedCount,
    double heldWeight,
    double subWeight,
    double missingWeight,
    double coverage,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: context.borderColor)),
        color: context.cardColor,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _AllocationSummaryCard(
            heldFraction: heldWeight / 100.0,
            subFraction: subWeight / 100.0,
            missingFraction: missingWeight / 100.0,
            heldCount: heldCount,
            subCount: subCount,
            missingCount: missingCount,
            excludedCount: excludedCount,
            heldColor: context.statusSuccess,
            subColor: context.colors.actionPrimaryBg,
            missingColor: context.statusError,
            bgColor: context.dividerColor,
            coverage: coverage,
          ),
          const SizedBox(height: 12),
          _buildInvestmentSummaryCard(context, theme, coverage),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _goToFinalPreview,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Review & Confirm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.actionPrimaryBg,
              foregroundColor: context.colors.actionPrimaryFg,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This will create a new standalone portfolio.',
            style:
                theme.textTheme.labelSmall?.copyWith(color: context.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildWhatYouHaveNeed(context, theme, displayItems),
          const SizedBox(height: 8),
          _buildExpandableComparison(context, theme, displayItems),
        ]),
      ),
    );
  }

  Widget _buildInvestmentSummaryCard(
      BuildContext context, ThemeData theme, double coverage) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final available = widget.opportunity.remainingPortfolioValue ?? 0;
    final minRec = widget.opportunity.minimumInvestmentAmount ?? 50000.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Investment Summary',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _SummaryRow(
            label: 'Total Investment',
            value: '₹${amount.toStringAsFixed(0)}'),
        _SummaryRow(
            label: 'Available to Invest',
            value: '₹${available.toStringAsFixed(0)}'),
        _SummaryRow(
            label: 'Min. Recommended',
            value: '₹${minRec.toStringAsFixed(0)}'),
        _SummaryRow(
            label: 'Coverage After Creation',
            value: '${coverage.toStringAsFixed(0)}%'),
      ]),
    );
  }

  Widget _buildWhatYouHaveNeed(
      BuildContext context, ThemeData theme, List<BasketItem> displayItems) {
    final missingItems = displayItems
        .where((i) =>
            i.status == ItemStatus.missing &&
            !_excludedItems.contains(i.stockSymbol))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: ExpansionTile(
        title: Text('What You Have vs What You Need',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(children: [
              if (missingItems.isEmpty)
                Row(children: [
                  Icon(Icons.check_circle,
                      color: context.statusSuccess, size: 16),
                  const SizedBox(width: 6),
                  Text('All constituents covered!',
                      style: TextStyle(color: context.statusSuccess)),
                ])
              else ...[
                Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: context.statusError, size: 16),
                  const SizedBox(width: 6),
                  Text('${missingItems.length} constituent(s) not available',
                      style: TextStyle(color: context.statusError)),
                ]),
                const SizedBox(height: 8),
                for (final m in missingItems.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: context.statusError,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(m.stockSymbol,
                              style: theme.textTheme.bodySmall)),
                      Text('${m.etfWeight.toStringAsFixed(1)}%',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: context.textSecondary)),
                    ]),
                  ),
                if (missingItems.length > 3)
                  Text('+${missingItems.length - 3} more',
                      style: TextStyle(
                          color: context.textTertiary, fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openSubstituteSelector,
                    icon: Icon(Icons.swap_horiz,
                        size: 16, color: context.colors.actionPrimaryBg),
                    label: Text('Find Replacement',
                        style: TextStyle(
                            color: context.colors.actionPrimaryBg)),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableComparison(
      BuildContext context, ThemeData theme, List<BasketItem> displayItems) {
    return Column(children: [
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor)),
        child: ExpansionTile(
          title: Text('Comparison',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          children: [
            SizedBox(
              height: 300,
              child: _BasketComparisonTab(
                originalOpportunity: _currentOpportunity,
                myBasketItems: _items,
                hasCalculated: _hasCalculated,
                includeHeld: true,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor)),
        child: ExpansionTile(
          title: Text('Sector Analysis',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          children: [
            SizedBox(
              height: 300,
              child: _SectorComparisonTab(
                originalOpportunity: _currentOpportunity,
                myBasketItems: _items,
                hasCalculated: _hasCalculated,
                includeHeld: true,
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // STICKY BOTTOM BAR (mobile + tablet)
  // ---------------------------------------------------------------------------
  Widget _buildStickyBottomBar(
      BuildContext context, ThemeData theme, double coverage) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.borderColor)),
        boxShadow: [
          BoxShadow(
              color: context.textPrimary.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total Investment',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: context.textSecondary)),
            Text(
              '₹${_amountController.text.isEmpty ? "0" : _amountController.text}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text('${coverage.toStringAsFixed(0)}% coverage',
                style: TextStyle(
                    color: context.statusSuccess,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ]),
          FilledButton.icon(
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Review & Confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.actionPrimaryBg,
              foregroundColor: context.colors.actionPrimaryFg,
            ),
            onPressed: _goToFinalPreview,
          ),
        ]),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE OPTIONS MENU
  // ---------------------------------------------------------------------------
  void _showMobileOptionsMenu(
    BuildContext context,
    List<BasketItem> displayItems,
    int heldCount,
    int subCount,
    int missingCount,
    int excludedCount,
    double coverage,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2))),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Recalculate'),
          onTap: () {
            Navigator.of(ctx).pop();
            _calculateQuantities();
          },
        ),
        ListTile(
          leading: const Icon(Icons.restart_alt),
          title: const Text('Reset Basket'),
          onTap: () {
            Navigator.of(ctx).pop();
            _resetBasket();
          },
        ),

        ListTile(
          leading: Icon(Icons.assessment_outlined,
              color: context.colors.actionPrimaryBg),
          title: const Text('View Portfolio Summary'),
          onTap: () {
            Navigator.of(ctx).pop();
            _showMobileSummarySheet(context, displayItems, heldCount, subCount,
                missingCount, excludedCount, coverage);
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(Icons.save_alt, color: context.colors.actionPrimaryBg),
          title: const Text('Save Basket'),
          onTap: () {
            Navigator.of(ctx).pop();
            _goToFinalPreview();
          },
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ]),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE SUMMARY BOTTOM SHEET
  // ---------------------------------------------------------------------------
  void _showMobileSummarySheet(
    BuildContext context,
    List<BasketItem> displayItems,
    int heldCount,
    int subCount,
    int missingCount,
    int excludedCount,
    double coverage,
  ) {
    final heldWeight = displayItems
        .where((i) => i.status == ItemStatus.held)
        .fold(0.0, (s, i) => s + i.etfWeight);
    final subWeight = displayItems
        .where((i) => i.status == ItemStatus.substitute)
        .fold(0.0, (s, i) => s + i.etfWeight);
    final missingWeight = displayItems
        .where((i) => i.status == ItemStatus.missing)
        .fold(0.0, (s, i) => s + i.etfWeight);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollCtrl) => SingleChildScrollView(
            controller: scrollCtrl,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(children: [
                Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(2))),
                Text('Portfolio Summary', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                _AllocationSummaryCard(
                  heldFraction: heldWeight / 100.0,
                  subFraction: subWeight / 100.0,
                  missingFraction: missingWeight / 100.0,
                  heldCount: heldCount,
                  subCount: subCount,
                  missingCount: missingCount,
                  excludedCount: _excludedItems.length,
                  heldColor: context.statusSuccess,
                  subColor: context.colors.actionPrimaryBg,
                  missingColor: context.statusError,
                  bgColor: context.dividerColor,
                  coverage: coverage,
                ),
                const SizedBox(height: 12),
                _buildInvestmentSummaryCard(context, theme, coverage),
                const SizedBox(height: 12),
                _buildWhatYouHaveNeed(context, theme, displayItems),
                const SizedBox(height: 12),
                _buildExpandableComparison(context, theme, displayItems),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// SHARED PRIVATE WIDGETS
// ---------------------------------------------------------------------------

/// Preset amount chip
class _PresetChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? context.colors.actionPrimaryBg
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? context.colors.actionPrimaryBg
                : context.borderColor,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? context.colors.actionPrimaryFg
                : context.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Stats pill
class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text('$value $label',
            style:
                TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Status badge
class _StatusBadge extends StatelessWidget {
  final ItemStatus? status;
  final bool isExcluded;

  const _StatusBadge({this.status, this.isExcluded = false});

  @override
  Widget build(BuildContext context) {
    if (isExcluded) {
      return _pill('Excluded', context.textTertiary);
    }
    if (status == null) return const SizedBox.shrink();
    final (label, color) = switch (status!) {
      ItemStatus.held => ('Held', context.statusSuccess),
      ItemStatus.substitute => ('Subst.', context.colors.actionPrimaryBg),
      ItemStatus.missing => ('Missing', context.statusError),
      ItemStatus.excluded => ('Excluded', context.textTertiary),
    };
    return _pill(label, color);
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

/// Status dot (mobile)
class _StatusDot extends StatelessWidget {
  final ItemStatus? status;
  final bool isExcluded;

  const _StatusDot({this.status, this.isExcluded = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (isExcluded) {
      color = context.textTertiary;
    } else {
      color = switch (status) {
        ItemStatus.held => context.statusSuccess,
        ItemStatus.substitute => context.colors.actionPrimaryBg,
        ItemStatus.missing => context.statusError,
        _ => context.textTertiary,
      };
    }
    return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

/// Group header row
class _GroupHeaderRow extends StatelessWidget {
  final String label;
  final Color color;

  const _GroupHeaderRow({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: color.withValues(alpha: 0.06),
      child: Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color)),
      ]),
    );
  }
}

/// Summary row helper
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    color: context.textSecondary, fontSize: 13))),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// DENSE BASKET ROW — Desktop
// ---------------------------------------------------------------------------
class _DenseBasketRow extends StatefulWidget {
  final BasketItem item;
  final String investedText;
  final double investmentAmount;
  final bool isExcluded;
  final int originalIdx;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onSubstitute;
  final ValueChanged<double> onQtyChanged;

  const _DenseBasketRow({
    required this.item,
    required this.investedText,
    required this.investmentAmount,
    required this.isExcluded,
    required this.originalIdx,
    required this.onRemove,
    required this.onAdd,
    required this.onSubstitute,
    required this.onQtyChanged,
  });

  @override
  State<_DenseBasketRow> createState() => _DenseBasketRowState();
}

class _DenseBasketRowState extends State<_DenseBasketRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isMissing = item.status == ItemStatus.missing && !widget.isExcluded;

    final weight = item.rebalancedWeight ?? item.etfWeight;
    final targetAmount = (weight / 100.0) * widget.investmentAmount;
    final targetQty = item.targetQuantity ?? 0.0;
    final targetVal = targetQty > 0 ? (targetQty * (item.lastPrice ?? 0.0)) : targetAmount;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 44,
        color: _isHovered
            ? context.colors.actionPrimaryBg.withValues(alpha: 0.05)
            : Colors.transparent,
        child: Row(children: [
          // Asset
          Expanded(
            flex: 22,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (widget.isExcluded
                              ? context.textTertiary
                              : (item.status == ItemStatus.held
                                  ? context.statusSuccess
                                  : item.status == ItemStatus.substitute
                                      ? context.colors.actionPrimaryBg
                                      : isMissing
                                          ? context.statusError
                                          : context.colors.actionPrimaryBg))
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                        item.stockSymbol.isNotEmpty
                            ? item.stockSymbol[0]
                            : '?',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              item.status == ItemStatus.substitute &&
                                      item.userHoldingSymbol != null
                                  ? item.userHoldingSymbol!
                                  : item.stockSymbol,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isExcluded
                                      ? context.textTertiary
                                      : context.textPrimary,
                                  decoration: widget.isExcluded
                                      ? TextDecoration.lineThrough
                                      : null),
                              overflow: TextOverflow.ellipsis),
                          if (item.status == ItemStatus.held || item.status == ItemStatus.substitute)
                            Text('(avg: ${item.heldAveragePrice?.toStringAsFixed(0) ?? '-'})',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: context.textSecondary)),
                          if (item.status == ItemStatus.substitute &&
                              item.userHoldingSymbol != null)
                            Text('sub for ${item.stockSymbol}',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: context.textTertiary))
                          else if (item.underfunded)
                            Container(
                              margin: const EdgeInsets.only(top: 1),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: context.statusWarning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Min ₹${(item.lastPrice ?? 0).toStringAsFixed(0)} needed',
                                style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: context.statusWarning),
                              ),
                            ),
                        ]),
                  ),
                ]),
              )),
          // Allocation %
          Expanded(
            flex: 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (item.rebalancedWeight ?? item.etfWeight) / 100.0,
                      minHeight: 4,
                      backgroundColor: context.textTertiary.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isExcluded
                            ? context.textTertiary
                            : (item.status == ItemStatus.held
                                ? context.statusSuccess
                                : item.status == ItemStatus.substitute
                                    ? context.colors.actionPrimaryBg
                                    : isMissing
                                        ? context.statusError
                                        : context.colors.actionPrimaryBg),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(item.rebalancedWeight ?? item.etfWeight).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 9, color: context.textSecondary),
                ),
              ],
            ),
          ),
          // Current Holding
          Expanded(
              flex: 16,
              child: ((item.heldQuantity ?? 0) > 0 && item.lastPrice != null)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.heldQuantity!.toInt()} | ₹${(item.heldQuantity! * item.lastPrice!).toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: context.statusSuccess)),
                        Text(
                            '@ ₹${item.lastPrice?.toStringAsFixed(0) ?? '—'}',
                            style: TextStyle(
                                fontSize: 9,
                                color: context.textTertiary)),
                      ],
                    )
                  : Text('—', style: TextStyle(fontSize: 11, color: context.textTertiary))),
          // Needed to Match
          Expanded(
              flex: 16,
              child: (item.lastPrice != null)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${targetQty.toInt()} | ₹${targetVal.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: targetQty > 0 ? FontWeight.w500 : FontWeight.normal,
                                color: targetQty > 0 ? context.textPrimary : context.textTertiary)),
                      ],
                    )
                  : Text('—', style: TextStyle(fontSize: 11, color: context.textTertiary))),
          // Gap
          Expanded(
              flex: 8,
              child: () {
                if (item.targetQuantity == null) {
                  return Text('—', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: context.textTertiary));
                }
                final gap = item.targetQuantity!.toInt() - (item.heldQuantity ?? 0).toInt();
                if (gap > 0) {
                  return Text('+$gap', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.statusSuccess));
                } else if (gap < 0) {
                  return Text('$gap', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.statusError));
                } else {
                  return Text('0', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: context.textTertiary));
                }
              }()
          ),
          // Investment Amount
          Expanded(
              flex: 13,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: () {
                  if (item.buyQuantity != null && item.buyQuantity! > 0 && item.lastPrice != null) {
                    return Text('₹${(item.buyQuantity! * item.lastPrice!).toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary));
                  } else if (item.lastPrice != null && (item.heldQuantity ?? 0) > 0 && (item.targetQuantity ?? 0) > 0) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${(item.targetQuantity! * item.lastPrice!).toStringAsFixed(0)}',
                             style: TextStyle(fontSize: 11, color: context.textTertiary)),
                        Text('Covered', style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: context.statusSuccess)),
                      ]
                    );
                  } else {
                    return Text('—', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: context.textTertiary));
                  }
                }()
              )),
          // Action
          Expanded(
              flex: 9,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isExcluded)
                      InkWell(
                          onTap: widget.onAdd,
                          child: Icon(Icons.undo,
                              size: 18, color: context.textSecondary))
                    else if (isMissing)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: widget.onSubstitute,
                            child: Icon(Icons.swap_horiz, size: 18, color: context.colors.actionPrimaryBg),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: widget.onRemove,
                            child: Icon(Icons.delete_outline, size: 18, color: context.statusError),
                          ),
                        ]
                      )
                    else
                      InkWell(
                          onTap: widget.onRemove,
                          child: Icon(Icons.delete_outline,
                              size: 18, color: context.statusError)),
                  ])),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TABLET BASKET ROW
// ---------------------------------------------------------------------------
class _TabletBasketRow extends StatelessWidget {
  final BasketItem item;
  final String investedText;
  final bool isExcluded;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onSubstitute;
  final ValueChanged<double> onQtyChanged;

  const _TabletBasketRow({
    required this.item,
    required this.investedText,
    required this.isExcluded,
    required this.onRemove,
    required this.onAdd,
    required this.onSubstitute,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMissing = item.status == ItemStatus.missing && !isExcluded;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: context.borderColor.withValues(alpha: 0.4))),
      ),
      child: Row(children: [
        const SizedBox(width: 12),
        // Asset
        Expanded(
            flex: 32,
            child: Row(children: [
              _StatusDot(status: item.status, isExcluded: isExcluded),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          item.status == ItemStatus.substitute &&
                                  item.userHoldingSymbol != null
                              ? item.userHoldingSymbol!
                              : item.stockSymbol,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isExcluded
                                  ? context.textTertiary
                                  : context.textPrimary,
                              decoration: isExcluded
                                  ? TextDecoration.lineThrough
                                  : null),
                          overflow: TextOverflow.ellipsis),
                      Text(item.sector,
                          style: TextStyle(
                              fontSize: 10, color: context.textTertiary),
                          overflow: TextOverflow.ellipsis),
                    ]),
              ),
            ])),
        // Status
        Expanded(
            flex: 14,
            child: _StatusBadge(
                status: item.status, isExcluded: isExcluded)),
        // ETF weight
        Expanded(
            flex: 12,
            child: Text('${item.etfWeight.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12, color: context.textSecondary))),
        // Invested
        Expanded(
            flex: 18,
            child: Text(investedText,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: context.textPrimary))),
        // Action
        Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: isExcluded
                  ? TextButton(
                      onPressed: onAdd,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero),
                      child: const Text('Restore'))
                  : isMissing
                      ? TextButton(
                          onPressed: onSubstitute,
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero),
                          child: const Text('Swap'))
                      : IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: context.statusError),
                          onPressed: onRemove,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
            )),
        const SizedBox(width: 4),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// MOBILE BASKET CARD
// ---------------------------------------------------------------------------
class _MobileBasketCard extends StatelessWidget {
  final BasketItem item;
  final String investedText;
  final bool isExcluded;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onSubstitute;
  final ValueChanged<double> onQtyChanged;

  const _MobileBasketCard({
    required this.item,
    required this.investedText,
    required this.isExcluded,
    required this.onRemove,
    required this.onAdd,
    required this.onSubstitute,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMissing = item.status == ItemStatus.missing && !isExcluded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Row 1: Dot + Symbol + Status badge + action
          Row(children: [
            _StatusDot(status: item.status, isExcluded: isExcluded),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.status == ItemStatus.substitute &&
                        item.userHoldingSymbol != null
                    ? '${item.userHoldingSymbol!} (sub for ${item.stockSymbol})'
                    : item.stockSymbol,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isExcluded
                        ? context.textTertiary
                        : context.textPrimary,
                    decoration:
                        isExcluded ? TextDecoration.lineThrough : null),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _StatusBadge(status: item.status, isExcluded: isExcluded),
            const SizedBox(width: 4),
            // Action button
            if (isExcluded)
              TextButton(
                onPressed: onAdd,
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero),
                child: const Text('Restore'),
              )
            else if (isMissing)
              TextButton(
                onPressed: onSubstitute,
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero),
                child: const Text('Swap'),
              )
            else
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz,
                    size: 20, color: context.textSecondary),
                onSelected: (val) {
                  if (val == 'remove') onRemove();
                  if (val == 'substitute') onSubstitute();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from basket')),
                  if (item.alternatives.isNotEmpty)
                    const PopupMenuItem(
                        value: 'substitute',
                        child: Text('Find substitute')),
                ],
              ),
          ]),
          const SizedBox(height: 8),
          // Row 2: stats
          Row(children: [
            _MiniStat(
                label: 'ETF Wt.',
                value: '${item.etfWeight.toStringAsFixed(1)}%'),
            const SizedBox(width: 16),
            if (item.lastPrice != null)
              _MiniStat(
                  label: 'Price',
                  value: '₹${item.lastPrice!.toStringAsFixed(1)}'),
            const SizedBox(width: 16),
            _MiniStat(label: 'Invested', value: investedText),
          ]),
          // Row 3: held chip
          if ((item.heldQuantity ?? 0) > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.statusSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: context.statusSuccess.withValues(alpha: 0.3)),
              ),
              child: Text(
                  'Held: ${item.heldQuantity!.toInt()} units @ ₹${item.heldAveragePrice?.toStringAsFixed(0) ?? "—"}',
                  style: TextStyle(
                      fontSize: 10,
                      color: context.statusSuccess,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(fontSize: 9, color: context.textTertiary)),
      Text(value,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textPrimary)),
    ]);
  }
}

// ---------------------------------------------------------------------------
// ALLOCATION SUMMARY CARD (Donut chart + legend)
// ---------------------------------------------------------------------------
class _AllocationSummaryCard extends StatefulWidget {
  final double heldFraction;
  final double subFraction;
  final double missingFraction;
  final int heldCount;
  final int subCount;
  final int missingCount;
  final int excludedCount;
  final Color heldColor;
  final Color subColor;
  final Color missingColor;
  final Color bgColor;
  final double coverage;

  const _AllocationSummaryCard({
    required this.heldFraction,
    required this.subFraction,
    required this.missingFraction,
    required this.heldCount,
    required this.subCount,
    required this.missingCount,
    required this.excludedCount,
    required this.heldColor,
    required this.subColor,
    required this.missingColor,
    required this.bgColor,
    required this.coverage,
  });

  @override
  State<_AllocationSummaryCard> createState() => _AllocationSummaryCardState();
}

class _AllocationSummaryCardState extends State<_AllocationSummaryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heldAnim;
  late Animation<double> _subAnim;
  late Animation<double> _missingAnim;
  late Animation<double> _coverageAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _setupAnimations(0, 0, 0, 0);
    _controller.forward();
  }

  void _setupAnimations(double startHeld, double startSub, double startMissing, double startCoverage) {
    _heldAnim = Tween<double>(begin: startHeld, end: widget.heldFraction).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _subAnim = Tween<double>(begin: startSub, end: widget.subFraction).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _missingAnim = Tween<double>(begin: startMissing, end: widget.missingFraction).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    final targetCoverage = (widget.heldFraction + widget.subFraction) * 100.0;
    _coverageAnim = Tween<double>(begin: startCoverage, end: targetCoverage).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _AllocationSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heldFraction != widget.heldFraction ||
        oldWidget.subFraction != widget.subFraction ||
        oldWidget.missingFraction != widget.missingFraction ||
        oldWidget.coverage != widget.coverage) {
      _setupAnimations(_heldAnim.value, _subAnim.value, _missingAnim.value, _coverageAnim.value);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Allocation Summary',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Row(children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(100, 100),
                    painter: _DonutCoveragePainter(
                      heldFraction: _heldAnim.value,
                      subFraction: _subAnim.value,
                      missingFraction: _missingAnim.value,
                      heldColor: widget.heldColor,
                      subColor: widget.subColor,
                      missingColor: widget.missingColor,
                      bgColor: widget.bgColor,
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${_coverageAnim.value.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: context.textPrimary)),
                Text('covered',
                    style: TextStyle(
                        fontSize: 10, color: context.textSecondary)),
                  ]);
                },
              ),
            ],
          ),
        ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(children: [
                  _LegendItem(
                      color: widget.heldColor,
                      label: 'Held',
                      value: '${widget.heldCount} (${(_heldAnim.value * 100).toStringAsFixed(1)}%)'),
                  _LegendItem(
                      color: widget.subColor,
                      label: 'Subst.',
                      value: '${widget.subCount} (${(_subAnim.value * 100).toStringAsFixed(1)}%)'),
                  _LegendItem(
                      color: widget.missingColor,
                      label: 'Missing',
                      value: '${widget.missingCount} (${(_missingAnim.value * 100).toStringAsFixed(1)}%)'),
                  _LegendItem(
                      color: context.textTertiary,
                      label: 'Excluded',
                      value: '${widget.excludedCount} (0%)'),
                ]);
              },
            ),
          ),
        ]),
      ]),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 11, color: context.textSecondary))),
        Text(value,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

/// Donut chart painter — colors passed as constructor args (Gap 12 fix)
class _DonutCoveragePainter extends CustomPainter {
  final double heldFraction;
  final double subFraction;
  final double missingFraction;
  final Color heldColor;
  final Color subColor;
  final Color missingColor;
  final Color bgColor;

  const _DonutCoveragePainter({
    required this.heldFraction,
    required this.subFraction,
    required this.missingFraction,
    required this.heldColor,
    required this.subColor,
    required this.missingColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final rect = Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -1.5707963267948966; // -π/2
    const fullSweep = 6.283185307179586; // 2π

    // Background
    paint.color = bgColor;
    canvas.drawArc(rect, 0, fullSweep, false, paint);

    // Held arc
    if (heldFraction > 0) {
      paint.color = heldColor;
      canvas.drawArc(rect, startAngle, heldFraction * fullSweep, false, paint);
    }
    // Substituted arc
    if (subFraction > 0) {
      paint.color = subColor;
      canvas.drawArc(
          rect,
          startAngle + heldFraction * fullSweep,
          subFraction * fullSweep,
          false,
          paint);
    }
    // Missing arc
    if (missingFraction > 0) {
      paint.color = missingColor;
      canvas.drawArc(
          rect,
          startAngle + (heldFraction + subFraction) * fullSweep,
          missingFraction * fullSweep,
          false,
          paint);
    }
  }

  @override
  bool shouldRepaint(_DonutCoveragePainter old) =>
      old.heldFraction != heldFraction ||
      old.subFraction != subFraction ||
      old.missingFraction != missingFraction;
}

// ---------------------------------------------------------------------------
// COMPARISON TAB (preserved, zero changes to internal logic)
// ---------------------------------------------------------------------------
class _BasketComparisonTab extends StatelessWidget {
  final BasketOpportunity originalOpportunity;
  final List<BasketItem> myBasketItems;
  final bool hasCalculated;
  final bool includeHeld;

  const _BasketComparisonTab({
    required this.originalOpportunity,
    required this.myBasketItems,
    required this.hasCalculated,
    required this.includeHeld,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasCalculated) {
      return const Center(
        child: Text('Please calculate the basket to see the comparison.'),
      );
    }
    final activeItems = includeHeld
        ? myBasketItems
        : myBasketItems.where((i) => i.status != ItemStatus.held).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowHeight: 40,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 44,
          columns: const [
            DataColumn(
                label: Text('Constituent',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('ETF Wt.',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Action',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('My Basket',
                    style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: activeItems.map((item) {
            final isMissing = item.status == ItemStatus.missing;
            final isSubstitute = item.status == ItemStatus.substitute;
            double pct = 0;
            double totalActiveInvestment = 0;
            for (var i in activeItems) {
              if (i.lastPrice != null && i.buyQuantity != null) {
                totalActiveInvestment += i.lastPrice! * i.buyQuantity!;
              }
            }
            if (totalActiveInvestment > 0 && item.lastPrice != null) {
              pct = (item.lastPrice! * (item.buyQuantity ?? 0.0) /
                      totalActiveInvestment) *
                  100;
            }
            Widget actionWidget;
            if (isMissing) {
              actionWidget = Text('EXCLUDED',
                  style: TextStyle(
                      color: context.statusError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold));
            } else if (isSubstitute) {
              actionWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: context.colors.actionPrimaryBg.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('SUB: ${item.userHoldingSymbol}',
                    style: TextStyle(
                        color: context.colors.actionPrimaryBg,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              );
            } else if (item.status == ItemStatus.held) {
              actionWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: context.statusSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('HELD',
                    style: TextStyle(
                        color: context.statusSuccess,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              );
            } else {
              actionWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: context.statusSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('BUY',
                    style: TextStyle(
                        color: context.statusSuccess,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              );
            }
            return DataRow(cells: [
              DataCell(Text(item.stockSymbol,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13))),
              DataCell(Text('${item.etfWeight.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 13))),
              DataCell(actionWidget),
              DataCell(Text(
                isMissing ? '-' : '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                    color: isMissing
                        ? context.textTertiary
                        : context.statusSuccess,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SECTOR COMPARISON TAB (preserved, zero changes to internal logic)
// ---------------------------------------------------------------------------
class _SectorComparisonTab extends StatelessWidget {
  final BasketOpportunity originalOpportunity;
  final List<BasketItem> myBasketItems;
  final bool hasCalculated;
  final bool includeHeld;

  const _SectorComparisonTab({
    required this.originalOpportunity,
    required this.myBasketItems,
    required this.hasCalculated,
    required this.includeHeld,
  });

  Color _getColorForSector(String sector) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
      const Color(0xFFFFEB3B),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
      const Color(0xFFE91E63),
    ];
    return colors[sector.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (!hasCalculated) {
      return const Center(
        child: Text('Please calculate the basket to see the sector analysis.'),
      );
    }
    final activeItems = includeHeld
        ? myBasketItems
        : myBasketItems.where((i) => i.status != ItemStatus.held).toList();

    final Map<String, double> etfSectorWeights = {};
    final Map<String, double> mySectorWeights = {};
    double myTotalWeight = 0;

    for (var item in originalOpportunity.composition) {
      etfSectorWeights[item.sector] =
          (etfSectorWeights[item.sector] ?? 0) + item.etfWeight;
    }
    for (var item in activeItems) {
      double weight = 0;
      if (item.lastPrice != null && (item.buyQuantity ?? 0.0) > 0) {
        weight = item.lastPrice! * (item.buyQuantity ?? 0.0);
      }
      mySectorWeights[item.sector] =
          (mySectorWeights[item.sector] ?? 0) + weight;
      myTotalWeight += weight;
    }
    if (myTotalWeight > 0) {
      mySectorWeights
          .updateAll((key, value) => (value / myTotalWeight) * 100);
    }

    final allSectors =
        {...etfSectorWeights.keys, ...mySectorWeights.keys}.toList();
    allSectors
        .sort((a, b) => (etfSectorWeights[b] ?? 0).compareTo(etfSectorWeights[a] ?? 0));

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: allSectors.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final sector = allSectors[index];
        final etfPct = etfSectorWeights[sector] ?? 0.0;
        final myPct = mySectorWeights[sector] ?? 0.0;
        final color = _getColorForSector(sector);

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sector,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ETF: ${etfPct.toStringAsFixed(1)}% | My: ${myPct.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 10, color: context.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: LinearProgressIndicator(
                value: etfPct / 100,
                backgroundColor: context.dividerColor,
                color: context.textTertiary,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: myPct / 100,
                backgroundColor: color.withValues(alpha: 0.2),
                color: color,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ]),
        ]);
      },
    );
  }
}
// ---------------------------------------------------------------------------
// SLIVER TAB BAR DELEGATE (kept for potential future use)
// ---------------------------------------------------------------------------
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(
          color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);

  @override
  bool shouldRebuild(_SliverTabBarDelegate old) => false;
}

class _ActualCostBanner extends StatelessWidget {
  final double actualCost;
  final double variance;
  final double investmentAmount;
  final double? residualCash;
  final double heldCoverage;
  final String Function(double) formatCurrency;

  const _ActualCostBanner({
    required this.actualCost,
    required this.variance,
    required this.investmentAmount,
    this.residualCash,
    required this.heldCoverage,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverBudget = variance > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOverBudget
            ? context.statusWarning.withValues(alpha: 0.1)
            : context.statusSuccess.withValues(alpha: 0.1),
        borderRadius: AppRadii.button,
        border: Border.all(
          color: isOverBudget
              ? context.statusWarning.withValues(alpha: 0.3)
              : context.statusSuccess.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              isOverBudget ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              size: 16,
              color: isOverBudget ? context.statusWarning : context.statusSuccess,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Budget: ${formatCurrency(actualCost)} of ${formatCurrency(investmentAmount)} deployed in fresh orders',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (heldCoverage > 0)
                  Text(
                    'Held stocks cover ${formatCurrency(heldCoverage)} of the basket',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.statusSuccess,
                    ),
                  ),
                if (residualCash != null && residualCash! > 0)
                  Text(
                    'Rounding leftover: ${formatCurrency(residualCash!)} (undeployed)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

