import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../domain/models/basket_opportunity.dart';
import '../widgets/minimum_investment_warning_widget.dart';
import '../providers/basket_providers.dart';
import '../utils/basket_api_errors.dart';
import '../widgets/substitute_selector.dart';
import '../basket_navigation.dart';
import '../flow/basket_flow_controller.dart';
import '../widgets/shared/basket_flow_step.dart';
import '../widgets/shared/basket_flow_stepper.dart';
import '../widgets/shared/basket_sticky_action_bar.dart';
import '../widgets/shared/basket_glass_dialogs.dart';
import '../utils/basket_allocation_math.dart';
import '../utils/basket_responsive.dart';
import '../shared/widgets/basket_stat_pill.dart';
import '../shared/widgets/basket_group_header.dart';
import '../customize/widgets/customize_actual_cost_banner.dart';
import '../customize/widgets/customize_allocation_summary_card.dart';
import '../customize/widgets/customize_basket_comparison_tab.dart';
import '../shared/widgets/basket_constituent_row.dart';
import '../customize/widgets/customize_sector_comparison_tab.dart';
import '../customize/customize_basket_formatters.dart';
import '../customize/customize_basket_metrics.dart';
import '../shared/basket_constituent_grouper.dart';
import '../shared/basket_item_status_theme.dart';
import '../shared/basket_panel_styles.dart';
part '../customize/customize_basket_logic.dart';
part '../customize/customize_basket_layouts.dart';
part '../customize/customize_basket_sidebar.dart';


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
  Timer? _debounceTimer;
  double? _actualCost;
  double? _budgetVariance;
  final Map<String, int> _manualQtyOverrides = {};
  int _calcEpoch = 0;
  BasketOpportunity? _resumeRefreshBaseline;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flow = ref.read(basketFlowControllerProvider);
      final flowNotifier = ref.read(basketFlowControllerProvider.notifier);
      var restoredFromFlow = false;
      if (flow.currentOpportunity?.etfIsin == widget.opportunity.etfIsin) {
        restoredFromFlow = true;
        setState(() {
          _currentOpportunity = flow.currentOpportunity ?? widget.opportunity;
          _items = List.from(_currentOpportunity.composition);
          _excludedItems
            ..clear()
            ..addAll(flow.excludedSymbols);
          _manualQtyOverrides
            ..clear()
            ..addAll(flow.manualQtyOverrides);
          if (flow.investmentAmount != null) {
            _amountController.text = flow.investmentAmount!.toInt().toString();
          }
          if (flow.basketName != null && flow.basketName!.isNotEmpty) {
            _basketNameController.text = flow.basketName!;
          }
          if (flow.hasCalculated) {
            _hasCalculated = true;
            _actualCost = _currentOpportunity.actualInvestmentCost;
            _budgetVariance = _currentOpportunity.budgetVariance;
          }
        });
      } else {
        if (!flow.isEmpty) {
          flowNotifier.resetFlow();
        }
        flowNotifier.startFlow(widget.opportunity);
      }

      final defaultAmount =
          widget.opportunity.minimumInvestmentAmount ?? 100000.0;
      if (_amountController.text.isEmpty) {
        _amountController.text = defaultAmount.toInt().toString();
      }

      final amount = double.tryParse(_amountController.text) ?? defaultAmount;
      if (restoredFromFlow &&
          _hasCalculated &&
          _currentOpportunity.isQuantitiesCalculatedForAmount(amount)) {
        // Instant hydrate from draft/session; refresh in background.
        _scheduleBackgroundRefreshAfterResume();
        return;
      }
      if (widget.opportunity.isQuantitiesCalculatedForAmount(defaultAmount) &&
          !restoredFromFlow) {
        setState(() {
          _hasCalculated = true;
          _actualCost = widget.opportunity.actualInvestmentCost;
          _budgetVariance = widget.opportunity.budgetVariance;
        });
        return;
      }
      _scheduleRecalculate(immediate: true);
    });
  }

  void _scheduleBackgroundRefreshAfterResume() {
    final before = _currentOpportunity;
    _resumeRefreshBaseline = before;
    _scheduleRecalculate(immediate: true);
  }

  void _syncFlowSnapshot() {
    final amount = double.tryParse(_amountController.text);
    final flow = ref.read(basketFlowControllerProvider.notifier);
    if (amount != null && amount > 0) {
      flow.setInvestmentAmount(amount);
    }
    final name = _basketNameController.text.trim();
    if (name.isNotEmpty) {
      flow.setBasketName(name);
    }
    flow.setHasCalculated(_hasCalculated);
    flow.updateOpportunity(
      _currentOpportunity.copyWith(composition: _items),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    try {
      _syncFlowSnapshot();
    } catch (_) {
      // Provider may already be disposed when leaving the section.
    }
    _amountController.dispose();
    _basketNameController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final isMobile = BasketResponsive.isMobile(context);
    final isDesktop = BasketResponsive.isDesktop(context);
    final isTablet = BasketResponsive.isTablet(context);

    final displayItems = _items;

    final heldCount = CustomizeBasketMetrics.heldCount(displayItems);
    final subCount = CustomizeBasketMetrics.substituteCount(displayItems);
    final missingCount =
        CustomizeBasketMetrics.missingCount(displayItems, _excludedItems);
    final excludedCount = _excludedItems.length;

    final heldWeight = _currentOpportunity.heldMatchScore ?? 0.0;
    final subWeight = _currentOpportunity.substituteMatchScore ?? 0.0;
    final missingWeight = _currentOpportunity.missingMatchScore ?? 0.0;
    final coverage = CustomizeBasketMetrics.coverage(
      hasCalculated: _hasCalculated,
      opportunity: _currentOpportunity,
    );

    final tabItems = BasketConstituentGrouper.filterItems(
      BasketConstituentGrouper.filterForTabIndex(_tabController.index),
      displayItems,
      _excludedItems,
    );

    final flowTrailing = isMobile
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCalculating)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              IconButton(
                icon: Icon(Icons.donut_large_outlined,
                    color: ModuleColors.portfolio),
                tooltip: 'Portfolio Summary',
                onPressed: () => _showMobileSummarySheet(
                  context,
                  displayItems,
                  heldCount,
                  subCount,
                  missingCount,
                  excludedCount,
                  coverage,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showMobileOptionsMenu(
                  context,
                  displayItems,
                  heldCount,
                  subCount,
                  missingCount,
                  excludedCount,
                  coverage,
                ),
              ),
            ],
          )
        : isTablet
            ? IconButton(
                icon: Icon(Icons.assessment_outlined,
                    color: ModuleColors.portfolio),
                tooltip: 'Portfolio Summary',
                onPressed: () =>
                    setState(() => _showSummaryDrawer = !_showSummaryDrawer),
              )
            : IconButton(
                icon: Icon(_isSidebarCollapsed
                    ? Icons.keyboard_double_arrow_left
                    : Icons.keyboard_double_arrow_right),
                tooltip: _isSidebarCollapsed ? 'Show Summary' : 'Hide Summary',
                onPressed: () =>
                    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
              );

    final content = isDesktop
        ? _buildDesktopLayout(context, displayItems, tabItems, heldCount,
            subCount, missingCount, excludedCount, heldWeight, subWeight,
            missingWeight, coverage)
        : isMobile
            ? _buildMobileLayout(context, displayItems, tabItems, heldCount,
                subCount, missingCount, excludedCount, coverage)
            : _buildTabletLayout(context, displayItems, tabItems, heldCount,
                subCount, missingCount, excludedCount, heldWeight, subWeight,
                missingWeight, coverage);

    final body = Column(
      children: [
        _buildFlowChrome(context, trailing: flowTrailing),
        Expanded(child: content),
      ],
    );

    if (widget.embedded) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _handleBack();
        },
        child: Column(
          children: [
            Expanded(child: body),
            _buildBottomActionBar(coverage, displayItems),
          ],
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: body,
        bottomNavigationBar: _buildBottomActionBar(coverage, displayItems),
      ),
    );
  }
}
