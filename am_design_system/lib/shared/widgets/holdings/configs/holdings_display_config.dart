import 'package:am_design_system/shared/models/holding.dart';
import 'package:am_design_system/shared/widgets/holdings/core/holdings_selector_core.dart';

/// Configuration for holdings display
class HoldingsDisplayConfig {
  const HoldingsDisplayConfig({
    this.showSummary = true,
    this.showPagination = true,
    this.showSearch = true,
    this.showSortControls = true,
    this.showViewModeSelector = true,
    this.showSectorFilter = true,
    this.showChangeTypeSelector = true,
    this.showDisplayFormatSelector = true,
    this.itemsPerPage = 25,
    this.defaultSortBy = HoldingsSortBy.currentValue,
    this.defaultDisplayFormat = HoldingsDisplayFormat.value,
    this.defaultChangeType = HoldingsChangeType.total,
    this.defaultViewMode = HoldingsViewMode.table,
    this.defaultSortAscending = false,
    this.enableRowSelection = false,
    this.enableExport = false,
    this.enableRefresh = true,
    this.compactMode = false,
  });

  final bool showSummary;
  final bool showPagination;
  final bool showSearch;
  final bool showSortControls;
  final bool showViewModeSelector;
  final bool showSectorFilter;
  final bool showChangeTypeSelector;
  final bool showDisplayFormatSelector;
  final int itemsPerPage;
  final HoldingsSortBy defaultSortBy;
  final HoldingsDisplayFormat defaultDisplayFormat;
  final HoldingsChangeType defaultChangeType;
  final HoldingsViewMode defaultViewMode;
  final bool defaultSortAscending;
  final bool enableRowSelection;
  final bool enableExport;
  final bool enableRefresh;
  final bool compactMode;

  /// Web configuration (feature-rich)
  factory HoldingsDisplayConfig.web() => const HoldingsDisplayConfig(
        showSummary: true,
        showPagination: true,
        showSearch: true,
        showSortControls: true,
        showViewModeSelector: true,
        showSectorFilter: true,
        showChangeTypeSelector: true,
        showDisplayFormatSelector: true,
        itemsPerPage: 50,
        defaultViewMode: HoldingsViewMode.table,
        enableRowSelection: true,
        enableExport: true,
        enableRefresh: true,
        compactMode: false,
      );

  /// Mobile configuration (simplified)
  factory HoldingsDisplayConfig.mobile() => const HoldingsDisplayConfig(
        showSummary: false,
        showPagination: false,
        showSearch: false,
        showSortControls: true,
        showViewModeSelector: false,
        showSectorFilter: false,
        showChangeTypeSelector: true,
        showDisplayFormatSelector: true,
        itemsPerPage: 20,
        defaultViewMode: HoldingsViewMode.card,
        enableRowSelection: false,
        enableExport: false,
        enableRefresh: true,
        compactMode: true,
      );

  /// Minimal configuration (dashboard widget)
  factory HoldingsDisplayConfig.minimal() => const HoldingsDisplayConfig(
        showSummary: false,
        showPagination: false,
        showSearch: false,
        showSortControls: false,
        showViewModeSelector: false,
        showSectorFilter: false,
        showChangeTypeSelector: false,
        showDisplayFormatSelector: false,
        itemsPerPage: 10,
        defaultViewMode: HoldingsViewMode.card,
        enableRowSelection: false,
        enableExport: false,
        enableRefresh: false,
        compactMode: true,
      );

  HoldingsDisplayConfig copyWith({
    bool? showSummary,
    bool? showPagination,
    bool? showSearch,
    bool? showSortControls,
    bool? showViewModeSelector,
    bool? showSectorFilter,
    bool? showChangeTypeSelector,
    bool? showDisplayFormatSelector,
    int? itemsPerPage,
    HoldingsSortBy? defaultSortBy,
    HoldingsDisplayFormat? defaultDisplayFormat,
    HoldingsChangeType? defaultChangeType,
    HoldingsViewMode? defaultViewMode,
    bool? defaultSortAscending,
    bool? enableRowSelection,
    bool? enableExport,
    bool? enableRefresh,
    bool? compactMode,
  }) =>
      HoldingsDisplayConfig(
        showSummary: showSummary ?? this.showSummary,
        showPagination: showPagination ?? this.showPagination,
        showSearch: showSearch ?? this.showSearch,
        showSortControls: showSortControls ?? this.showSortControls,
        showViewModeSelector: showViewModeSelector ?? this.showViewModeSelector,
        showSectorFilter: showSectorFilter ?? this.showSectorFilter,
        showChangeTypeSelector:
            showChangeTypeSelector ?? this.showChangeTypeSelector,
        showDisplayFormatSelector:
            showDisplayFormatSelector ?? this.showDisplayFormatSelector,
        itemsPerPage: itemsPerPage ?? this.itemsPerPage,
        defaultSortBy: defaultSortBy ?? this.defaultSortBy,
        defaultDisplayFormat: defaultDisplayFormat ?? this.defaultDisplayFormat,
        defaultChangeType: defaultChangeType ?? this.defaultChangeType,
        defaultViewMode: defaultViewMode ?? this.defaultViewMode,
        defaultSortAscending: defaultSortAscending ?? this.defaultSortAscending,
        enableRowSelection: enableRowSelection ?? this.enableRowSelection,
        enableExport: enableExport ?? this.enableExport,
        enableRefresh: enableRefresh ?? this.enableRefresh,
        compactMode: compactMode ?? this.compactMode,
      );
}
