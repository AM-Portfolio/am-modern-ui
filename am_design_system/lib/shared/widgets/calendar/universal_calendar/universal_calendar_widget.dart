
import 'package:flutter/material.dart';
import 'package:am_design_system/core/utils/common_logger.dart';
import '../year_calendar/calendar_types.dart';


import 'card_renderer.dart';
import 'card_types.dart';
import 'config.dart';
import 'config_manager.dart';
import 'data_provider.dart';
import 'template_factory.dart';
import 'types.dart';

/// Universal calendar date selector widget that orchestrates 3 separate components based on config
/// This is the main widget that should be used for date filtering across the app
/// Creates: FilterTemplate + DisplayTemplate + LayoutTemplate based on configuration
class UniversalCalendarWidget extends StatefulWidget {
  const UniversalCalendarWidget({
    required this.onDateSelectionChanged,
    super.key,
    this.config,
    this.initialSelection,
    this.templateType = CalendarTemplateType.adaptive,
    this.title,
    this.context = 'default',
    this.cardConfigs,
    this.dataProvider,
    this.enableCardView = false,
    this.yearCalendarData,
    this.currentYear,
    this.showYearCalendar = false,
  });

  /// Callback when date selection changes
  final Function(DateSelection) onDateSelectionChanged;

  /// Configuration overrides (optional, uses basic config if not provided)
  final CalendarConfig? config;

  /// Initial date selection
  final DateSelection? initialSelection;

  /// Template composition type
  final CalendarTemplateType templateType;

  /// Custom title for the widget
  final String? title;

  /// Context for default configuration (trade, portfolio, analytics, etc.)
  final String context;

  /// Card configurations for calendar display
  final List<CalendarCardConfig>? cardConfigs;

  /// Data provider for card content
  final CalendarDataProvider? dataProvider;

  /// Enable card view mode
  final bool enableCardView;

  /// Year calendar data for year calendar view
  final Map<int, CalendarMonthData>? yearCalendarData;

  /// Current year for year calendar view
  final int? currentYear;

  /// Show year calendar instead of filter template
  final bool showYearCalendar;

  @override
  State<UniversalCalendarWidget> createState() => _UniversalCalendarWidgetState();
}

class _UniversalCalendarWidgetState extends State<UniversalCalendarWidget> {
  late DateSelection _currentSelection;
  late CalendarDataProvider _dataProvider;
  Map<String, List<CardData>> _cardData = {};
  bool _isLoadingCardData = false;

  @override
  void initState() {
    super.initState();
    CommonLogger.methodEntry('initState', tag: 'UniversalCalendarWidget');
    _currentSelection =
        widget.initialSelection ??
        DateSelection(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
          description: 'Last 30 Days',
          filterType: DateFilterMode.quick,
        );

    CommonLogger.debug('Initial selection: $_currentSelection', tag: 'UniversalCalendarWidget');

    // Initialize data provider
    _dataProvider =
        widget.dataProvider ??
        CalendarDataProviderFactory.createProvider(context: widget.context, config: {'mockData': null});

    CommonLogger.debug('Data provider initialized: ${_dataProvider.runtimeType}', tag: 'UniversalCalendarWidget');

    // Load initial card data if card view is enabled
    if (widget.enableCardView) {
      CommonLogger.info('Card view enabled, loading initial data...', tag: 'UniversalCalendarWidget');
      _loadCardData();
    }
    CommonLogger.methodExit('initState', tag: 'UniversalCalendarWidget');
  }

  @override
  void didUpdateWidget(UniversalCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelection != oldWidget.initialSelection && widget.initialSelection != null) {
      CommonLogger.info('Initial selection updated from widget: ${widget.initialSelection}', tag: 'UniversalCalendarWidget');
      _currentSelection = widget.initialSelection!;
    }

    // Reload card data if context or data provider changed
    if (widget.enableCardView &&
        (widget.context != oldWidget.context || widget.dataProvider != oldWidget.dataProvider)) {
      CommonLogger.info('Context or data provider changed, re-initializing...', tag: 'UniversalCalendarWidget');
      _dataProvider =
          widget.dataProvider ??
          CalendarDataProviderFactory.createProvider(context: widget.context, config: {'mockData': null});
      _loadCardData();
    }
  }


  void _handleSelectionChanged(DateSelection selection) {
    CommonLogger.info('Selection changed: $selection', tag: 'UniversalCalendarWidget');
    setState(() {
      _currentSelection = selection;
    });
    widget.onDateSelectionChanged(selection);

    // Reload card data for new date range
    if (widget.enableCardView) {
      CommonLogger.debug('Reloading card data for new selection...', tag: 'UniversalCalendarWidget');
      _loadCardData();
    }
  }


  Future<void> _loadCardData() async {
    if (!_currentSelection.hasDateRange) return;

    setState(() {
      _isLoadingCardData = true;
    });

    try {
      final cardTypes = widget.cardConfigs?.map((c) => c.type).toList() ?? _dataProvider.getSupportedCardTypes();

      final data = await _dataProvider.getCardData(
        startDate: _currentSelection.startDate!,
        endDate: _currentSelection.endDate!,
        cardTypes: cardTypes,
      );

      setState(() {
        _cardData = data;
        _isLoadingCardData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCardData = false;
      });
      // Handle error appropriately
      debugPrint('Error loading card data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get effective config (use provided config or generate based on context)
    final effectiveConfig = widget.config ?? _getDefaultConfig();

    CommonLogger.debug(
      'Building UniversalCalendarWidget - showYearCalendar: ${widget.showYearCalendar}, '
      'hasYearData: ${widget.yearCalendarData != null}, year: ${widget.currentYear}',
      tag: 'UniversalCalendarWidget',
    );

    if (widget.enableCardView) {
      return Column(
        children: [
          // Date selector section
          UniversalCalendarTemplateFactory.createCalendarWidget(
            context: context,
            config: effectiveConfig,
            onSelectionChanged: _handleSelectionChanged,
            initialSelection: _currentSelection,
            yearCalendarData: widget.yearCalendarData,
            currentYear: widget.currentYear,
            showYearCalendar: widget.showYearCalendar,
          ),
          const SizedBox(height: 16),
          // Card view section
          Expanded(child: _buildCardView(context)),
        ],
      );
    }

    // Create the universal calendar using template factory
    return UniversalCalendarTemplateFactory.createCalendarWidget(
      context: context,
      config: effectiveConfig,
      onSelectionChanged: _handleSelectionChanged,
      initialSelection: _currentSelection,
      yearCalendarData: widget.yearCalendarData,
      currentYear: widget.currentYear,
      showYearCalendar: widget.showYearCalendar,
    );
  }

  Widget _buildCardView(BuildContext context) {
    if (_isLoadingCardData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cardData.isEmpty) {
      return const Center(child: Text('No data available for selected date range'));
    }

    final configs = widget.cardConfigs ?? _dataProvider.getDefaultCardConfigs();

    return ListView.builder(
      itemCount: _cardData.keys.length,
      itemBuilder: (context, index) {
        final dateKey = _cardData.keys.elementAt(index);
        final date = DateTime.parse(dateKey);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _formatDateHeader(date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              // Cards grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CalendarCardFactory.createCardGrid(
                    configs: configs,
                    dataMap: _cardData,
                    dateKey: dateKey,
                    onCardTap: _handleCardTap,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _handleCardTap(CalendarCardConfig config, CardData data) {
    // Handle card tap - could navigate to detailed view
    debugPrint('Card tapped: ${config.title} for ${data.dateKey}');
  }

  String _formatDateHeader(DateTime date) {
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
    final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  CalendarConfig _getDefaultConfig() {
    // Choose appropriate config based on context and template type
    switch (widget.templateType) {
      case CalendarTemplateType.minimal:
        return UniversalCalendarConfigManager.getMinimalConfig();

      case CalendarTemplateType.compact:
        return UniversalCalendarConfigManager.getCompactConfig(title: widget.title);

      case CalendarTemplateType.full:
        return UniversalCalendarConfigManager.getFullConfig(
          title: widget.title ?? UniversalCalendarConfigManager.getDefaultTitle(widget.context),
        );

      case CalendarTemplateType.dashboard:
        return UniversalCalendarConfigManager.getCompactConfig(title: widget.title);

      case CalendarTemplateType.adaptive:
        // Choose config based on context
        switch (widget.context.toLowerCase()) {
          case 'trade':
          case 'trading':
            return UniversalCalendarConfigManager.getTradeConfig(title: widget.title);

          case 'web':
            return UniversalCalendarConfigManager.getWebConfig(title: widget.title);

          default:
            return UniversalCalendarConfigManager.getBasicConfig(
              title: widget.title ?? UniversalCalendarConfigManager.getDefaultTitle(widget.context),
            );
        }
    }
  }
}

/// Simplified wrapper for quick date filtering
class QuickDateFilter extends StatelessWidget {
  const QuickDateFilter({required this.onDateSelectionChanged, super.key, this.initialSelection});

  final Function(DateSelection) onDateSelectionChanged;
  final DateSelection? initialSelection;

  @override
  Widget build(BuildContext context) => UniversalCalendarWidget(
    onDateSelectionChanged: onDateSelectionChanged,
    initialSelection: initialSelection,
    templateType: CalendarTemplateType.minimal,
    config: UniversalCalendarConfigManager.getMinimalConfig(),
  );
}

/// Web-optimized date filter for responsive layouts
class WebDateFilter extends StatelessWidget {
  const WebDateFilter({
    required this.onDateSelectionChanged,
    super.key,
    this.title,
    this.initialSelection,
    this.fullFeatures = true,
  });

  final Function(DateSelection) onDateSelectionChanged;
  final String? title;
  final DateSelection? initialSelection;
  final bool fullFeatures;

  @override
  Widget build(BuildContext context) => UniversalCalendarWidget(
    onDateSelectionChanged: onDateSelectionChanged,
    title: title,
    initialSelection: initialSelection,
    config: UniversalCalendarConfigManager.getWebConfig(title: title, fullFeatures: fullFeatures),
  );
}

/// Trade-specific date filter optimized for trading analytics
class TradeDateFilter extends StatelessWidget {
  const TradeDateFilter({required this.onDateSelectionChanged, super.key, this.title, this.initialSelection});

  final Function(DateSelection) onDateSelectionChanged;
  final String? title;
  final DateSelection? initialSelection;

  @override
  Widget build(BuildContext context) => UniversalCalendarWidget(
    onDateSelectionChanged: onDateSelectionChanged,
    title: title,
    initialSelection: initialSelection,
    context: 'trade',
  );
}
