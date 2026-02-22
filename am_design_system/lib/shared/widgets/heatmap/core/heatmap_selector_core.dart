import 'package:flutter/foundation.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/core/utils/common_logger.dart';

import '../../selectors/selectors.dart';

/// Core logic for heatmap selector functionality
/// Handles state management, validation, and business logic independent of UI
class HeatmapSelectorCore extends ChangeNotifier {
  HeatmapSelectorCore({
    TimeFrame? initialTimeFrame,
    MetricType? initialMetric,
    SectorType? initialSector,
    MarketCapType? initialMarketCap,
    HeatmapLayoutType? initialLayout,
    this.availableTimeFrames,
    this.availableMetrics,
    this.availableSectors,
    this.availableMarketCaps,
    this.availableLayouts,
    this.onTimeFrameChanged,
    this.onMetricChanged,
    this.onSectorChanged,
    this.onMarketCapChanged,
    this.onLayoutChanged,
    this.onFiltersChanged,
  }) {
    _selectedTimeFrame = initialTimeFrame ?? TimeFrame.oneMonth;
    _selectedMetric = initialMetric ?? MetricType.changePercent;
    _selectedSector = initialSector ?? SectorType.all;
    _selectedMarketCap = initialMarketCap ?? MarketCapType.all;
    _selectedLayout = initialLayout ?? HeatmapLayoutType.treemap;

    CommonLogger.debug(
      'HeatmapSelectorCore: initialized',
      tag: 'Heatmap.Selector.Core',
    );
  }

  // Private state
  late TimeFrame _selectedTimeFrame;
  late MetricType _selectedMetric;
  late SectorType _selectedSector;
  late MarketCapType _selectedMarketCap;
  late HeatmapLayoutType _selectedLayout;

  // Available options
  final List<TimeFrame>? availableTimeFrames;
  final List<MetricType>? availableMetrics;
  final List<SectorType>? availableSectors;
  final List<MarketCapType>? availableMarketCaps;
  final List<HeatmapLayoutType>? availableLayouts;

  // Callbacks
  final ValueChanged<TimeFrame>? onTimeFrameChanged;
  final ValueChanged<MetricType>? onMetricChanged;
  final ValueChanged<SectorType>? onSectorChanged;
  final ValueChanged<MarketCapType>? onMarketCapChanged;
  final ValueChanged<HeatmapLayoutType>? onLayoutChanged;
  final Function({
    TimeFrame? timeFrame,
    MetricType? metric,
    SectorType? sector,
    MarketCapType? marketCap,
    HeatmapLayoutType? layout,
  })?
  onFiltersChanged;

  // Getters for current state
  TimeFrame get selectedTimeFrame => _selectedTimeFrame;
  MetricType get selectedMetric => _selectedMetric;
  SectorType get selectedSector => _selectedSector;
  MarketCapType get selectedMarketCap => _selectedMarketCap;
  HeatmapLayoutType get selectedLayout => _selectedLayout;

  // Getters for available options with defaults
  List<TimeFrame> get timeFrameOptions =>
      availableTimeFrames ??
      [
        TimeFrame.oneDay,
        TimeFrame.oneWeek,
        TimeFrame.oneMonth,
        TimeFrame.threeMonths,
        TimeFrame.oneYear,
      ];

  List<MetricType> get metricOptions =>
      availableMetrics ?? MetricType.heatmapMetrics;

  List<SectorType> get sectorOptions =>
      availableSectors ??
      [
        SectorType.all,
        SectorType.technology,
        SectorType.healthcare,
        SectorType.finance,
      ];

  List<MarketCapType> get marketCapOptions =>
      availableMarketCaps ??
      [
        MarketCapType.all,
        MarketCapType.largeCap,
        MarketCapType.midCap,
        MarketCapType.smallCap,
      ];

  List<HeatmapLayoutType> get layoutOptions =>
      availableLayouts ??
      [
        HeatmapLayoutType.treemap,
        HeatmapLayoutType.grid,
        HeatmapLayoutType.list,
      ];

  // State update methods
  void updateTimeFrame(TimeFrame timeFrame) {
    if (_selectedTimeFrame == timeFrame) return;

    _selectedTimeFrame = timeFrame;
    notifyListeners();

    CommonLogger.debug(
      'Core timeframe changed: ${timeFrame.code}',
      tag: 'Heatmap.Selector.Core',
    );

    onTimeFrameChanged?.call(timeFrame);
    _notifyFiltersChanged();
  }

  void updateMetric(MetricType metric) {
    if (_selectedMetric == metric) return;

    _selectedMetric = metric;
    notifyListeners();

    CommonLogger.debug(
      'Core metric changed: ${metric.shortName}',
      tag: 'Heatmap.Selector.Core',
    );

    onMetricChanged?.call(metric);
    _notifyFiltersChanged();
  }

  void updateSector(SectorType sector) {
    if (_selectedSector == sector) return;

    _selectedSector = sector;
    notifyListeners();

    CommonLogger.debug(
      'Core sector changed: ${sector.name}',
      tag: 'Heatmap.Selector.Core',
    );

    onSectorChanged?.call(sector);
    _notifyFiltersChanged();
  }

  void updateMarketCap(MarketCapType marketCap) {
    if (_selectedMarketCap == marketCap) return;

    _selectedMarketCap = marketCap;
    notifyListeners();

    CommonLogger.debug(
      'Core market cap changed: ${marketCap.name}',
      tag: 'Heatmap.Selector.Core',
    );

    onMarketCapChanged?.call(marketCap);
    _notifyFiltersChanged();
  }

  void updateLayout(HeatmapLayoutType layout) {
    if (_selectedLayout == layout) return;

    _selectedLayout = layout;
    notifyListeners();

    CommonLogger.debug(
      'Core layout changed: ${layout.displayName}',
      tag: 'Heatmap.Selector.Core',
    );

    onLayoutChanged?.call(layout);
    _notifyFiltersChanged();
  }

  void resetFilters() {
    _selectedTimeFrame = TimeFrame.oneMonth;
    _selectedMetric = MetricType.changePercent;
    _selectedSector = SectorType.all;
    _selectedMarketCap = MarketCapType.all;
    _selectedLayout = HeatmapLayoutType.treemap;

    notifyListeners();

    CommonLogger.debug('Core filters reset', tag: 'Heatmap.Selector.Core');
    _notifyFiltersChanged();
  }

  void _notifyFiltersChanged() {
    onFiltersChanged?.call(
      timeFrame: _selectedTimeFrame,
      metric: _selectedMetric,
      sector: _selectedSector,
      marketCap: _selectedMarketCap,
      layout: _selectedLayout,
    );
  }

  // Validation methods
  bool isValidTimeFrame(TimeFrame timeFrame) =>
      timeFrameOptions.contains(timeFrame);

  bool isValidMetric(MetricType metric) => metricOptions.contains(metric);

  bool isValidSector(SectorType sector) => sectorOptions.contains(sector);

  bool isValidMarketCap(MarketCapType marketCap) =>
      marketCapOptions.contains(marketCap);

  bool isValidLayout(HeatmapLayoutType layout) =>
      layoutOptions.contains(layout);

  // Bulk update methods for performance
  void updateFilters({
    TimeFrame? timeFrame,
    MetricType? metric,
    SectorType? sector,
    MarketCapType? marketCap,
    HeatmapLayoutType? layout,
  }) {
    var hasChanges = false;

    if (timeFrame != null && _selectedTimeFrame != timeFrame) {
      _selectedTimeFrame = timeFrame;
      hasChanges = true;
    }

    if (metric != null && _selectedMetric != metric) {
      _selectedMetric = metric;
      hasChanges = true;
    }

    if (sector != null && _selectedSector != sector) {
      _selectedSector = sector;
      hasChanges = true;
    }

    if (marketCap != null && _selectedMarketCap != marketCap) {
      _selectedMarketCap = marketCap;
      hasChanges = true;
    }

    if (layout != null && _selectedLayout != layout) {
      _selectedLayout = layout;
      hasChanges = true;
    }

    if (hasChanges) {
      notifyListeners();
      _notifyFiltersChanged();
    }
  }

  // Export current state
  Map<String, dynamic> exportState() => {
    'timeFrame': _selectedTimeFrame,
    'metric': _selectedMetric,
    'sector': _selectedSector,
    'marketCap': _selectedMarketCap,
    'layout': _selectedLayout,
  };

  @override
  void dispose() {
    CommonLogger.debug(
      'HeatmapSelectorCore: disposed',
      tag: 'Heatmap.Selector.Core',
    );
    super.dispose();
  }
}
