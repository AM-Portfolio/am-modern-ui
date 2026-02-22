import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';
import '../../../../core/utils/common_logger.dart';
import '../../selectors/selectors.dart';
import '../configs/selector_config.dart';
import '../core/heatmap_selector_core.dart';
import '../../buttons/app_button.dart';
import '../../buttons/reset_button.dart';
import '../../containers/selector_container.dart';
import '../../inputs/custom_dropdown.dart';
import '../../display/pill_selector.dart';

/// Web-optimized heatmap selector with compact layouts
/// Maintains current web-friendly design while using the extracted core logic
class HeatmapSelectorWeb extends StatefulWidget {
  const HeatmapSelectorWeb({
    required this.core,
    super.key,
    this.showTimeFrame = true,
    this.showMetric = true,
    this.showSector = true,
    this.showMarketCap = true,
    this.showLayout = false,
    this.layout = SelectorLayoutType.compact,
    this.primaryColor,
    this.title,
    this.showResetButton = true,
  });

  final HeatmapSelectorCore core;
  final bool showTimeFrame;
  final bool showMetric;
  final bool showSector;
  final bool showMarketCap;
  final bool showLayout;
  final SelectorLayoutType layout;
  final Color? primaryColor;
  final String? title;
  final bool showResetButton;

  @override
  State<HeatmapSelectorWeb> createState() => _HeatmapSelectorWebState();
}

class _HeatmapSelectorWebState extends State<HeatmapSelectorWeb> {
  @override
  void initState() {
    super.initState();

    // Listen to core changes
    widget.core.addListener(_onCoreChanged);

    CommonLogger.debug(
      'HeatmapSelectorWeb: initialized with layout=${widget.layout}',
      tag: 'Heatmap.Selector.Web',
    );
  }

  @override
  void dispose() {
    widget.core.removeListener(_onCoreChanged);
    super.dispose();
  }

  void _onCoreChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.layout) {
      case SelectorLayoutType.compact:
        return _buildCompactLayout(context);
      case SelectorLayoutType.expanded:
        return _buildExpandedLayout(context);
      case SelectorLayoutType.pills:
        return _buildPillsLayout(context);
      case SelectorLayoutType.dropdown:
        return _buildDropdownLayout(context);
    }
  }

  Widget _buildCompactLayout(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: (widget.primaryColor ?? Theme.of(context).primaryColor)
            .withOpacity(0.1),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        if (widget.showTimeFrame) ...[
          Expanded(flex: 3, child: _buildTimeFramePills(context)),
          const SizedBox(width: 12),
        ],
        if (widget.showMetric) ...[
          Expanded(flex: 2, child: _buildMetricDropdown(context)),
          const SizedBox(width: 12),
        ],
        if (widget.showSector) ...[
          Expanded(flex: 2, child: _buildSectorDropdown(context)),
          const SizedBox(width: 12),
        ],
        if (widget.showMarketCap) ...[
          Expanded(flex: 2, child: _buildMarketCapDropdown(context)),
          const SizedBox(width: 12),
        ],
        if (widget.showLayout) ...[
          Expanded(flex: 2, child: _buildLayoutDropdown(context)),
          const SizedBox(width: 12),
        ],
        if (widget.showResetButton) _buildResetButton(context),
      ],
    ),
  );

  Widget _buildExpandedLayout(BuildContext context) => Card(
    elevation: 2,
    margin: const EdgeInsets.all(8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildExpandedSelectors(context),
          if (widget.showResetButton) ...[
            const SizedBox(height: 16),
            _buildExpandedResetButton(context),
          ],
        ],
      ),
    ),
  );

  Widget _buildPillsLayout(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: SelectorContainerConfigs.responsiveGrid(
      children: [
        if (widget.showTimeFrame) _buildTimeFramePills(context),
        if (widget.showMetric) _buildMetricPills(context),
        if (widget.showSector) _buildSectorPills(context),
        if (widget.showMarketCap) _buildMarketCapPills(context),
        if (widget.showLayout) _buildLayoutPills(context),
      ],
    ),
  );

  Widget _buildDropdownLayout(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    child: Row(
      children: [
        if (widget.showTimeFrame) ...[
          Expanded(child: _buildTimeFrameDropdown(context)),
          const SizedBox(width: 8),
        ],
        if (widget.showMetric) ...[
          Expanded(child: _buildMetricDropdown(context)),
          const SizedBox(width: 8),
        ],
        if (widget.showSector) ...[
          Expanded(child: _buildSectorDropdown(context)),
          const SizedBox(width: 8),
        ],
        if (widget.showMarketCap) ...[
          Expanded(child: _buildMarketCapDropdown(context)),
          const SizedBox(width: 8),
        ],
        if (widget.showLayout) ...[
          Expanded(child: _buildLayoutDropdown(context)),
          const SizedBox(width: 8),
        ],
        if (widget.showResetButton) _buildIconResetButton(context),
      ],
    ),
  );

  Widget _buildTimeFramePills(BuildContext context) => PillSelector<TimeFrame>(
    items: widget.core.timeFrameOptions,
    selectedItem: widget.core.selectedTimeFrame,
    onSelectionChanged: widget.core.updateTimeFrame,
    itemDisplayText: (timeFrame) => timeFrame.displayName,
    primaryColor: widget.primaryColor,
  );

  Widget _buildMetricDropdown(BuildContext context) =>
      CustomDropdown<MetricType>(
        value: widget.core.selectedMetric,
        primaryColor: widget.primaryColor,
        hint: 'Metric',
        items: widget.core.metricOptions
            .map<DropdownMenuItem<MetricType>>(
              (MetricType metric) => metric.toDropdownItem(
                text: metric.shortName,
                icon: metric.icon,
                iconColor:
                    (widget.primaryColor ?? Theme.of(context).primaryColor)
                        .withOpacity(0.7),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) widget.core.updateMetric(value);
        },
      );

  Widget _buildResetButton(BuildContext context) => ResetButton(
    onPressed: widget.core.resetFilters,
    style: ResetButtonStyle.compact,
    primaryColor: widget.primaryColor,
  );

  Widget _buildExpandedSelectors(BuildContext context) => Column(
    children: [
      Row(
        children: [
          if (widget.showTimeFrame) ...[
            Expanded(
              child: TimeFrameSelector.heatmap(
                selectedTimeFrame: widget.core.selectedTimeFrame,
                onTimeFrameChanged: widget.core.updateTimeFrame,
                primaryColor: widget.primaryColor,
                title: 'Time Frame',
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (widget.showMetric)
            Expanded(
              child: MetricSelector.heatmap(
                selectedMetric: widget.core.selectedMetric,
                onMetricChanged: widget.core.updateMetric,
                primaryColor: widget.primaryColor,
                title: 'Metric',
              ),
            ),
        ],
      ),
      if (widget.showSector || widget.showMarketCap) ...[
        const SizedBox(height: 16),
        Row(
          children: [
            if (widget.showSector) ...[
              Expanded(
                child: SectorSelector.heatmap(
                  selectedSector: widget.core.selectedSector,
                  onSectorChanged: widget.core.updateSector,
                  primaryColor: widget.primaryColor,
                  title: 'Sector',
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (widget.showMarketCap)
              Expanded(
                child: MarketCapSelector.heatmap(
                  selectedMarketCap: widget.core.selectedMarketCap,
                  onMarketCapChanged: widget.core.updateMarketCap,
                  primaryColor: widget.primaryColor,
                  title: 'Market Cap',
                ),
              ),
          ],
        ),
      ],
      if (widget.showLayout) ...[
        const SizedBox(height: 16),
        // Layout selector for expanded view
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Layout',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              _buildLayoutPills(context),
            ],
          ),
        ),
      ],
    ],
  );

  Widget _buildExpandedResetButton(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: ResetButton(
      onPressed: widget.core.resetFilters,
      style: ResetButtonStyle.outlined,
      primaryColor: widget.primaryColor,
    ),
  );

  // Additional pill and dropdown builders for other selectors
  Widget _buildMetricPills(BuildContext context) => PillSelector<MetricType>(
    items: widget.core.metricOptions,
    selectedItem: widget.core.selectedMetric,
    onSelectionChanged: widget.core.updateMetric,
    itemDisplayText: (metric) => metric.shortName,
    primaryColor: widget.primaryColor,
  );

  Widget _buildSectorPills(BuildContext context) => PillSelector<SectorType>(
    items: widget.core.sectorOptions,
    selectedItem: widget.core.selectedSector,
    onSelectionChanged: widget.core.updateSector,
    itemDisplayText: (sector) => sector.displayName,
    primaryColor: widget.primaryColor,
  );

  Widget _buildMarketCapPills(BuildContext context) =>
      PillSelector<MarketCapType>(
        items: widget.core.marketCapOptions,
        selectedItem: widget.core.selectedMarketCap,
        onSelectionChanged: widget.core.updateMarketCap,
        itemDisplayText: (marketCap) => marketCap.displayName,
        primaryColor: widget.primaryColor,
      );

  Widget _buildLayoutPills(BuildContext context) =>
      PillSelector<HeatmapLayoutType>(
        items: widget.core.layoutOptions,
        selectedItem: widget.core.selectedLayout,
        onSelectionChanged: widget.core.updateLayout,
        itemDisplayText: (layout) => layout.displayName,
        itemIcon: (layout) => layout.icon,
        primaryColor: widget.primaryColor,
      );

  Widget _buildTimeFrameDropdown(BuildContext context) =>
      CustomDropdown<TimeFrame>(
        value: widget.core.selectedTimeFrame,
        primaryColor: widget.primaryColor,
        hint: 'Time Frame',
        items: widget.core.timeFrameOptions
            .map<DropdownMenuItem<TimeFrame>>(
              (TimeFrame timeFrame) =>
                  timeFrame.toSimpleDropdownItem(text: timeFrame.displayName),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) widget.core.updateTimeFrame(value);
        },
      );

  Widget _buildSectorDropdown(BuildContext context) =>
      CustomDropdown<SectorType>(
        value: widget.core.selectedSector,
        primaryColor: widget.primaryColor,
        hint: 'Sector',
        items: widget.core.sectorOptions
            .map<DropdownMenuItem<SectorType>>(
              (SectorType sector) => sector.toDropdownItem(
                text: sector.shortName,
                icon: sector.icon,
                iconColor:
                    (widget.primaryColor ?? Theme.of(context).primaryColor)
                        .withOpacity(0.7),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) widget.core.updateSector(value);
        },
      );

  Widget _buildMarketCapDropdown(BuildContext context) =>
      CustomDropdown<MarketCapType>(
        value: widget.core.selectedMarketCap,
        primaryColor: widget.primaryColor,
        hint: 'Market Cap',
        items: widget.core.marketCapOptions
            .map<DropdownMenuItem<MarketCapType>>(
              (MarketCapType marketCap) => marketCap.toDropdownItem(
                text: marketCap.shortName,
                icon: marketCap.icon,
                iconColor:
                    (widget.primaryColor ?? Theme.of(context).primaryColor)
                        .withOpacity(0.7),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) widget.core.updateMarketCap(value);
        },
      );

  Widget _buildIconResetButton(BuildContext context) => ResetButton(
    onPressed: widget.core.resetFilters,
    primaryColor: widget.primaryColor,
  );

  Widget _buildLayoutDropdown(BuildContext context) =>
      CustomDropdown<HeatmapLayoutType>(
        value: widget.core.selectedLayout,
        primaryColor: widget.primaryColor,
        hint: 'Layout',
        items: widget.core.layoutOptions
            .map<DropdownMenuItem<HeatmapLayoutType>>(
              (layout) => layout.toDropdownItem(
                text: layout.displayName,
                icon: layout.icon,
                iconColor: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) widget.core.updateLayout(value);
        },
      );
}
