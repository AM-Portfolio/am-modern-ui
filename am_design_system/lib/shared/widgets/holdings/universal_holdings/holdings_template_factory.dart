
import 'package:flutter/material.dart';

import 'package:am_design_system/shared/models/holding.dart';
import 'package:am_design_system/shared/widgets/holdings/core/holdings_selector_core.dart';
import 'package:am_design_system/core/utils/common_logger.dart';
import '../configs/holdings_display_config.dart';

import '../holdings_display_template.dart';

/// Template types for holdings display
enum HoldingsTemplateType {
  minimal,
  compact,
  full,
  adaptive,
}

/// Factory for creating holdings template components
/// Follows the pattern from UniversalHeatmapTemplateFactory
class HoldingsTemplateFactory {
  /// Create display template for holdings visualization
  static Widget createDisplayTemplate({
    required List<Holding> holdings,
    required HoldingsSelectorCore core,
    required bool isLoading,
    String? error,
    ValueChanged<Holding>? onHoldingTap,
  }) {
    CommonLogger.debug(
      'Creating holdings display template with viewMode=${core.selectedViewMode}, '
      'holdings=${holdings.length}, isLoading=$isLoading',
      tag: 'HoldingsTemplateFactory.Display',
    );

    return HoldingsDisplayTemplate(
      holdings: holdings,
      sortBy: core.selectedSortBy,
      sortAscending: core.sortAscending,
      displayFormat: core.selectedDisplayFormat,
      changeType: core.selectedChangeType,
      viewMode: core.selectedViewMode,
      isLoading: isLoading,
      error: error,
      onHoldingTap: onHoldingTap,
      sectorFilter: core.sectorFilter,
    );
  }

  /// Create selector widget for holdings filters
  static Widget? createSelectorWidget({
    required HoldingsDisplayConfig config,
    required HoldingsSelectorCore core,
  }) {
    if (!_shouldShowSelectors(config)) {
      CommonLogger.debug(
        'Skipping selector creation - no selectors enabled',
        tag: 'HoldingsTemplateFactory.Selector',
      );
      return null;
    }

    CommonLogger.debug(
      'Creating selector widget with filters enabled',
      tag: 'HoldingsTemplateFactory.Selector',
    );

    return _buildSelectorControls(config, core);
  }

  /// Build selector controls based on config
  static Widget _buildSelectorControls(
    HoldingsDisplayConfig config,
    HoldingsSelectorCore core,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (config.showChangeTypeSelector)
            _buildChangeTypeSelector(core),
          if (config.showDisplayFormatSelector)
            _buildDisplayFormatSelector(core),
          if (config.showSortControls) _buildSortControls(core),
          if (config.showViewModeSelector) _buildViewModeSelector(core),
          if (config.showSectorFilter) _buildSectorFilter(core),
        ],
      ),
    );
  }

  static Widget _buildChangeTypeSelector(HoldingsSelectorCore core) {
    return SegmentedButton<HoldingsChangeType>(
      segments: const [
        ButtonSegment(
          value: HoldingsChangeType.daily,
          label: Text('Daily'),
        ),
        ButtonSegment(
          value: HoldingsChangeType.total,
          label: Text('Total'),
        ),
      ],
      selected: {core.selectedChangeType},
      onSelectionChanged: (Set<HoldingsChangeType> newSelection) {
        core.updateChangeType(newSelection.first);
      },
    );
  }

  static Widget _buildDisplayFormatSelector(HoldingsSelectorCore core) {
    return SegmentedButton<HoldingsDisplayFormat>(
      segments: const [
        ButtonSegment(
          value: HoldingsDisplayFormat.value,
          label: Text('₹'),
        ),
        ButtonSegment(
          value: HoldingsDisplayFormat.percentage,
          label: Text('%'),
        ),
      ],
      selected: {core.selectedDisplayFormat},
      onSelectionChanged: (Set<HoldingsDisplayFormat> newSelection) {
        core.updateDisplayFormat(newSelection.first);
      },
    );
  }

  static Widget _buildSortControls(HoldingsSelectorCore core) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<HoldingsSortBy>(
          value: core.selectedSortBy,
          items: HoldingsSortBy.values
              .map(
                (sortBy) => DropdownMenuItem(
                  value: sortBy,
                  child: Text(sortBy.displayName),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) core.updateSortBy(value);
          },
        ),
        IconButton(
          icon: Icon(
            core.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
          ),
          onPressed: () => core.toggleSortOrder(),
        ),
      ],
    );
  }

  static Widget _buildViewModeSelector(HoldingsSelectorCore core) {
    return SegmentedButton<HoldingsViewMode>(
      segments: const [
        ButtonSegment(
          value: HoldingsViewMode.table,
          icon: Icon(Icons.table_chart),
        ),
        ButtonSegment(
          value: HoldingsViewMode.card,
          icon: Icon(Icons.view_agenda),
        ),
      ],
      selected: {core.selectedViewMode},
      onSelectionChanged: (Set<HoldingsViewMode> newSelection) {
        core.updateViewMode(newSelection.first);
      },
    );
  }

  static Widget _buildSectorFilter(HoldingsSelectorCore core) {
    return DropdownButton<String>(
      value: core.sectorFilter,
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All Sectors')),
        DropdownMenuItem(value: 'Technology', child: Text('Technology')),
        DropdownMenuItem(value: 'Healthcare', child: Text('Healthcare')),
        DropdownMenuItem(value: 'Finance', child: Text('Finance')),
        DropdownMenuItem(value: 'Energy', child: Text('Energy')),
      ],
      onChanged: (value) {
        if (value != null) core.updateSectorFilter(value);
      },
    );
  }

  /// Helper to check if selectors should be shown
  static bool _shouldShowSelectors(HoldingsDisplayConfig config) =>
      config.showChangeTypeSelector ||
      config.showDisplayFormatSelector ||
      config.showSortControls ||
      config.showViewModeSelector ||
      config.showSectorFilter;

  /// Create layout template based on template type
  static Widget createLayoutTemplate({
    required BuildContext context,
    required HoldingsTemplateType templateType,
    required HoldingsDisplayConfig config,
    required List<Holding> holdings,
    required HoldingsSelectorCore core,
    required Widget displayWidget,
    Widget? selectorWidget,
    String? title,
  }) {
    CommonLogger.debug(
      'Creating layout template: $templateType',
      tag: 'HoldingsTemplateFactory.Layout',
    );

    final effectiveTitle = title ?? 'Portfolio Holdings';

    switch (templateType) {
      case HoldingsTemplateType.minimal:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: displayWidget,
          ),
        );

      case HoldingsTemplateType.compact:
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectorWidget != null) selectorWidget,
              Expanded(child: displayWidget),
            ],
          ),
        );

      case HoldingsTemplateType.full:
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet),
                    const SizedBox(width: 8),
                    Text(
                      effectiveTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    if (config.enableRefresh)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          // Refresh logic
                        },
                      ),
                  ],
                ),
              ),
              if (selectorWidget != null) selectorWidget,
              Expanded(child: displayWidget),
            ],
          ),
        );

      case HoldingsTemplateType.adaptive:
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return createLayoutTemplate(
                context: context,
                templateType: HoldingsTemplateType.compact,
                config: config,
                holdings: holdings,
                core: core,
                displayWidget: displayWidget,
                selectorWidget: selectorWidget,
                title: title,
              );
            } else {
              return createLayoutTemplate(
                context: context,
                templateType: HoldingsTemplateType.full,
                config: config,
                holdings: holdings,
                core: core,
                displayWidget: displayWidget,
                selectorWidget: selectorWidget,
                title: title,
              );
            }
          },
        );
    }
  }
}
