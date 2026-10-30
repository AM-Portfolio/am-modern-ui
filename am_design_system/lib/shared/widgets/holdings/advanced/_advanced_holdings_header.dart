part of 'advanced_holdings_template.dart';

/// Header UI builder extension for [_AdvancedHoldingsTemplateState].
///
/// Extracted into a part file to keep [advanced_holdings_template.dart] within
/// the 600-line am-modularity limit while sharing the same Dart library scope
/// (all private state fields and helpers are directly accessible here).
extension _AdvancedHoldingsHeaderBuilder on _AdvancedHoldingsTemplateState {
  // ---------------------------------------------------------------------------
  // Entry point — wraps layout choice and secondary info row.
  // ---------------------------------------------------------------------------

  Widget _buildControlsHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) => constraints.maxWidth >= 900
            ? _buildDesktopFilterRow()
            : _buildNarrowFilterLayout(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop layout — single horizontal row.
  // ---------------------------------------------------------------------------

  static const double _controlHeight = 36;

  Widget _buildDesktopFilterRow() => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        child: Row(
          children: [
            _buildStatusPills(),
            const SizedBox(width: AppSpacing.sm),
            _buildViewModeToggle(),
            if (_hasPriceFreshnessLabel) ...[
              const SizedBox(width: AppSpacing.sm),
              _buildPriceFreshnessLabel(),
            ],
            const Spacer(),
            _buildFilterDropdown(
              leadIcon: Icons.public_outlined,
              label: 'Sector',
              currentValue: _selectedSector,
              allLabel: 'All Sectors',
              options: _availableSectors,
              onSelected: _onSectorChanged,
              labelMaxWidth: 220,
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterDropdown(
              leadIcon: Icons.bar_chart_rounded,
              label: 'Industry',
              currentValue: _selectedIndustry,
              allLabel: 'All Industries',
              options: _availableIndustries,
              onSelected: _onIndustryChanged,
              labelMaxWidth: 180,
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(width: 220, child: _buildSearchField()),
            const SizedBox(width: AppSpacing.sm),
            _buildResetButton(),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Narrow layout — single scroll row (status · view · Sector · Industry).
  // ---------------------------------------------------------------------------

  Widget _buildNarrowFilterLayout() => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _controlHeight,
              child: Row(
                children: [
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildStatusPills(),
                        const SizedBox(width: AppSpacing.sm),
                        _buildViewModeToggle(),
                        if (_hasPriceFreshnessLabel) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _buildPriceFreshnessLabel(),
                        ],
                        const SizedBox(width: AppSpacing.md),
                        _buildFilterDropdown(
                          leadIcon: Icons.public_outlined,
                          label: 'Sector',
                          currentValue: _selectedSector,
                          allLabel: 'All Sectors',
                          options: _availableSectors,
                          onSelected: _onSectorChanged,
                          labelMaxWidth: 200,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterDropdown(
                          leadIcon: Icons.bar_chart_rounded,
                          label: 'Industry',
                          currentValue: _selectedIndustry,
                          allLabel: 'All Industries',
                          options: _availableIndustries,
                          onSelected: _onIndustryChanged,
                          labelMaxWidth: 160,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildResetButton(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSearchField(),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Reusable control builders.
  // ---------------------------------------------------------------------------

  /// Shared shell for segmented control groups (status + view mode).
  BoxDecoration get _segmentGroupDecoration => BoxDecoration(
        color: _isDarkChrome
            ? context.glassOverlay(0.06)
            : _accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: context.borderColor),
      );

  /// Grouped `[All | Profit | Loss]` — same chrome as view toggle.
  Widget _buildStatusPills() {
    return SizedBox(
      height: _controlHeight,
      child: Container(
        decoration: _segmentGroupDecoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentButton(
              selected: _filterStatus == 'all',
              accent: _accent,
              onTap: () => _onFilterStatusChanged('all'),
              child: Text(
                'All',
                style: _segmentLabelStyle(
                  selected: _filterStatus == 'all',
                  accent: _accent,
                ),
              ),
            ),
            _buildSegmentButton(
              selected: _filterStatus == 'profit',
              accent: context.marketPositive,
              onTap: () => _onFilterStatusChanged('profit'),
              child: Text(
                'Profit',
                style: _segmentLabelStyle(
                  selected: _filterStatus == 'profit',
                  accent: context.marketPositive,
                ),
              ),
            ),
            _buildSegmentButton(
              selected: _filterStatus == 'loss',
              accent: context.marketNegative,
              onTap: () => _onFilterStatusChanged('loss'),
              child: Text(
                'Loss',
                style: _segmentLabelStyle(
                  selected: _filterStatus == 'loss',
                  accent: context.marketNegative,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `[Table | Card]` — same chrome/selection as status pills.
  Widget _buildViewModeToggle() {
    return SizedBox(
      height: _controlHeight,
      child: Container(
        decoration: _segmentGroupDecoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentButton(
              selected: _viewMode == 'table',
              accent: _accent,
              onTap: () => _onViewModeChanged('table'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.table_chart,
                    size: 15,
                    color: _viewMode == 'table'
                        ? _accent
                        : context.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Table',
                    style: _segmentLabelStyle(
                      selected: _viewMode == 'table',
                      accent: _accent,
                    ),
                  ),
                ],
              ),
            ),
            _buildSegmentButton(
              selected: _viewMode == 'card',
              accent: _accent,
              onTap: () => _onViewModeChanged('card'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dashboard,
                    size: 15,
                    color: _viewMode == 'card'
                        ? _accent
                        : context.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Card',
                    style: _segmentLabelStyle(
                      selected: _viewMode == 'card',
                      accent: _accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact dropdown — same height/radius as search + reset; full sector label.
  Widget _buildFilterDropdown({
    required IconData leadIcon,
    required String label,
    required String currentValue,
    required String allLabel,
    required List<String> options,
    required ValueChanged<String> onSelected,
    bool isExpanded = false,
    double labelMaxWidth = 160,
  }) {
    final isFiltered = currentValue != 'All';
    final triggerLabel = isFiltered ? currentValue : label;

    return SizedBox(
      height: _controlHeight,
      child: CustomDropdown<String>(
        value: currentValue,
        primaryColor: _accent,
        isExpanded: isExpanded,
        height: _controlHeight,
        borderRadius: AppRadii.sm,
        backgroundColor: isFiltered
            ? _accent.withValues(alpha: _isDarkChrome ? 0.14 : 0.08)
            : (_isDarkChrome
                ? context.glassOverlay(0.05)
                : context.surfaceColor),
        borderColor:
            isFiltered ? _accent.withValues(alpha: 0.55) : context.borderColor,
        menuMaxHeight: 320,
        menuMaxWidth: 300,
        leading: Icon(
          leadIcon,
          size: 14,
          color: isFiltered ? _accent : context.textTertiary,
        ),
        contentPadding: const EdgeInsets.only(left: 10, right: 6),
        selectedItemBuilder: (context, _) => ConstrainedBox(
          constraints: BoxConstraints(maxWidth: labelMaxWidth),
          child: Tooltip(
            message: isFiltered ? currentValue : label,
            waitDuration: const Duration(milliseconds: 400),
            child: Text(
              triggerLabel,
              style: TextStyle(
                fontSize: AppTypeScale.sm,
                fontWeight: isFiltered ? FontWeight.w600 : FontWeight.w500,
                color: isFiltered ? _accent : context.textSecondary,
                height: 1.1,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        items: options.map((opt) {
          final text = opt == 'All' ? allLabel : opt;
          return DropdownMenuItem<String>(
            value: opt,
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppTypeScale.sm,
                fontWeight:
                    opt == currentValue ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) onSelected(val);
        },
      ),
    );
  }

  /// Symbol / company name search field — matches control height/radius.
  Widget _buildSearchField() {
    return SizedBox(
      height: _controlHeight,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search symbol or company...',
          hintStyle: TextStyle(
            fontSize: AppTypeScale.sm,
            color: context.textTertiary,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 16,
            color: context.textTertiary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: AppSpacing.md,
          ),
          filled: true,
          fillColor: _isDarkChrome
              ? context.glassOverlay(0.05)
              : context.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: BorderSide(color: context.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: BorderSide(color: context.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: BorderSide(color: _accent),
          ),
          isDense: true,
        ),
        style: const TextStyle(fontSize: AppTypeScale.sm),
      ),
    );
  }

  /// Outlined Reset — same height/radius/border weight as dropdowns.
  Widget _buildResetButton() {
    final hasActiveFilters = _filterStatus != 'all' ||
        _selectedSector != 'All' ||
        _selectedIndustry != 'All' ||
        _searchQuery.isNotEmpty;

    return SizedBox(
      height: _controlHeight,
      child: OutlinedButton.icon(
        onPressed: _resetFilters,
        icon: Icon(
          Icons.refresh,
          size: 15,
          color: hasActiveFilters ? _accent : context.textTertiary,
        ),
        label: Text(
          'Reset',
          style: TextStyle(
            fontSize: AppTypeScale.sm,
            fontWeight: FontWeight.w600,
            color: hasActiveFilters ? _accent : context.textTertiary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _accent,
          backgroundColor: hasActiveFilters
              ? _accent.withValues(alpha: 0.08)
              : (_isDarkChrome
                  ? context.glassOverlay(0.05)
                  : Colors.transparent),
          side: BorderSide(
            color: hasActiveFilters
                ? _accent.withValues(alpha: 0.55)
                : context.borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
          minimumSize: const Size(0, _controlHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  bool get _hasPriceFreshnessLabel {
    final label = widget.priceFreshnessLabel;
    return label != null && label.isNotEmpty;
  }

  /// `As of …` stamp — sits beside Table/Card on the top control row.
  Widget _buildPriceFreshnessLabel() {
    return Text(
      widget.priceFreshnessLabel!,
      style: TextStyle(
        fontSize: AppTypeScale.sm,
        color: context.textSecondary,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared segment cell (status + view mode).
  // ---------------------------------------------------------------------------

  TextStyle _segmentLabelStyle({
    required bool selected,
    required Color accent,
  }) =>
      TextStyle(
        fontSize: AppTypeScale.sm,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? accent : context.textSecondary,
        height: 1.1,
      );

  Widget _buildSegmentButton({
    required bool selected,
    required Color accent,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm - 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: _isDarkChrome ? 0.20 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.sm - 2),
          border: selected
              ? Border.all(color: accent.withValues(alpha: 0.65))
              : null,
        ),
        child: child,
      ),
    );
  }
}
