import 'package:am_market_ui/features/dashboard/domain/dashboard_section_id.dart';
import 'package:am_market_ui/features/dashboard/domain/dashboard_slot.dart';
import 'package:am_market_ui/features/dashboard/domain/view_mode.dart';

/// Declarative section config — data/layout contract for a future UI redesign.
///
/// New section = config + [DashboardSectionPort]; presentation is not wired yet.
class DashboardSectionConfig {
  const DashboardSectionConfig({
    required this.id,
    required this.navLabel,
    this.slotOrder = const [
      DashboardSlot.strip,
      DashboardSlot.chart,
      DashboardSlot.movers,
      DashboardSlot.lower,
    ],
    this.showStrip = true,
    this.showChart = true,
    this.showMovers = true,
    this.showLower = true,
    this.defaultViewMode = DashboardViewMode.card,
    this.allowedViewModes = const {
      DashboardViewMode.card,
      DashboardViewMode.list,
      DashboardViewMode.calendar,
      DashboardViewMode.heatmap,
    },
    this.defaultChartSymbols = const [],
    this.moversTitle = 'Top Movers',
    this.moversLosersTitle = 'Top Losers',
    this.emptyStripMessage = 'No items for this timeframe',
    this.emptyMoversMessage = 'No movers for this timeframe',
    this.emptyLowerMessage = 'No data for this view',
  });

  final DashboardSectionId id;
  final String navLabel;
  final List<DashboardSlot> slotOrder;
  final bool showStrip;
  final bool showChart;
  final bool showMovers;
  final bool showLower;
  final DashboardViewMode defaultViewMode;
  final Set<DashboardViewMode> allowedViewModes;
  final List<String> defaultChartSymbols;
  final String moversTitle;
  final String moversLosersTitle;
  final String emptyStripMessage;
  final String emptyMoversMessage;
  final String emptyLowerMessage;

  bool shows(DashboardSlot slot) => switch (slot) {
        DashboardSlot.strip => showStrip,
        DashboardSlot.chart => showChart,
        DashboardSlot.movers => showMovers,
        DashboardSlot.lower => showLower,
      };

  static const overview = DashboardSectionConfig(
    id: DashboardSectionId.overview,
    navLabel: 'Overview',
    defaultViewMode: DashboardViewMode.card,
    defaultChartSymbols: ['NIFTY 50', 'SENSEX', 'NIFTY BANK'],
    moversTitle: 'Index Top Movers',
    moversLosersTitle: 'Index Top Losers',
    emptyMoversMessage: 'No movers for this timeframe',
    emptyLowerMessage: 'Live map unavailable',
  );

  static const positional = DashboardSectionConfig(
    id: DashboardSectionId.positional,
    navLabel: 'Positional',
    defaultViewMode: DashboardViewMode.calendar,
    moversTitle: 'Flow leaders',
    moversLosersTitle: 'Flow laggards',
    emptyMoversMessage: 'No flow leaders for this timeframe',
    emptyLowerMessage: 'No session flow for this timeframe',
  );

  static const deepView = DashboardSectionConfig(
    id: DashboardSectionId.deepView,
    navLabel: 'Deep view',
    showMovers: false,
    slotOrder: [
      DashboardSlot.strip,
      DashboardSlot.chart,
      DashboardSlot.lower,
    ],
    defaultViewMode: DashboardViewMode.card,
    allowedViewModes: {
      DashboardViewMode.card,
      DashboardViewMode.list,
      DashboardViewMode.heatmap,
    },
    emptyLowerMessage: 'Deep view unavailable for this timeframe',
  );

  /// FII/DII Activity — summary tab (InstitutionalOiOverview).
  static const activity = DashboardSectionConfig(
    id: DashboardSectionId.activity,
    navLabel: 'Activity',
    showStrip: false,
    showChart: false,
    showMovers: false,
    showLower: true,
    slotOrder: [DashboardSlot.lower],
    defaultViewMode: DashboardViewMode.card,
    allowedViewModes: {DashboardViewMode.card},
    emptyLowerMessage: 'Institutional data unavailable',
  );

  /// Dashboard secondary tabs only (Positional lives under FII/DII Activity).
  static const List<DashboardSectionConfig> all = [
    overview,
    deepView,
  ];

  /// FII/DII Activity page secondary tabs.
  static const List<DashboardSectionConfig> fiiDiiActivityTabs = [
    activity,
    positional,
  ];

  static DashboardSectionConfig forId(DashboardSectionId id) => switch (id) {
        DashboardSectionId.overview => overview,
        DashboardSectionId.positional => positional,
        DashboardSectionId.deepView => deepView,
        DashboardSectionId.activity => activity,
      };
}
