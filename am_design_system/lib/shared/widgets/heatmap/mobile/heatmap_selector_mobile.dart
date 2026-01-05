import 'package:flutter/material.dart';
import '../../../../core/utils/common_logger.dart';
import '../../selectors/selectors.dart';
import '../core/heatmap_selector_core.dart';
import '../configs/selector_config.dart';


/// Mobile-optimized heatmap selector with user-friendly design
/// Uses bottom sheets, expandable sections, and touch-friendly controls
class HeatmapSelectorMobile extends StatefulWidget {
  const HeatmapSelectorMobile({
    required this.core,
    super.key,
    this.showTimeFrame = true,
    this.showMetric = true,
    this.showSector = true,
    this.showMarketCap = true,
    this.showLayout = false,
    this.primaryColor,
    this.title,
    this.showResetButton = true,
    this.compactMode = false,
  });

  final HeatmapSelectorCore core;
  final bool showTimeFrame;
  final bool showMetric;
  final bool showSector;
  final bool showMarketCap;
  final bool showLayout;
  final Color? primaryColor;
  final String? title;
  final bool showResetButton;
  final bool compactMode;

  @override
  State<HeatmapSelectorMobile> createState() => _HeatmapSelectorMobileState();
}

class _HeatmapSelectorMobileState extends State<HeatmapSelectorMobile>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Listen to core changes
    widget.core.addListener(_onCoreChanged);

    CommonLogger.debug(
      'HeatmapSelectorMobile: initialized',
      tag: 'Heatmap.Selector.Mobile',
    );
  }

  @override
  void dispose() {
    widget.core.removeListener(_onCoreChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onCoreChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compactMode) {
      return _buildCompactMode(context);
    }

    return _buildStandardMode(context);
  }

  Widget _buildCompactMode(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactHeader(context),
        if (_isExpanded)
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildCompactExpandedFilters(context),
          ),
      ],
    ),
  );

  Widget _buildCompactHeader(BuildContext context) => InkWell(
    onTap: _toggleExpanded,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            color: widget.primaryColor ?? Theme.of(context).primaryColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getCompactSummary(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 18,
          ),
        ],
      ),
    ),
  );

  String _getCompactSummary() {
    final parts = <String>[];

    if (widget.showTimeFrame) {
      parts.add(widget.core.selectedTimeFrame.displayName);
    }
    if (widget.showMetric) {
      parts.add(widget.core.selectedMetric.shortName);
    }
    if (widget.showSector && widget.core.selectedSector != SectorType.all) {
      parts.add(widget.core.selectedSector.shortName);
    }
    if (widget.showMarketCap &&
        widget.core.selectedMarketCap != MarketCapType.all) {
      parts.add(widget.core.selectedMarketCap.shortName);
    }

    return parts.isEmpty ? 'Tap to configure filters' : parts.join(' • ');
  }

  Widget _buildStandardMode(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) _buildCompactTitle(context),
        _buildQuickActions(context),
      ],
    ),
  );

  Widget _buildCompactTitle(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
    child: Row(
      children: [
        Icon(
          Icons.filter_alt_outlined,
          color: widget.primaryColor ?? Theme.of(context).primaryColor,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.title!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.primaryColor ?? Theme.of(context).primaryColor,
            ),
          ),
        ),
        if (widget.showResetButton)
          InkWell(
            onTap: widget.core.resetFilters,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reset',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _buildQuickActions(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Column(
      children: [
        if (widget.showTimeFrame) _buildCompactTimeFrameRow(context),
        const SizedBox(height: 8),
        _buildCompactFiltersRow(context),
      ],
    ),
  );

  Widget _buildCompactTimeFrameRow(BuildContext context) => SizedBox(
    height: 32,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: widget.core.timeFrameOptions.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final timeFrame = widget.core.timeFrameOptions[index];
        final isSelected = widget.core.selectedTimeFrame == timeFrame;

        return _buildCompactPill(
          context,
          text: timeFrame.displayName,
          isSelected: isSelected,
          onTap: () => widget.core.updateTimeFrame(timeFrame),
        );
      },
    ),
  );

  Widget _buildCompactPill(
    BuildContext context, {
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (widget.primaryColor ?? Theme.of(context).primaryColor)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? null
            : Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    ),
  );

  Widget _buildCompactFilterChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: widget.primaryColor ?? Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildCompactFiltersRow(BuildContext context) => Row(
    children: [
      if (widget.showSector) ...[
        Expanded(
          child: _buildCompactFilterChip(
            context,
            icon: Icons.business,
            label: 'Sector',
            value: widget.core.selectedSector.shortName,
            onTap: () => _showSectorSelector(context),
          ),
        ),
        const SizedBox(width: 6),
      ],
      if (widget.showMarketCap) ...[
        Expanded(
          child: _buildCompactFilterChip(
            context,
            icon: Icons.account_balance,
            label: 'Cap',
            value: widget.core.selectedMarketCap.shortName,
            onTap: () => _showMarketCapSelector(context),
          ),
        ),
        const SizedBox(width: 6),
      ],
      if (widget.showLayout) ...[
        Expanded(
          child: _buildCompactFilterChip(
            context,
            icon: widget.core.selectedLayout.icon,
            label: 'Layout',
            value: widget.core.selectedLayout.displayName,
            onTap: () => _showLayoutSelector(context),
          ),
        ),
      ],
    ],
  );

  Widget _buildFiltersList(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        if (widget.showMetric)
          _buildFilterTile(
            context,
            icon: Icons.trending_up,
            title: 'Metric',
            value: widget.core.selectedMetric.shortName,
            onTap: () => _showMetricSelector(context),
          ),
        if (widget.showSector)
          _buildFilterTile(
            context,
            icon: Icons.business,
            title: 'Sector',
            value: widget.core.selectedSector.displayName,
            onTap: () => _showSectorSelector(context),
          ),
        if (widget.showMarketCap)
          _buildFilterTile(
            context,
            icon: Icons.account_balance,
            title: 'Market Cap',
            value: widget.core.selectedMarketCap.displayName,
            onTap: () => _showMarketCapSelector(context),
          ),
        if (widget.showLayout)
          _buildFilterTile(
            context,
            icon: Icons.view_module,
            title: 'Layout',
            value: widget.core.selectedLayout.displayName,
            onTap: () => _showLayoutSelector(context),
          ),
      ],
    ),
  );

  Widget _buildCompactExpandedFilters(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        if (widget.showMetric) ...[
          _buildCompactFilterSection(
            context,
            title: 'Metric',
            child: _buildCompactMetricList(context),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.showSector) ...[
          _buildCompactFilterSection(
            context,
            title: 'Sector',
            child: _buildCompactSectorList(context),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.showMarketCap) ...[
          _buildCompactFilterSection(
            context,
            title: 'Market Cap',
            child: _buildCompactMarketCapList(context),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.showLayout) ...[
          _buildCompactFilterSection(
            context,
            title: 'Layout',
            child: _buildCompactLayoutList(context),
          ),
        ],
      ],
    ),
  );

  Widget _buildCompactFilterSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: widget.primaryColor ?? Theme.of(context).primaryColor,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );

  Widget _buildCompactMetricList(BuildContext context) => SizedBox(
    height: 32,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: widget.core.metricOptions.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final metric = widget.core.metricOptions[index];
        final isSelected = widget.core.selectedMetric == metric;
        return _buildCompactPill(
          context,
          text: metric.shortName,
          isSelected: isSelected,
          onTap: () => widget.core.updateMetric(metric),
        );
      },
    ),
  );

  Widget _buildCompactSectorList(BuildContext context) => SizedBox(
    height: 32,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: widget.core.sectorOptions.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final sector = widget.core.sectorOptions[index];
        final isSelected = widget.core.selectedSector == sector;
        return _buildCompactPill(
          context,
          text: sector.shortName,
          isSelected: isSelected,
          onTap: () => widget.core.updateSector(sector),
        );
      },
    ),
  );

  Widget _buildCompactMarketCapList(BuildContext context) => SizedBox(
    height: 32,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: widget.core.marketCapOptions.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final marketCap = widget.core.marketCapOptions[index];
        final isSelected = widget.core.selectedMarketCap == marketCap;
        return _buildCompactPill(
          context,
          text: marketCap.shortName,
          isSelected: isSelected,
          onTap: () => widget.core.updateMarketCap(marketCap),
        );
      },
    ),
  );

  Widget _buildCompactLayoutList(BuildContext context) => SizedBox(
    height: 32,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: widget.core.layoutOptions.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        final layout = widget.core.layoutOptions[index];
        final isSelected = widget.core.selectedLayout == layout;
        return _buildCompactPill(
          context,
          text: layout.displayName,
          isSelected: isSelected,
          onTap: () => widget.core.updateLayout(layout),
        );
      },
    ),
  );

  Widget _buildFilterTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: widget.primaryColor ?? Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    ),
  );

  void _showFiltersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: _buildBottomSheet,
    );
  }

  Widget _buildBottomSheet(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBottomSheetHeader(context),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (widget.showMetric) ...[
                  _buildBottomSheetSection(
                    context,
                    title: 'Metric',
                    child: _buildMetricList(context),
                  ),
                  const SizedBox(height: 24),
                ],
                if (widget.showSector) ...[
                  _buildBottomSheetSection(
                    context,
                    title: 'Sector',
                    child: _buildSectorList(context),
                  ),
                  const SizedBox(height: 24),
                ],
                if (widget.showMarketCap) ...[
                  _buildBottomSheetSection(
                    context,
                    title: 'Market Cap',
                    child: _buildMarketCapList(context),
                  ),
                  const SizedBox(height: 24),
                ],
                if (widget.showLayout) ...[
                  _buildBottomSheetSection(
                    context,
                    title: 'Layout',
                    child: _buildLayoutList(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildBottomSheetHeader(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Filter Options',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );

  Widget _buildBottomSheetSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: widget.primaryColor ?? Theme.of(context).primaryColor,
        ),
      ),
      const SizedBox(height: 12),
      child,
    ],
  );

  Widget _buildMetricList(BuildContext context) => Column(
    children: widget.core.metricOptions.map((metric) {
      final isSelected = widget.core.selectedMetric == metric;
      return _buildBottomSheetTile(
        context,
        title: metric.displayName,
        subtitle: metric.shortName,
        isSelected: isSelected,
        onTap: () {
          widget.core.updateMetric(metric);
          Navigator.of(context).pop();
        },
      );
    }).toList(),
  );

  Widget _buildSectorList(BuildContext context) => Column(
    children: widget.core.sectorOptions.map((sector) {
      final isSelected = widget.core.selectedSector == sector;
      return _buildBottomSheetTile(
        context,
        title: sector.displayName,
        subtitle: sector.shortName,
        isSelected: isSelected,
        onTap: () {
          widget.core.updateSector(sector);
          Navigator.of(context).pop();
        },
      );
    }).toList(),
  );

  Widget _buildMarketCapList(BuildContext context) => Column(
    children: widget.core.marketCapOptions.map((marketCap) {
      final isSelected = widget.core.selectedMarketCap == marketCap;
      return _buildBottomSheetTile(
        context,
        title: marketCap.displayName,
        subtitle: marketCap.shortName,
        isSelected: isSelected,
        onTap: () {
          widget.core.updateMarketCap(marketCap);
          Navigator.of(context).pop();
        },
      );
    }).toList(),
  );

  Widget _buildLayoutList(BuildContext context) => Column(
    children: widget.core.layoutOptions.map((layout) {
      final isSelected = widget.core.selectedLayout == layout;
      return _buildBottomSheetTile(
        context,
        title: layout.displayName,
        subtitle: 'View as ${layout.displayName.toLowerCase()}',
        icon: layout.icon,
        isSelected: isSelected,
        onTap: () {
          widget.core.updateLayout(layout);
          Navigator.of(context).pop();
        },
      );
    }).toList(),
  );

  Widget _buildBottomSheetTile(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    String? subtitle,
    IconData? icon,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: isSelected
          ? BoxDecoration(
              color: (widget.primaryColor ?? Theme.of(context).primaryColor)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.primaryColor ?? Theme.of(context).primaryColor,
              ),
            )
          : null,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? (widget.primaryColor ?? Theme.of(context).primaryColor)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (widget.primaryColor ??
                              Theme.of(context).primaryColor)
                        : null,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: widget.primaryColor ?? Theme.of(context).primaryColor,
              size: 20,
            ),
        ],
      ),
    ),
  );

  // Individual selector methods
  void _showMetricSelector(BuildContext context) {
    _showSelectorDialog(
      context,
      title: 'Select Metric',
      items: widget.core.metricOptions,
      selectedItem: widget.core.selectedMetric,
      onItemSelected: widget.core.updateMetric,
      getDisplayText: (metric) => (metric as MetricType).displayName,
      getSubtitle: (metric) => (metric as MetricType).displayName,
    );
  }

  void _showSectorSelector(BuildContext context) {
    _showSelectorDialog(
      context,
      title: 'Select Sector',
      items: widget.core.sectorOptions,
      selectedItem: widget.core.selectedSector,
      onItemSelected: widget.core.updateSector,
      getDisplayText: (sector) => (sector as SectorType).displayName,
      getSubtitle: (sector) => (sector as SectorType).displayName,
    );
  }

  void _showMarketCapSelector(BuildContext context) {
    _showSelectorDialog(
      context,
      title: 'Select Market Cap',
      items: widget.core.marketCapOptions,
      selectedItem: widget.core.selectedMarketCap,
      onItemSelected: widget.core.updateMarketCap,
      getDisplayText: (marketCap) => (marketCap as MarketCapType).displayName,
      getSubtitle: (marketCap) => (marketCap as MarketCapType).displayName,
    );
  }

  void _showLayoutSelector(BuildContext context) {
    _showSelectorDialog<HeatmapLayoutType>(
      context,
      title: 'Select Layout',
      items: widget.core.layoutOptions,
      selectedItem: widget.core.selectedLayout,
      onItemSelected: widget.core.updateLayout,
      getDisplayText: (layout) => (layout as HeatmapLayoutType).displayName,
      getSubtitle: (layout) => 'View as ${(layout as HeatmapLayoutType).displayName.toLowerCase()}',
      getIcon: (layout) => (layout as HeatmapLayoutType).icon,
    );
  }

  void _showSelectorDialog<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required T selectedItem,
    required ValueChanged<T> onItemSelected,
    required String Function(T) getDisplayText,
    String Function(T)? getSubtitle,
    IconData? Function(T)? getIcon,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = item == selectedItem;

              return ListTile(
                leading: getIcon != null
                    ? Icon(
                        getIcon(item),
                        color: isSelected
                            ? (widget.primaryColor ??
                                  Theme.of(context).primaryColor)
                            : null,
                      )
                    : null,
                title: Text(
                  getDisplayText(item),
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? (widget.primaryColor ??
                              Theme.of(context).primaryColor)
                        : null,
                  ),
                ),
                subtitle: getSubtitle != null ? Text(getSubtitle(item)) : null,
                trailing: isSelected
                    ? Icon(
                        Icons.check,
                        color:
                            widget.primaryColor ??
                            Theme.of(context).primaryColor,
                      )
                    : null,
                onTap: () {
                  onItemSelected(item);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
