import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../internal/domain/entities/metrics_filter_config.dart';
import '../cubit/favorite_filter/favorite_filter_cubit.dart';
import 'favorite_filter_panel.dart';
import 'filters/date_range_filter_group.dart';
import 'filters/filter_group.dart';
import 'filters/filter_group_card.dart';
import 'filters/instrument_filter_group.dart';
import 'filters/profit_loss_filter_group.dart';
import 'filters/trade_characteristics_filter_group.dart';

enum FilterGroupType { dateRange, instrument, tradeCharacteristics, profitLoss }

/// Clean filter panel for trade holdings - without favorite filter logic
class FilterPanel extends ConsumerStatefulWidget {
  const FilterPanel({
    required this.userId,
    required this.initialConfig,
    required this.onApplyFilter,
    super.key,
    this.onReset,
  });

  final String userId;
  final MetricsFilterConfig initialConfig;
  final Function(MetricsFilterConfig) onApplyFilter;
  final VoidCallback? onReset;

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<FilterPanel> with SingleTickerProviderStateMixin {
  final List<FilterGroup> _activeGroups = [];
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _initializeFromConfig();

    if (_activeGroups.isNotEmpty) {
      _isExpanded = true;
      _animationController.forward();
    }
  }

  void _initializeFromConfig() {
    final config = widget.initialConfig;
    _loadDateRangeFilter(config);
    _loadInstrumentFilter(config);
    _loadTradeCharacteristicsFilter(config);
    _loadProfitLossFilter(config);
  }

  bool _hasInstrumentFilters(filter) =>
      filter.marketSegments.isNotEmpty ||
      filter.indexTypes.isNotEmpty ||
      filter.derivativeTypes.isNotEmpty ||
      filter.baseSymbols.isNotEmpty;

  bool _hasTradeCharacteristics(filter) =>
      filter.directions.isNotEmpty ||
      filter.statuses.isNotEmpty ||
      filter.strategies.isNotEmpty ||
      filter.tags.isNotEmpty ||
      filter.minHoldingTimeHours != null ||
      filter.maxHoldingTimeHours != null;

  bool _hasProfitLossFilters(filter) =>
      filter.minProfitLoss != null ||
      filter.maxProfitLoss != null ||
      filter.minPositionSize != null ||
      filter.maxPositionSize != null;

  @override
  void dispose() {
    _animationController.dispose();
    for (final group in _activeGroups) {
      if (group is InstrumentFilterGroup) {
        group.dispose();
      } else if (group is TradeCharacteristicsFilterGroup) {
        group.dispose();
      } else if (group is ProfitLossFilterGroup) {
        group.dispose();
      }
    }
    super.dispose();
  }

  void _addFilterGroup(FilterGroupType type) {
    setState(() {
      switch (type) {
        case FilterGroupType.dateRange:
          if (!_activeGroups.any((g) => g is DateRangeFilterGroup)) {
            _activeGroups.add(DateRangeFilterGroup(onChanged: (start, end) => setState(() {})));
          }
          break;
        case FilterGroupType.instrument:
          if (!_activeGroups.any((g) => g is InstrumentFilterGroup)) {
            _activeGroups.add(InstrumentFilterGroup(onChanged: () => setState(() {})));
          }
          break;
        case FilterGroupType.tradeCharacteristics:
          if (!_activeGroups.any((g) => g is TradeCharacteristicsFilterGroup)) {
            _activeGroups.add(TradeCharacteristicsFilterGroup(onChanged: () => setState(() {})));
          }
          break;
        case FilterGroupType.profitLoss:
          if (!_activeGroups.any((g) => g is ProfitLossFilterGroup)) {
            _activeGroups.add(ProfitLossFilterGroup(onChanged: () => setState(() {})));
          }
          break;
      }

      if (!_isExpanded) {
        _isExpanded = true;
        _animationController.forward();
      }
    });
  }

  void _removeFilterGroup(int index) {
    setState(() {
      final group = _activeGroups[index];
      if (group is InstrumentFilterGroup) {
        group.dispose();
      } else if (group is TradeCharacteristicsFilterGroup) {
        group.dispose();
      } else if (group is ProfitLossFilterGroup) {
        group.dispose();
      }
      _activeGroups.removeAt(index);
    });
  }

  void _applyFilters() {
    final config = MetricsFilterConfig(
      dateRange: _activeGroups.whereType<DateRangeFilterGroup>().firstOrNull?.toFilterCriteria(),
      instrumentFilters: _activeGroups.whereType<InstrumentFilterGroup>().firstOrNull?.toFilterCriteria(),
      tradeCharacteristics: _activeGroups.whereType<TradeCharacteristicsFilterGroup>().firstOrNull?.toFilterCriteria(),
      profitLossFilters: _activeGroups.whereType<ProfitLossFilterGroup>().firstOrNull?.toFilterCriteria(),
    );

    widget.onApplyFilter(config);
  }

  void _resetAllFilters() {
    setState(() {
      for (final group in _activeGroups) {
        group.reset();
      }
      _activeGroups.clear();
    });
    widget.onReset?.call();
  }

  void _loadDateRangeFilter(MetricsFilterConfig config) {
    if (config.dateRange != null) {
      _activeGroups.add(
        DateRangeFilterGroup(
          startDate: config.dateRange!.startDate,
          endDate: config.dateRange!.endDate,
          onChanged: (start, end) => setState(() {}),
        ),
      );
    }
  }

  void _loadInstrumentFilter(MetricsFilterConfig config) {
    if (config.instrumentFilters != null && _hasInstrumentFilters(config.instrumentFilters)) {
      final group = InstrumentFilterGroup(onChanged: () => setState(() {}));
      group.selectedSegments = List.from(config.instrumentFilters!.marketSegments);
      group.selectedIndexTypes = List.from(config.instrumentFilters!.indexTypes);
      group.selectedDerivativeTypes = List.from(config.instrumentFilters!.derivativeTypes);
      group.symbolsController.text = config.instrumentFilters!.baseSymbols.join(', ');
      _activeGroups.add(group);
    }
  }

  void _loadTradeCharacteristicsFilter(MetricsFilterConfig config) {
    if (config.tradeCharacteristics != null && _hasTradeCharacteristics(config.tradeCharacteristics)) {
      final group = TradeCharacteristicsFilterGroup(onChanged: () => setState(() {}));
      group.selectedDirections = List.from(config.tradeCharacteristics!.directions);
      group.selectedStatuses = List.from(config.tradeCharacteristics!.statuses);
      group.strategiesController.text = config.tradeCharacteristics!.strategies.join(', ');
      group.tagsController.text = config.tradeCharacteristics!.tags.join(', ');
      if (config.tradeCharacteristics!.minHoldingTimeHours != null) {
        group.minHoldingHoursController.text = config.tradeCharacteristics!.minHoldingTimeHours.toString();
      }
      if (config.tradeCharacteristics!.maxHoldingTimeHours != null) {
        group.maxHoldingHoursController.text = config.tradeCharacteristics!.maxHoldingTimeHours.toString();
      }
      _activeGroups.add(group);
    }
  }

  void _loadProfitLossFilter(MetricsFilterConfig config) {
    if (config.profitLossFilters != null && _hasProfitLossFilters(config.profitLossFilters)) {
      final group = ProfitLossFilterGroup(onChanged: () => setState(() {}));
      if (config.profitLossFilters!.minProfitLoss != null) {
        group.minPnLController.text = config.profitLossFilters!.minProfitLoss.toString();
      }
      if (config.profitLossFilters!.maxProfitLoss != null) {
        group.maxPnLController.text = config.profitLossFilters!.maxProfitLoss.toString();
      }
      if (config.profitLossFilters!.minPositionSize != null) {
        group.minPositionSizeController.text = config.profitLossFilters!.minPositionSize.toString();
      }
      if (config.profitLossFilters!.maxPositionSize != null) {
        group.maxPositionSizeController.text = config.profitLossFilters!.maxPositionSize.toString();
      }
      _activeGroups.add(group);
    }
  }

  void _applyFavoriteFilter(MetricsFilterConfig config) {
    setState(() {
      _activeGroups.clear();
      _loadDateRangeFilter(config);
      _loadInstrumentFilter(config);
      _loadTradeCharacteristicsFilter(config);
      _loadProfitLossFilter(config);

      // Expand the panel if filters were added
      if (_activeGroups.isNotEmpty && !_isExpanded) {
        _isExpanded = true;
        _animationController.forward();
      }
    });
    widget.onApplyFilter(config);
  }

  void _showSaveDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final cubit = context.read<FavoriteFilterCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: AlertDialog(
          title: const Text('Save as Favorite'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Filter Name *',
                    hintText: 'e.g., My Trading Strategy',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Brief description of this filter',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Please enter a filter name')));
                  return;
                }

                final config = MetricsFilterConfig(
                  dateRange: _activeGroups.whereType<DateRangeFilterGroup>().firstOrNull?.toFilterCriteria(),
                  instrumentFilters: _activeGroups.whereType<InstrumentFilterGroup>().firstOrNull?.toFilterCriteria(),
                  tradeCharacteristics: _activeGroups
                      .whereType<TradeCharacteristicsFilterGroup>()
                      .firstOrNull
                      ?.toFilterCriteria(),
                  profitLossFilters: _activeGroups.whereType<ProfitLossFilterGroup>().firstOrNull?.toFilterCriteria(),
                );

                cubit.createFilter(
                  userId: widget.userId,
                  name: name,
                  filterConfig: config,
                  description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                );

                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Filter "$name" saved successfully')));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  int get _activeFilterCount => _activeGroups.where((g) => g.hasActiveFilters).length;

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AmFilterPanel(
      title: 'Filters',
      activeFilterCount: _activeFilterCount,
      isExpanded: _isExpanded,
      onExpandToggle: () {
        setState(() => _isExpanded = !_isExpanded);
        _isExpanded ? _animationController.forward() : _animationController.reverse();
      },
      headerActions: [
        // Favorite Filter Dropdown
        FavoriteFilterPanel(
          userId: widget.userId,
          onFilterSelected: (filter) => _applyFavoriteFilter(filter.filterConfig),
        ),
        const SizedBox(width: 12),
        
        // Add Filter Button
        PopupMenuButton<FilterGroupType>(
          itemBuilder: (context) => [
            if (!_activeGroups.any((g) => g is DateRangeFilterGroup))
              PopupMenuItem(
                value: FilterGroupType.dateRange,
                child: _buildMenuTile(Icons.date_range_rounded, 'Date Range', theme),
              ),
            if (!_activeGroups.any((g) => g is InstrumentFilterGroup))
              PopupMenuItem(
                value: FilterGroupType.instrument,
                child: _buildMenuTile(Icons.candlestick_chart_rounded, 'Instruments', theme),
              ),
            if (!_activeGroups.any((g) => g is TradeCharacteristicsFilterGroup))
              PopupMenuItem(
                value: FilterGroupType.tradeCharacteristics,
                child: _buildMenuTile(Icons.insights_rounded, 'Trade Characteristics', theme),
              ),
            if (!_activeGroups.any((g) => g is ProfitLossFilterGroup))
              PopupMenuItem(
                value: FilterGroupType.profitLoss,
                child: _buildMenuTile(Icons.account_balance_wallet_rounded, 'Profit & Loss', theme),
              ),
          ],
          onSelected: _addFilterGroup,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tooltip: 'Add Filter Group',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 16, color: theme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  'Add',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_activeGroups.isNotEmpty) ...[
          const SizedBox(width: 8),
          // Save as Favorite Button
          Tooltip(
            message: 'Save as favorite',
            child: InkWell(
              onTap: _showSaveDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Icon(Icons.bookmark_add_rounded, size: 18, color: Colors.amber[700]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Reset Button
          Tooltip(
            message: 'Reset all filters',
            child: InkWell(
              onTap: _resetAllFilters,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                ),
                child: Icon(Icons.refresh_rounded, size: 18, color: theme.colorScheme.error),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Apply Button
          FilledButton.icon(
            onPressed: _applyFilters,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Apply'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 32),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ],
      child: _buildFilterGroupsContent(theme),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, ThemeData theme) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: theme.primaryColor),
      ),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    ],
  );

  Widget _buildFilterGroupCard(int index, FilterGroup group) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: FilterGroupCard(key: ValueKey(group), filterGroup: group, onRemove: () => _removeFilterGroup(index)),
  );

  Widget _buildMobileLayout(double maxWidth) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _activeGroups.asMap().entries.map((entry) {
      final index = entry.key;
      final group = entry.value;
      return SizedBox(width: maxWidth, child: _buildFilterGroupCard(index, group));
    }).toList(),
  );

  Widget _buildDesktopLayout() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: _activeGroups.asMap().entries.map((entry) {
      final index = entry.key;
      final group = entry.value;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: index > 0 ? 6 : 0),
          child: _buildFilterGroupCard(index, group),
        ),
      );
    }).toList(),
  );

  Widget _buildFilterGroupsContent(ThemeData theme) {
    if (_activeGroups.isEmpty) {
      return _buildEmptyState(theme);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        return isMobile ? _buildMobileLayout(constraints.maxWidth) : _buildDesktopLayout();
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: theme.primaryColor.withOpacity(0.03),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.filter_alt_off_rounded, size: 32, color: theme.primaryColor.withOpacity(0.6)),
        ),
        const SizedBox(height: 12),
        Text(
          'No filter groups active',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.hintColor),
        ),
        const SizedBox(height: 4),
        Text(
          'Add filter groups to refine your holdings',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
