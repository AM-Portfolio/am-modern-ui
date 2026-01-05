import 'package:flutter/foundation.dart';
import 'package:am_design_system/shared/models/holding.dart';
import 'package:am_design_system/core/utils/common_logger.dart';

/// HoldingsViewMode is specific to selector/UI, so keeping it here or moving to a config file?
/// Let's keep it here for now if it's not in holding.dart
/// Wait, holding.dart is for data model. ViewMode is UI config.
enum HoldingsViewMode {
  table('Table'),
  card('Card'),
  detailed('Detailed');

  const HoldingsViewMode(this.displayName);
  final String displayName;
}

/// Core logic for holdings selector functionality
/// Handles state management, validation, and business logic independent of UI
class HoldingsSelectorCore extends ChangeNotifier {
  HoldingsSelectorCore({
    HoldingsSortBy? initialSortBy,
    HoldingsDisplayFormat? initialDisplayFormat,
    HoldingsChangeType? initialChangeType,
    HoldingsViewMode? initialViewMode,
    bool? initialSortAscending,
    String? initialSectorFilter,
    this.onSortByChanged,
    this.onDisplayFormatChanged,
    this.onChangeTypeChanged,
    this.onViewModeChanged,
    this.onSortOrderChanged,
    this.onSectorFilterChanged,
    this.onFiltersChanged,
  }) {
    _selectedSortBy = initialSortBy ?? HoldingsSortBy.currentValue;
    _selectedDisplayFormat = initialDisplayFormat ?? HoldingsDisplayFormat.value;
    _selectedChangeType = initialChangeType ?? HoldingsChangeType.total;
    _selectedViewMode = initialViewMode ?? HoldingsViewMode.table;
    _sortAscending = initialSortAscending ?? false;
    _sectorFilter = initialSectorFilter ?? 'All';

    CommonLogger.debug(
      'HoldingsSelectorCore: initialized',
      tag: 'Holdings.Selector.Core',
    );
  }

  // Private state
  late HoldingsSortBy _selectedSortBy;
  late HoldingsDisplayFormat _selectedDisplayFormat;
  late HoldingsChangeType _selectedChangeType;
  late HoldingsViewMode _selectedViewMode;
  late bool _sortAscending;
  late String _sectorFilter;

  // Callbacks
  final ValueChanged<HoldingsSortBy>? onSortByChanged;
  final ValueChanged<HoldingsDisplayFormat>? onDisplayFormatChanged;
  final ValueChanged<HoldingsChangeType>? onChangeTypeChanged;
  final ValueChanged<HoldingsViewMode>? onViewModeChanged;
  final ValueChanged<bool>? onSortOrderChanged;
  final ValueChanged<String>? onSectorFilterChanged;
  final Function({
    HoldingsSortBy? sortBy,
    HoldingsDisplayFormat? displayFormat,
    HoldingsChangeType? changeType,
    HoldingsViewMode? viewMode,
    bool? sortAscending,
    String? sectorFilter,
  })? onFiltersChanged;

  // Getters for current state
  HoldingsSortBy get selectedSortBy => _selectedSortBy;
  HoldingsDisplayFormat get selectedDisplayFormat => _selectedDisplayFormat;
  HoldingsChangeType get selectedChangeType => _selectedChangeType;
  HoldingsViewMode get selectedViewMode => _selectedViewMode;
  bool get sortAscending => _sortAscending;
  String get sectorFilter => _sectorFilter;

  // State update methods
  void updateSortBy(HoldingsSortBy sortBy) {
    if (_selectedSortBy == sortBy) return;

    _selectedSortBy = sortBy;
    notifyListeners();

    CommonLogger.debug(
      'Core sort by changed: ${sortBy.displayName}',
      tag: 'Holdings.Selector.Core',
    );

    onSortByChanged?.call(sortBy);
    _notifyFiltersChanged();
  }

  void updateDisplayFormat(HoldingsDisplayFormat format) {
    if (_selectedDisplayFormat == format) return;

    _selectedDisplayFormat = format;
    notifyListeners();

    CommonLogger.debug(
      'Core display format changed: ${format.displayName}',
      tag: 'Holdings.Selector.Core',
    );

    onDisplayFormatChanged?.call(format);
    _notifyFiltersChanged();
  }

  void updateChangeType(HoldingsChangeType changeType) {
    if (_selectedChangeType == changeType) return;

    _selectedChangeType = changeType;
    notifyListeners();

    CommonLogger.debug(
      'Core change type changed: ${changeType.displayName}',
      tag: 'Holdings.Selector.Core',
    );

    onChangeTypeChanged?.call(changeType);
    _notifyFiltersChanged();
  }

  void updateViewMode(HoldingsViewMode viewMode) {
    if (_selectedViewMode == viewMode) return;

    _selectedViewMode = viewMode;
    notifyListeners();

    CommonLogger.debug(
      'Core view mode changed: ${viewMode.displayName}',
      tag: 'Holdings.Selector.Core',
    );

    onViewModeChanged?.call(viewMode);
    _notifyFiltersChanged();
  }

  void updateSortOrder(bool ascending) {
    if (_sortAscending == ascending) return;

    _sortAscending = ascending;
    notifyListeners();

    CommonLogger.debug(
      'Core sort order changed: ${ascending ? "ascending" : "descending"}',
      tag: 'Holdings.Selector.Core',
    );

    onSortOrderChanged?.call(ascending);
    _notifyFiltersChanged();
  }

  void updateSectorFilter(String sector) {
    if (_sectorFilter == sector) return;

    _sectorFilter = sector;
    notifyListeners();

    CommonLogger.debug(
      'Core sector filter changed: $sector',
      tag: 'Holdings.Selector.Core',
    );

    onSectorFilterChanged?.call(sector);
    _notifyFiltersChanged();
  }

  void toggleSortOrder() {
    updateSortOrder(!_sortAscending);
  }

  void resetFilters() {
    _selectedSortBy = HoldingsSortBy.currentValue;
    _selectedDisplayFormat = HoldingsDisplayFormat.value;
    _selectedChangeType = HoldingsChangeType.total;
    _selectedViewMode = HoldingsViewMode.table;
    _sortAscending = false;
    _sectorFilter = 'All';

    notifyListeners();

    CommonLogger.debug('Core filters reset', tag: 'Holdings.Selector.Core');
    _notifyFiltersChanged();
  }

  void _notifyFiltersChanged() {
    onFiltersChanged?.call(
      sortBy: _selectedSortBy,
      displayFormat: _selectedDisplayFormat,
      changeType: _selectedChangeType,
      viewMode: _selectedViewMode,
      sortAscending: _sortAscending,
      sectorFilter: _sectorFilter,
    );
  }

  // Bulk update for performance
  void updateFilters({
    HoldingsSortBy? sortBy,
    HoldingsDisplayFormat? displayFormat,
    HoldingsChangeType? changeType,
    HoldingsViewMode? viewMode,
    bool? sortAscending,
    String? sectorFilter,
  }) {
    var hasChanges = false;

    if (sortBy != null && _selectedSortBy != sortBy) {
      _selectedSortBy = sortBy;
      hasChanges = true;
    }

    if (displayFormat != null && _selectedDisplayFormat != displayFormat) {
      _selectedDisplayFormat = displayFormat;
      hasChanges = true;
    }

    if (changeType != null && _selectedChangeType != changeType) {
      _selectedChangeType = changeType;
      hasChanges = true;
    }

    if (viewMode != null && _selectedViewMode != viewMode) {
      _selectedViewMode = viewMode;
      hasChanges = true;
    }

    if (sortAscending != null && _sortAscending != sortAscending) {
      _sortAscending = sortAscending;
      hasChanges = true;
    }

    if (sectorFilter != null && _sectorFilter != sectorFilter) {
      _sectorFilter = sectorFilter;
      hasChanges = true;
    }

    if (hasChanges) {
      notifyListeners();
      _notifyFiltersChanged();
    }
  }

  // Export current state
  Map<String, dynamic> exportState() => {
        'sortBy': _selectedSortBy,
        'displayFormat': _selectedDisplayFormat,
        'changeType': _selectedChangeType,
        'viewMode': _selectedViewMode,
        'sortAscending': _sortAscending,
        'sectorFilter': _sectorFilter,
      };

  @override
  void dispose() {
    CommonLogger.debug(
      'HoldingsSelectorCore: disposed',
      tag: 'Holdings.Selector.Core',
    );
    super.dispose();
  }
}
