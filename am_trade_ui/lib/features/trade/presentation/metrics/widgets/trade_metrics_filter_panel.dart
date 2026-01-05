import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../internal/domain/entities/metrics_filter_config.dart';
import '../../../internal/domain/entities/filter_criteria.dart';
import '../../widgets/filters/date_range_filter_group.dart';
import '../../widgets/filters/filter_group.dart';
import '../../widgets/filters/filter_group_card.dart';
import '../../widgets/filters/instrument_filter_group.dart';
import '../../widgets/filters/trade_characteristics_filter_group.dart';
import '../../widgets/filters/profit_loss_filter_group.dart';
import '../../widgets/filters/metric_type_filter_group.dart';
import '../../../internal/domain/enums/metric_types.dart';

enum MetricsFilterGroupType { dateRange, instrument, tradeCharacteristics, profitLoss, metricTypes }

/// Customized Filter Panel for Trade Metrics
class TradeMetricsFilterPanel extends ConsumerStatefulWidget {
  const TradeMetricsFilterPanel({
    required this.userId,
    required this.initialConfig,
    required this.onApplyFilter,
    super.key,
    this.onReset,
    this.availableMetricTypes = const [],
  });

  final String userId;
  final MetricsFilterConfig initialConfig;
  final Function(MetricsFilterConfig) onApplyFilter;
  final VoidCallback? onReset;
  final List<MetricTypes> availableMetricTypes;

  @override
  ConsumerState<TradeMetricsFilterPanel> createState() => _TradeMetricsFilterPanelState();
}

class _TradeMetricsFilterPanelState extends ConsumerState<TradeMetricsFilterPanel> with SingleTickerProviderStateMixin {
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
    _loadMetricTypesFilter(config);
  }

  bool _hasMetricTypeFilters(config) => config.metricTypes.isNotEmpty;

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

  void _addFilterGroup(MetricsFilterGroupType type) {
    setState(() {
      switch (type) {
        case MetricsFilterGroupType.dateRange:
          if (!_activeGroups.any((g) => g is DateRangeFilterGroup)) {
            _activeGroups.add(DateRangeFilterGroup(onChanged: (start, end) => setState(() {})));
          }
          break;
        case MetricsFilterGroupType.instrument:
          if (!_activeGroups.any((g) => g is InstrumentFilterGroup)) {
            _activeGroups.add(InstrumentFilterGroup(onChanged: () => setState(() {})));
          }
          break;
        case MetricsFilterGroupType.tradeCharacteristics:
          if (!_activeGroups.any((g) => g is TradeCharacteristicsFilterGroup)) {
            _activeGroups.add(TradeCharacteristicsFilterGroup(onChanged: () => setState(() {})));
          }
          break;
        case MetricsFilterGroupType.profitLoss:
          if (!_activeGroups.any((g) => g is ProfitLossFilterGroup)) {
            _activeGroups.add(ProfitLossFilterGroup(onChanged: () => setState(() {})));
          }
          break;
        case MetricsFilterGroupType.metricTypes:
          if (!_activeGroups.any((g) => g is MetricTypeFilterGroup)) {
            _activeGroups.add(MetricTypeFilterGroup(
              onChanged: () => setState(() {}), 
              availableTypes: widget.availableMetricTypes,
            ));
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
      metricTypes: _activeGroups.whereType<MetricTypeFilterGroup>().firstOrNull?.selectedTypes ?? [],
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

  void _loadMetricTypesFilter(MetricsFilterConfig config) {
    if (config.metricTypes.isNotEmpty) {
      final group = MetricTypeFilterGroup(
        onChanged: () => setState(() {}),
        availableTypes: widget.availableMetricTypes,
        initialSelection: List.from(config.metricTypes),
      );
      _activeGroups.add(group);
    }
  }

  int get _activeFilterCount => _activeGroups.where((g) => g.hasActiveFilters).length;

  bool _hasInstrumentFilters(InstrumentFilterCriteria? filters) {
    if (filters == null) return false;
    return filters.marketSegments.isNotEmpty ||
        filters.indexTypes.isNotEmpty ||
        filters.derivativeTypes.isNotEmpty ||
        filters.baseSymbols.isNotEmpty;
  }

  bool _hasTradeCharacteristics(TradeCharacteristicsFilter? filters) {
    if (filters == null) return false;
    return filters.directions.isNotEmpty ||
        filters.statuses.isNotEmpty ||
        filters.strategies.isNotEmpty ||
        filters.tags.isNotEmpty ||
        filters.minHoldingTimeHours != null ||
        filters.maxHoldingTimeHours != null;
  }

  bool _hasProfitLossFilters(ProfitLossFilter? filters) {
    if (filters == null) return false;
    return filters.minProfitLoss != null ||
        filters.maxProfitLoss != null ||
        filters.minPositionSize != null ||
        filters.maxPositionSize != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
                _isExpanded ? _animationController.forward() : _animationController.reverse();
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor.withOpacity(0.05), theme.primaryColor.withOpacity(0.02)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.tune_rounded, color: theme.primaryColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Data Filters',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (_activeGroups.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_activeFilterCount active',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (_activeGroups.isNotEmpty)
                          Text(
                            '${_activeGroups.length} group${_activeGroups.length > 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
                          ),
                      ],
                    ),
                    const Spacer(),
                    
                    // Action Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<MetricsFilterGroupType>(
                          itemBuilder: (context) => [
                            if (!_activeGroups.any((g) => g is DateRangeFilterGroup))
                              PopupMenuItem(
                                value: MetricsFilterGroupType.dateRange,
                                child: _buildMenuTile(Icons.date_range_rounded, 'Date Range', theme),
                              ),
                            if (!_activeGroups.any((g) => g is InstrumentFilterGroup))
                              PopupMenuItem(
                                value: MetricsFilterGroupType.instrument,
                                child: _buildMenuTile(Icons.candlestick_chart_rounded, 'Instruments', theme),
                              ),
                            if (!_activeGroups.any((g) => g is TradeCharacteristicsFilterGroup))
                              PopupMenuItem(
                                value: MetricsFilterGroupType.tradeCharacteristics,
                                child: _buildMenuTile(Icons.insights_rounded, 'Trade Characteristics', theme),
                              ),
                            if (!_activeGroups.any((g) => g is ProfitLossFilterGroup))
                              PopupMenuItem(
                                value: MetricsFilterGroupType.profitLoss,
                                child: _buildMenuTile(Icons.account_balance_wallet_rounded, 'Profit & Loss', theme),
                              ),
                            if (!_activeGroups.any((g) => g is MetricTypeFilterGroup))
                              PopupMenuItem(
                                value: MetricsFilterGroupType.metricTypes,
                                child: _buildMenuTile(Icons.category_rounded, 'Metric Types', theme),
                              ),
                            if (!_activeGroups.any((g) => g is MetricTypeFilterGroup))
                              PopupMenuItem(
                                value: MetricsFilterGroupType.metricTypes,
                                child: _buildMenuTile(Icons.category_rounded, 'Metric Types', theme),
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
                        const SizedBox(width: 8),
                        RotationTransition(
                          turns: _rotationAnimation,
                          child: Icon(Icons.expand_more_rounded, size: 20, color: theme.hintColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Animated Content
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [_buildFilterGroupsContent(theme)],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
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

  Widget _buildFilterGroupsContent(ThemeData theme) {
    if (_activeGroups.isEmpty) {
      return _buildEmptyState(theme);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        return isMobile 
          ? Wrap(spacing: 8, runSpacing: 8, children: _activeGroups.asMap().entries.map((e) => SizedBox(width: constraints.maxWidth, child: _buildFilterGroupCard(e.key, e.value))).toList())
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: _activeGroups.asMap().entries.map((e) => Expanded(child: Padding(padding: EdgeInsets.only(left: e.key > 0 ? 6 : 0), child: _buildFilterGroupCard(e.key, e.value)))).toList());
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
      ],
    ),
  );
}
