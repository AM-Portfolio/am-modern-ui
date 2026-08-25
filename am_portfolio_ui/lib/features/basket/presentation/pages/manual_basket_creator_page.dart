import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../domain/models/basket_opportunity.dart';
import '../widgets/minimum_investment_warning_widget.dart';
import '../../../portfolio/providers/portfolio_providers.dart';
import '../../../portfolio/internal/domain/entities/portfolio_holding.dart';
import '../providers/basket_providers.dart';
import 'package:go_router/go_router.dart';
import 'basket_success_page.dart';
import '../widgets/substitute_selector.dart';

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
  bool _includeHeld = false;
  bool _isCalculating = false;
  bool _hasCalculated = false;
  bool _isCustomAmount = false;
  bool _showPercentAllocation = false;
  bool _hasStaleData = false;
  bool _showSummaryDrawer = false; // tablet side panel

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
    if (item.lastPrice == null || item.buyQuantity == null) return '—';
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
      _items[index] = _items[index].copyWith(clearBuyQuantity: true);
      _hasCalculated = false;
    });
  }

  void _addItem(int index) {
    setState(() {
      _excludedItems.remove(_items[index].stockSymbol);
      _items[index] = _items[index].copyWith(buyQuantity: 0.0);
      _hasCalculated = false;
    });
  }

  void _resetBasket() {
    setState(() {
      _excludedItems.clear();
      _items = List.from(widget.opportunity.composition);
      _hasCalculated = false;
    });
  }

  void _rebalance() {
    double activeWeights = 0.0;
    for (var item in _items) {
      if (item.buyQuantity != null ||
          item.status == ItemStatus.held ||
          item.status == ItemStatus.substitute) {
        activeWeights += item.etfWeight;
      }
    }
    if (activeWeights > 0 && activeWeights < 100.0) {
      final multiplier = 100.0 / activeWeights;
      setState(() {
        _items = _items.map((item) {
          if (item.buyQuantity != null ||
              item.status == ItemStatus.held ||
              item.status == ItemStatus.substitute) {
            return item.copyWith(
                rebalancedWeight: item.etfWeight * multiplier);
          }
          return item;
        }).toList();
        _hasCalculated = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Basket rebalanced! Click Recalculate to see new quantities.')),
      );
    }
  }

  void _setFixedAmount(int amountRs) {
    setState(() {
      _amountController.text = amountRs.toString();
      _isCustomAmount = false;
      _hasCalculated = false;
    });
    _calculateQuantities();
  }

  Future<void> _calculateQuantities() async {
    if (_amountController.text.isEmpty) return;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _isCalculating = true;
      _hasStaleData = false;
    });

    try {
      double targetAmount = amount;
      if (_includeHeld) {
        final holdingsAsync =
            ref.read(portfolioHoldingsProvider(widget.userId));
        final localHoldings = holdingsAsync.asData?.value;
        if (localHoldings != null) {
          double totalHeldCost = 0;
          double totalHeldCurrentVal = 0;
          for (var item in _items) {
            final h = localHoldings.holdings
                .where((h) =>
                    h.symbol.toLowerCase() ==
                    item.stockSymbol.toLowerCase())
                .firstOrNull;
            if (h != null) {
              totalHeldCost += h.quantity * h.avgPrice;
              totalHeldCurrentVal +=
                  h.quantity * (item.lastPrice ?? h.currentPrice);
            }
          }
          if (amount > totalHeldCost) {
            targetAmount = totalHeldCurrentVal + (amount - totalHeldCost);
          }
        }
      }

      final holdingsAsync = ref.read(portfolioHoldingsProvider(widget.userId));
      final localHoldings = holdingsAsync.asData?.value;
      final itemsToSend = _enrichItemsWithHoldings(_items, localHoldings);

      final updatedOpportunity =
          await ref.read(calculateBasketQuantitiesProvider(
        request: {
          'investmentAmount': targetAmount,
          'opportunity':
              _currentOpportunity.copyWith(composition: itemsToSend).toJson(),
          'includeHeld': _includeHeld,
        },
      ).future);

      setState(() {
        _currentOpportunity = updatedOpportunity;
        final Map<String, BasketItem> updatedMap = {
          for (var item in updatedOpportunity.composition)
            item.stockSymbol.toLowerCase(): item
        };
        _items = _items.map((item) {
          final updatedItem = updatedMap[item.stockSymbol.toLowerCase()];
          if (updatedItem != null) {
            if (_excludedItems.contains(item.stockSymbol)) {
              return updatedItem.copyWith(clearBuyQuantity: true);
            }
            return updatedItem;
          }
          return item;
        }).toList();
        _hasCalculated = true;
      });
    } catch (e) {
      setState(() => _hasStaleData = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating quantities: $e')),
      );
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  void _openSubstituteSelectorFor(int originalIdx) {
    final item = _items[originalIdx];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SubstituteSelector(
        originalSymbol: item.stockSymbol,
        requiredMarketCap: item.marketCapCategory ?? '',
        onSelected: (stock) {
          setState(() {
            _items[originalIdx] = _items[originalIdx].copyWith(
              status: ItemStatus.substitute,
              userHoldingSymbol: stock.symbol,
              userHoldingIsin: stock.isin,
            );
            _hasCalculated = false;
          });
          Navigator.of(ctx).pop();
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

  Future<void> _savePortfolio() async {
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

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final request = {
        'userId': widget.userId,
        'sourcePortfolioId': widget.portfolioId,
        'etfIsin': widget.opportunity.etfIsin,
        'etfName': widget.opportunity.etfName,
        'basketName': basketName,
        'idempotencyKey': DateTime.now().millisecondsSinceEpoch.toString(),
        'investmentAmount': amount,
        'remainingMissingCount':
            _items.where((c) => c.status == ItemStatus.missing).length,
        'remainingMissing': _items
            .where((c) => c.status == ItemStatus.missing)
            .map((c) => c.stockSymbol)
            .toList(),
        'lines': _items.map((item) {
          return {
            'status':
                item.status.toString().split('.').last.toUpperCase(),
            'etfIsin': item.isin,
            'etfSymbol': item.stockSymbol,
            'holdingIsin':
                (item.status == ItemStatus.substitute ||
                        item.status == ItemStatus.held)
                    ? (item.userHoldingIsin ?? item.isin)
                    : item.isin,
            'holdingSymbol':
                (item.status == ItemStatus.substitute ||
                        item.status == ItemStatus.held)
                    ? (item.userHoldingSymbol ?? item.stockSymbol)
                    : item.stockSymbol,
            'quantity': item.buyQuantity,
            'heldQuantity': item.heldQuantity,
            'averageBuyingPrice': item.lastPrice,
          };
        }).toList(),
      };

      final newBasketId =
          await ref.read(createBasketPortfolioProvider(request: request).future);

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      ref.invalidate(myBasketsProvider(userId: widget.userId, portfolioId: ''));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BasketSuccessPage(
              opportunity: widget.opportunity,
              basketName: basketName,
              basketId: newBasketId,
              userId: widget.userId,
              portfolioId: widget.portfolioId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create basket: $e'),
          backgroundColor: context.statusError,
        ));
      }
    }
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
        ref.watch(portfolioHoldingsProvider(widget.userId));
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
        .fold(0.0, (s, i) => s + i.etfWeight);
    final subWeight = displayItems
        .where((i) => i.status == ItemStatus.substitute)
        .fold(0.0, (s, i) => s + i.etfWeight);
    final missingWeight = displayItems
        .where((i) => i.status == ItemStatus.missing)
        .fold(0.0, (s, i) => s + i.etfWeight);
    final coverage = heldWeight + subWeight;

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
              SizedBox(
                width: 320,
                child: _buildRightSidebar(context, theme, displayItems,
                    heldCount, subCount, missingCount, excludedCount, heldWeight,
                    subWeight, missingWeight, coverage),
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
                        onPressed: _savePortfolio,
                        style: FilledButton.styleFrom(
                          backgroundColor: context.colors.actionPrimaryBg,
                          foregroundColor: context.colors.actionPrimaryFg,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Create Basket',
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
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 12),
        Icon(Icons.auto_awesome, color: context.colors.actionPrimaryBg),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Customize Basket', style: theme.textTheme.titleMedium),
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
          onPressed: _savePortfolio,
          icon: const Icon(Icons.save_alt, size: 16),
          label: const Text('Save Basket'),
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
            onPressed: () => context.pop()),
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
              onPressed: () => context.pop()),
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
    return Column(
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
        // Stats strip
        _buildStatsStrip(context, theme, displayItems.length, heldCount,
            subCount, missingCount, excludedCount,
            isMobile: isMobile),
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
        // Constituent list
        Expanded(
          child: _buildConstituentList(context, theme, tabItems, displayItems,
              isMobile: isMobile, isTablet: isTablet),
        ),
        // Bottom info bar
        _buildBottomInfoBar(context, theme),
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
        // Include Held toggle
        Row(children: [
          Text('Include Held', style: theme.textTheme.labelSmall),
          const SizedBox(width: 4),
          Switch(
            value: _includeHeld,
            onChanged: (v) {
              setState(() => _includeHeld = v);
              if (_amountController.text.isNotEmpty) _calculateQuantities();
            },
          ),
          if (!isMobile) ...[
            const Spacer(),
            Text('Show % Alloc', style: theme.textTheme.labelSmall),
            Switch(
              value: _showPercentAllocation,
              onChanged: (v) => setState(() => _showPercentAllocation = v),
            ),
          ],
        ]),
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
      height: 36,
      color: context.backgroundColor,
      child: Row(children: [
        cell('Asset', 26),
        cell('Status', 12),
        cell('Holding', 16),
        cell('ETF Wt.', 10, align: TextAlign.right),
        if (_showPercentAllocation) cell('Alloc %', 14),
        cell('Invested', 14, align: TextAlign.right),
        cell('', 8),
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
            isExcluded: _excludedItems.contains(item.stockSymbol),
            showAllocationSlider: _showPercentAllocation,
            originalIdx: originalIdx,
            onRemove: () => _removeItem(originalIdx),
            onAdd: () => _addItem(originalIdx),
            onSubstitute: () => _openSubstituteSelectorFor(originalIdx),
            onQtyChanged: (v) => _updateQuantity(originalIdx, v),
            onWeightChanged: (w) {
              setState(() {
                _items[originalIdx] =
                    _items[originalIdx].copyWith(rebalancedWeight: w);
                _hasCalculated = false;
              });
              _calculateQuantities();
            },
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

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.only(
        bottom: isMobile ? 80 : 16,
        left: isMobile ? 8 : 0,
        right: isMobile ? 8 : 0,
        top: 4,
      ),
      children: rows,
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
        const Expanded(flex: 12, child: SizedBox()),
        const Expanded(flex: 16, child: SizedBox()),
        Expanded(
            flex: 10,
            child: Text('100%',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right)),
        if (_showPercentAllocation)
          const Expanded(flex: 14, child: SizedBox()),
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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _savePortfolio,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Create Basket',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.actionPrimaryBg,
                foregroundColor: context.colors.actionPrimaryFg,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
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
                includeHeld: _includeHeld,
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
                includeHeld: _includeHeld,
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
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
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
        const Spacer(),
        FilledButton(
          onPressed: _savePortfolio,
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.actionPrimaryBg,
            foregroundColor: context.colors.actionPrimaryFg,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Create Basket',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]),
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
          leading: const Icon(Icons.balance),
          title: const Text('Rebalance Weights'),
          onTap: () {
            Navigator.of(ctx).pop();
            _rebalance();
          },
        ),
        ListTile(
          leading: Icon(Icons.percent, color: context.colors.actionPrimaryBg),
          title: const Text('Show % Allocation'),
          trailing: Switch(
            value: _showPercentAllocation,
            onChanged: (v) {
              Navigator.of(ctx).pop();
              setState(() => _showPercentAllocation = v);
            },
          ),
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
            _savePortfolio();
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
  final bool isExcluded;
  final bool showAllocationSlider;
  final int originalIdx;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onSubstitute;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<double> onWeightChanged;

  const _DenseBasketRow({
    required this.item,
    required this.investedText,
    required this.isExcluded,
    required this.showAllocationSlider,
    required this.originalIdx,
    required this.onRemove,
    required this.onAdd,
    required this.onSubstitute,
    required this.onQtyChanged,
    required this.onWeightChanged,
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
              flex: 26,
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
                          if (item.status == ItemStatus.substitute &&
                              item.userHoldingSymbol != null)
                            Text('sub for ${item.stockSymbol}',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: context.textTertiary)),
                        ]),
                  ),
                ]),
              )),
          // Status
          Expanded(
              flex: 12,
              child: _StatusBadge(
                  status: item.status, isExcluded: widget.isExcluded)),
          // Holding
          Expanded(
              flex: 16,
              child: (item.heldQuantity ?? 0) > 0
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${item.heldQuantity!.toInt()} units',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: context.statusSuccess)),
                        if (item.heldAveragePrice != null)
                          Text(
                              '@ ₹${item.heldAveragePrice!.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: context.textTertiary)),
                      ],
                    )
                  : const SizedBox()),
          // ETF weight
          Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('${item.etfWeight.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12, color: context.textSecondary)),
              )),
          // Alloc slider
          if (widget.showAllocationSlider)
            Expanded(
                flex: 14,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: context.colors.actionPrimaryBg,
                    thumbColor: context.colors.actionPrimaryBg,
                    inactiveTrackColor: context.dividerColor,
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: (item.rebalancedWeight ?? item.etfWeight)
                        .clamp(0.0, 100.0),
                    min: 0,
                    max: 100,
                    onChangeEnd: widget.onWeightChanged,
                    onChanged: (_) {},
                  ),
                )),
          // Invested
          Expanded(
              flex: 14,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(widget.investedText,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary)),
              )),
          // Action
          Expanded(
              flex: 8,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isExcluded)
                      InkWell(
                          onTap: widget.onAdd,
                          child: Icon(Icons.undo,
                              size: 18, color: context.textSecondary))
                    else if (isMissing)
                      InkWell(
                          onTap: widget.onSubstitute,
                          child: Icon(Icons.swap_horiz,
                              size: 18,
                              color: context.colors.actionPrimaryBg))
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
class _AllocationSummaryCard extends StatelessWidget {
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
              CustomPaint(
                size: const Size(100, 100),
                painter: _DonutCoveragePainter(
                  heldFraction: heldFraction,
                  subFraction: subFraction,
                  missingFraction: missingFraction,
                  heldColor: heldColor,
                  subColor: subColor,
                  missingColor: missingColor,
                  bgColor: bgColor,
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${coverage.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: context.textPrimary)),
                Text('covered',
                    style: TextStyle(
                        fontSize: 10, color: context.textSecondary)),
              ]),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(children: [
              _LegendItem(
                  color: heldColor,
                  label: 'Held',
                  value: '$heldCount (${(heldFraction * 100).toStringAsFixed(1)}%)'),
              _LegendItem(
                  color: subColor,
                  label: 'Subst.',
                  value: '$subCount (${(subFraction * 100).toStringAsFixed(1)}%)'),
              _LegendItem(
                  color: missingColor,
                  label: 'Missing',
                  value: '$missingCount (${(missingFraction * 100).toStringAsFixed(1)}%)'),
              _LegendItem(
                  color: context.textTertiary,
                  label: 'Excluded',
                  value: '$excludedCount (0%)'),
            ]),
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(sector,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('ETF: ${etfPct.toStringAsFixed(1)}% | My: ${myPct.toStringAsFixed(1)}%'),
          ]),
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

