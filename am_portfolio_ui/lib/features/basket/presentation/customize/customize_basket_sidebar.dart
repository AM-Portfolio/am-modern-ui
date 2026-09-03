part of '../pages/manual_basket_creator_page.dart';

extension _ManualBasketCreatorPageSidebar on _ManualBasketCreatorPageState {
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
          CustomizeAllocationSummaryCard(
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
          _buildInvestmentSummaryCard(context, theme),
          const SizedBox(height: 12),
          Text(
            'Review & confirm from the bottom bar.',
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
      BuildContext context, ThemeData theme) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final available = widget.opportunity.remainingPortfolioValue ?? 0;
    final minRec = widget.opportunity.minimumInvestmentAmount ?? 50000.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BasketPanelStyles.insetPanel(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Investment Summary',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        BasketSummaryRow(
            label: 'Total Investment',
            value: '₹${amount.toStringAsFixed(0)}'),
        BasketSummaryRow(
            label: 'Available to Invest',
            value: '₹${available.toStringAsFixed(0)}'),
        BasketSummaryRow(
            label: 'Min. Recommended',
            value: '₹${minRec.toStringAsFixed(0)}'),
        if (_actualCost != null && _actualCost! > 0)
          BasketSummaryRow(
              label: 'Fresh Orders',
              value: '₹${_actualCost!.toStringAsFixed(0)}'),
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
      decoration: BasketPanelStyles.insetPanel(context),
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
        decoration: BasketPanelStyles.insetPanel(context),
        child: ExpansionTile(
          title: Text('Comparison',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          children: [
            SizedBox(
              height: 300,
              child: CustomizeBasketComparisonTab(
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
        decoration: BasketPanelStyles.insetPanel(context),
        child: ExpansionTile(
          title: Text('Sector Analysis',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          children: [
            SizedBox(
              height: 300,
              child: CustomizeSectorComparisonTab(
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
          leading: Icon(Icons.drafts_outlined,
              color: context.colors.actionPrimaryBg),
          title: const Text('Save draft'),
          enabled: _hasCalculated && !_hasStaleData && !_isCalculating,
          onTap: () {
            Navigator.of(ctx).pop();
            _saveDraft();
          },
        ),
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
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: DraggableScrollableSheet(
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
                const SizedBox(height: 12),
                _buildExpandableComparison(context, theme, displayItems),
              ]),
            ),
          ),
        ),
        );
      },
    );
  }
}
