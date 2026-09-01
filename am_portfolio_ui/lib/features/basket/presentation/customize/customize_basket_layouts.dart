part of '../pages/manual_basket_creator_page.dart';

extension _ManualBasketCreatorPageLayouts on _ManualBasketCreatorPageState {
  Widget _buildFlowChrome(
    BuildContext context, {
    Widget? trailing,
  }) {
    return BasketFlowStepper(
      currentStep: BasketFlowStep.customize,
      trailing: trailing,
    );
  }

  Widget _buildBottomActionBar(double coverage, List<BasketItem> displayItems) {
    final investAmount = double.tryParse(_amountController.text) ?? 0.0;
    final targetSum = _targetWeightSum(displayItems);
    final customWeightSum = _totalCustomWeightPercent(displayItems, investAmount);
    final customValue = _totalCustomInvestment(displayItems);

    return BasketStickyActionBar(
      stats: [
        BasketStatItem(
          label: 'Target Wt',
          value: '${targetSum.toStringAsFixed(1)}%',
        ),
        BasketStatItem(
          label: 'Allocation Wt',
          value: '${customWeightSum.toStringAsFixed(1)}%',
          highlight: customWeightSum >= 80,
        ),
        BasketStatItem(
          label: 'From Holdings',
          value: '₹${customValue.toStringAsFixed(0)}',
        ),
        BasketStatItem(
          label: 'Match Score',
          value: '${coverage.toStringAsFixed(0)}%',
          highlight: coverage >= 80,
        ),
      ],
      onBack: () => Navigator.of(context).maybePop(),
      primaryLabel: 'Review & Confirm',
      onPrimary: _goToFinalPreview,
      isLoading: _isCalculating,
    );
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildLeftPanel(context, theme, displayItems, tabItems,
              heldCount, subCount, missingCount, excludedCount,
              isMobile: false, isTablet: false),
        ),
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
        _buildLeftPanel(context, theme, displayItems, tabItems, heldCount,
            subCount, missingCount, excludedCount,
            isMobile: false, isTablet: true),
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
                    CustomizeAllocationSummaryCard(
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
                    _buildInvestmentSummaryCard(context, theme),
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
    return _buildLeftPanel(context, theme, displayItems, tabItems, heldCount,
        subCount, missingCount, excludedCount,
        isMobile: true, isTablet: false);
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
                _scheduleRecalculate(immediate: true);
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
          child: AmToggleChip(
            label: CustomizeBasketFormatters.formatPreset(preset),
            selected: !_isCustomAmount &&
                _amountController.text == preset.toString(),
            compact: true,
            onTap: () => _setFixedAmount(preset),
          ),
        ),
      AmToggleChip(
        label: 'Custom',
        selected: _isCustomAmount,
        compact: true,
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
                      onChanged: (_) => _scheduleRecalculate(),
                      onSubmitted: (_) => _scheduleRecalculate(immediate: true),
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
          CustomizeActualCostBanner(
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
            formatCurrency: CustomizeBasketFormatters.formatRupee,
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
        Tooltip(
          message: 'Allocation % = value from your holdings in this basket ÷ budget',
          child: cell('Allocation\n(Target | Custom)', 10),
        ),
        cell('Your Holding\n(Units | Value)', 16),
        cell('In Basket\n(Units)', 16),
        cell('Gap vs ETF\n(Units)', 8, align: TextAlign.center),
        cell('Basket\nValue', 13, align: TextAlign.right),
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
      rows.add(BasketGroupHeader(label: '$label (${items.length})', color: color));
      for (final item in items) {
        final originalIdx = displayItems.indexOf(item);
        if (originalIdx == -1) continue;
        if (isMobile) {
          rows.add(CustomizeConstituentRowMobile(
            item: item,
            hasCalculated: _hasCalculated,
            investedText: CustomizeBasketFormatters.investedText(item),
            isExcluded: _excludedItems.contains(item.stockSymbol),
            onRemove: () => _removeItem(originalIdx),
            onAdd: () => _addItem(originalIdx),
            onAddGap: () => _openSubstituteSelectorFor(originalIdx, isGapFill: true),
            onSubstitute: () => _openSubstituteSelectorFor(originalIdx),
            onQtyChanged: (v) => _updateQuantity(originalIdx, v),
            onTargetQtyChanged: (delta) => _updateTargetQuantity(originalIdx, delta),
          ));
        } else if (isTablet) {
          rows.add(CustomizeConstituentRowTablet(
            item: item,
            hasCalculated: _hasCalculated,
            investedText: CustomizeBasketFormatters.investedText(item),
            isExcluded: _excludedItems.contains(item.stockSymbol),
            onRemove: () => _removeItem(originalIdx),
            onAdd: () => _addItem(originalIdx),
            onAddGap: () => _openSubstituteSelectorFor(originalIdx, isGapFill: true),
            onSubstitute: () => _openSubstituteSelectorFor(originalIdx),
            onQtyChanged: (v) => _updateQuantity(originalIdx, v),
            onTargetQtyChanged: (delta) => _updateTargetQuantity(originalIdx, delta),
          ));
        } else {
          final investAmount = double.tryParse(_amountController.text) ?? 0.0;
          final allocated = _allocatedUnits(item, investAmount);
          rows.add(CustomizeConstituentRowDesktop(
            item: item,
            hasCalculated: _hasCalculated || !_isCalculating,
            investedText: CustomizeBasketFormatters.investedText(item),
            investmentAmount: investAmount,
            customWeightPercent: _customWeightFor(item, investAmount),
            allocatedUnits: allocated,
            baseTargetQuantity: BasketAllocationMath.baseTargetQuantity(item, investAmount),
            gapVsEtf: BasketAllocationMath.gapUnitsVsEtf(item, investAmount),
            canIncrease: BasketAllocationMath.canIncreaseAllocation(
              item,
              investAmount,
              manualOverrideQty: _manualQtyOverrides[item.stockSymbol],
            ),
            canDecrease: BasketAllocationMath.canDecreaseAllocation(
              item,
              investAmount,
              manualOverrideQty: _manualQtyOverrides[item.stockSymbol],
            ),
            isExcluded: _excludedItems.contains(item.stockSymbol),
            originalIdx: originalIdx,
            onRemove: () => _removeItem(originalIdx),
            onAdd: () => _addItem(originalIdx),
            onAddGap: () => _openSubstituteSelectorFor(originalIdx, isGapFill: true),
            onSubstitute: () => _openSubstituteSelectorFor(originalIdx),
            onQtyChanged: (v) => _updateQuantity(originalIdx, v),
            onTargetQtyChanged: (delta) => _updateTargetQuantity(originalIdx, delta),
            onDirectTargetQtySet: (qty) => _setDirectTargetQuantity(originalIdx, qty),
            onDirectTargetQtyChanged: (qty) => _setDirectTargetQuantity(originalIdx, qty),
          ));
        }
      }
    }

    addGroup('Direct Match', BasketItemStatusTheme.heldGroupColor(context), directItems);
    addGroup('Substituted', BasketItemStatusTheme.substituteGroupColor(context), subItems);
    addGroup('Missing / Swap', BasketItemStatusTheme.missingGroupColor(context), missingItems);
    addGroup('Excluded', BasketItemStatusTheme.excludedGroupColor(context), excludedItems);

    return SliverPadding(
      padding: EdgeInsets.only(
        bottom: isMobile ? 140 : 8,
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
}
