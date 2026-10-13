import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:provider/provider.dart' show ReadContext, WatchContext;
import 'package:am_design_system/am_design_system.dart';
import 'package:am_library/am_library.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/shared/widgets/glass_container.dart';
import 'package:intl/intl.dart';
import 'package:am_market_common/models/historical_performance_model.dart';
import 'package:am_market_common/models/seasonality_model.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/historical_performance_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';

class HeatmapExplorerView extends ConsumerStatefulWidget {
  const HeatmapExplorerView({super.key});

  @override
  ConsumerState<HeatmapExplorerView> createState() => _HeatmapExplorerViewState();
}

class _HeatmapExplorerViewState extends ConsumerState<HeatmapExplorerView> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  String _selectedSymbol = 'NIFTY BANK'; // Default symbol
  bool _emittedHeatmapEmpty = false;
  final List<String> _months = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
  ];

  final List<String> _shortMonths = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];
  
  // Heatmap State
  String _heatmapTimeframe = '1D';
  bool _showingIndices = true; // Use separate state for Heatmap section drill-down
  bool _isHeatmapExpanded = true; // Control visibility of the heatmap grid
  
  final ScrollController _scrollController = ScrollController();


  // _selectedSymbol is used for General Analysis (Seasonality/Historical)
  // For Heatmap, we use _showingIndices to determine if showing "List of Indices" or "Constituents of _selectedSymbol"
  // Wait, if _showingIndices is false, we show constituents of _selectedSymbol. 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchData() {
    _fetchGeneralData();
    _fetchHeatmapData();
  }

  void _fetchGeneralData() {
    // 1. Fetch General Analysis Data (Seasonality & Historical)
    if (_selectedSymbol.isNotEmpty && _selectedSymbol != "INDICES") {
        context.read<MarketProvider>().loadHistoricalPerformance(_selectedSymbol);
        context.read<MarketProvider>().loadSeasonality(_selectedSymbol);
    }
  }

  void _fetchHeatmapData() {
    // 2. Fetch Heatmap Data
    // Target: if showing indices -> "INDICES"
    // If showing constituents -> _selectedSymbol
    String heatmapTarget = _showingIndices ? 'INDICES' : _selectedSymbol;
    if (heatmapTarget.isEmpty && !_showingIndices) heatmapTarget = "NIFTY 50"; // Fallback

    final sw = Stopwatch()..start();
    context.read<MarketProvider>().loadHeatmap(heatmapTarget, _heatmapTimeframe);
    // loadHeatmap is async on provider; record request timing as navigation cost
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sw.stop();
      ProductTelemetry.instance.widgetTiming(
        widget: 'market_heatmap',
        durationMs: sw.elapsedMilliseconds,
        operation: 'fetch',
        technicalArea: 'market',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Listen to global timeframe changes and synchronize internal data state
    ref.listen<TimeFrame>(appTimeFrameProvider, (previous, next) {
      if (next.code != _heatmapTimeframe) {
        setState(() {
          _heatmapTimeframe = next.code;
        });
        // Only fetch heatmap data when timeframe changes, historical/seasonality are independent
        _fetchHeatmapData();
      }
    });

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
        // Main Content Area — index discovery via Global Search
        Expanded(
          child: _showingIndices
            ? SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  children: [
                    _buildHeatmapSection(),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? context.colors.cardSurface.withValues(alpha: 0.60)
                            : context.colors.cardSurface.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.colors.border.withValues(alpha: isDark ? 0.35 : 0.5)),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                      ),
                      child: const HistoricalPerformanceSection(),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              )
            : provider_pkg.Selector<MarketProvider, (HistoricalPerformanceResponse?, SeasonalityResponse?, bool)>(
                selector: (_, p) => (p.historicalPerformance, p.seasonality, p.isLoading),
                builder: (context, dataTuple, child) {
                  final hData = dataTuple.$1;
                  final sData = dataTuple.$2;
                  final isLoading = dataTuple.$3;
                  return SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        _buildHeatmapSection(),
                        const SizedBox(height: 16),
                        hData == null 
                            ? SizedBox(
                                height: 200,
                                child: Center(child: Text(isLoading ? 'Loading...' : 'No data available', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)))
                              )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                 Container(
                                 padding: const EdgeInsets.all(16),
                                 decoration: BoxDecoration(
                                   color: isDark
                                       ? context.colors.cardSurface.withValues(alpha: 0.60)
                                       : context.colors.cardSurface.withValues(alpha: 0.90),
                                   borderRadius: BorderRadius.circular(16),
                                   border: Border.all(color: context.colors.border.withValues(alpha: isDark ? 0.35 : 0.5)),
                                   boxShadow: isDark
                                       ? []
                                       : [
                                           BoxShadow(
                                             color: Colors.black.withOpacity(0.04),
                                             blurRadius: 10,
                                             offset: const Offset(0, 4),
                                           )
                                         ],
                                 ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     // Overall Return Header (Optional)
                                     if (hData.overallReturn != null)
                                       Padding(
                                         padding: const EdgeInsets.only(bottom: 16.0),
                                         child: Text(
                                           "Overall Return (${hData.startYear}-${hData.endYear}): ${hData.overallReturn}%",
                                           style: TextStyle(
                                               color: _getColorForChange(hData.overallReturn!),
                                               fontWeight: FontWeight.bold,
                                               fontSize: 16
                                           ),
                                         ),
                                       ),
          
                                     // Responsive Table with Horizontal Scroll
                                     LayoutBuilder(
                                       builder: (context, constraints) {
                                         // On Desktop, use full available width.
                                         // On Mobile, force a minimum width (e.g., 900) to prevent squashing, enabling scrolling.
                                         const double minTableWidth = 900.0;
                                         final double effectiveWidth = constraints.maxWidth < minTableWidth 
                                             ? minTableWidth 
                                             : constraints.maxWidth;

                                         return SingleChildScrollView(
                                           scrollDirection: Axis.horizontal,
                                           child: SizedBox(
                                             width: effectiveWidth,
                                             child: Column(
                                               children: [
                                                  // Header Row
                                                  Row(
                                                    children: [
                                                      const SizedBox(width: 60), // Year column width
                                                      ..._shortMonths.map((m) => Expanded(
                                                        child: Center(
                                                          child: Text(
                                                            m,
                                                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      )),
                                                      const SizedBox(width: 60), // Yearly Total width
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Divider(color: Colors.white.withOpacity(0.1), height: 1),
                                                  const SizedBox(height: 8),

                                                  // Data Rows
                                                  ...hData.yearlyPerformance.map((yearly) {
                                                      return Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                                                        child: Row(
                                                          children: [
                                                            // Year Label
                                                            SizedBox(
                                                              width: 60,
                                                              child: Text(
                                                                '${yearly.year}',
                                                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                                                              ),
                                                            ),
                                                            
                                                            // Monthly Cells
                                                            ..._months.map((monthKey) {
                                                                final val = yearly.monthlyReturns[monthKey];
                                                                final baseColor = val != null
                                                                    ? _getColorForChange(val).withValues(alpha: 0.8)
                                                                    : context.colors.textPrimary.withValues(alpha: 0.05);
                                                                final glowColor = (val != null && val >= 0)
                                                                    ? context.colors.marketPositiveIndicator.withValues(alpha: 0.3)
                                                                    : context.colors.marketNegativeIndicator.withValues(alpha: 0.3);
                                                                return Expanded(
                                                                  child: _HoverableHeatmapCell(
                                                                     val: val,
                                                                     baseColor: baseColor,
                                                                     glowColor: glowColor,
                                                                  ),
                                                                );
                                                            }).toList(),

                                                            // Yearly Total
                                                            SizedBox(
                                                              width: 60,
                                                              child: Center(
                                                                child: Text(
                                                                  yearly.yearlyReturn != null ? '${yearly.yearlyReturn}%' : '-',
                                                                    style: TextStyle(
                                                                      color: _getColorForChange(yearly.yearlyReturn ?? 0),
                                                                      fontSize: 12,
                                                                      fontWeight: FontWeight.bold
                                                                    ),
                                                                    textAlign: TextAlign.end,
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      );
                                                  }).toList(),
                                               ],
                                             ),
                                           ),
                                         );
                                       }
                                     ),
                                  ],
                                ),
                            ),
                             const SizedBox(height: 16),
                             if (sData != null) _buildSeasonality(sData),
                             const SizedBox(height: 16), // Bottom padding
                            ],
                           ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  ),
);
     
  }


  Widget _buildSeasonality(SeasonalityResponse seasonality) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Filter out weekends
    final dayOfWeekData = seasonality.dayOfWeekReturns.entries
        .where((e) => e.key != 'SATURDAY' && e.key != 'SUNDAY')
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? context.colors.cardSurface.withValues(alpha: 0.60)
            : context.colors.cardSurface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border.withValues(alpha: isDark ? 0.35 : 0.5)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Seasonality Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Average percentage return based on historical data.',
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(Icons.info_outline, color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4), size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day of Week Analysis
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Day of Week', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...dayOfWeekData.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              children: [
                                SizedBox(width: 80, child: Text(e.key, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.w500))),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(height: 4, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(2))),
                                      FractionallySizedBox(
                                        widthFactor: (e.value.abs() / 1.0).clamp(0.0, 1.0), // Normalize
                                        child: Container(
                                          height: 4, 
                                          decoration: BoxDecoration(
                                            color: _getColorForChange(e.value),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(width: 45, child: Text('${e.value.toStringAsFixed(2)}%', textAlign: TextAlign.end, style: TextStyle(color: _getColorForChange(e.value), fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Monthly Analysis
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monthly', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                         ...seasonality.monthlyReturns.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              children: [
                                SizedBox(width: 80, child: Text(e.key, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.w500))),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(height: 4, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(2))),
                                      FractionallySizedBox(
                                        widthFactor: (e.value.abs() / 5.0).clamp(0.0, 1.0), // Normalize
                                        child: Container(
                                          height: 4, 
                                          decoration: BoxDecoration(
                                            color: _getColorForChange(e.value),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(width: 45, child: Text('${e.value.toStringAsFixed(2)}%', textAlign: TextAlign.end, style: TextStyle(color: _getColorForChange(e.value), fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day of Week Analysis
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Day of Week', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...dayOfWeekData.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                children: [
                                  SizedBox(width: 80, child: Text(e.key, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.w500))),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Container(height: 4, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(2))),
                                        FractionallySizedBox(
                                          widthFactor: (e.value.abs() / 1.0).clamp(0.0, 1.0), // Normalize
                                          child: Container(
                                            height: 4, 
                                            decoration: BoxDecoration(
                                              color: _getColorForChange(e.value),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 45, child: Text('${e.value.toStringAsFixed(2)}%', textAlign: TextAlign.end, style: TextStyle(color: _getColorForChange(e.value), fontSize: 11, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Monthly Analysis
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                           ...seasonality.monthlyReturns.entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                children: [
                                  SizedBox(width: 80, child: Text(e.key, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.w500))),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Container(height: 4, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(2))),
                                        FractionallySizedBox(
                                          widthFactor: (e.value.abs() / 5.0).clamp(0.0, 1.0), // Normalize
                                          child: Container(
                                            height: 4, 
                                            decoration: BoxDecoration(
                                              color: _getColorForChange(e.value),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 45, child: Text('${e.value.toStringAsFixed(2)}%', textAlign: TextAlign.end, style: TextStyle(color: _getColorForChange(e.value), fontSize: 11, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                );
              }
            }
          ),
        ],
      ),
    );
  }

  Color _getColorForChange(double pChange) {
    final colors = context.colors;
    if (pChange > 0) return colors.marketPositiveIndicator;
    if (pChange == 0) return colors.textTertiary;
    return colors.marketNegativeIndicator;
  }

  // --- New Market Heatmap Section ---

  Widget _buildHeatmapSection() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      // Logic to determine title
      String title = _showingIndices ? "Market Heatmap (Indices)" : "Heatmap: $_selectedSymbol";

      return Container(
          decoration: BoxDecoration(
            color: isDark
                ? context.colors.cardSurface.withValues(alpha: 0.60)
                : context.colors.cardSurface.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border.withValues(alpha: isDark ? 0.35 : 0.5)),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (!_showingIndices)
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: isDark ? Colors.white : Colors.black87,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _onBackToIndices,
                              ),
                            if (!_showingIndices) const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isHeatmapExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color:
                                    isDark ? Colors.white70 : Colors.black54,
                              ),
                              onPressed: () => setState(
                                () =>
                                    _isHeatmapExpanded = !_isHeatmapExpanded,
                              ),
                              tooltip: _isHeatmapExpanded
                                  ? 'Minimize Section'
                                  : 'Expand Section',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const GlobalTimeFrameBar(
                        variant: GlobalTimeFrameVariant.dropdown,
                        dropdownWidth: 72,
                      ),
                    ],
                  ),
                  if (_isHeatmapExpanded) ...[
                      const SizedBox(height: 12),
                      _buildHeatmapGrid(),
                  ]
              ],
          ),
      );
  }

  void _onBackToIndices() {
      setState(() {
          _showingIndices = true;
          _selectedSymbol = "";
          _isHeatmapExpanded = true; // Reset expansion when going back
      });
      _fetchData();
  }

  void _onHeatmapItemTap(String symbol, double value) {
      if (_showingIndices) {
          // Drill down
          setState(() {
              _showingIndices = false;
              _selectedSymbol = symbol;
              _isHeatmapExpanded = true; // Keep expanded to show constituents
          });
          _fetchData();
      } else {
          // Select stock but don't drill further (unless we have stock details)
          // Just update generalized view
          setState(() {
              _selectedSymbol = symbol;
              _isHeatmapExpanded = false; // Minimize heatmap to show details below
          });
          // Also fetch history/seasonality for this stock
          context.read<MarketProvider>().loadHistoricalPerformance(symbol);
          context.read<MarketProvider>().loadSeasonality(symbol);
      }
  }

  Widget _buildHeatmapGrid() {
      return provider_pkg.Selector<MarketProvider, Map<String, double>?>(
          selector: (_, p) => p.heatmapValues,
          builder: (context, data, child) {
              final isLoading = provider_pkg.Provider.of<MarketProvider>(context, listen: false).isLoading;
              if (isLoading && (data == null || data.isEmpty)) {
                  return const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(strokeWidth: 2),
                  ));
              }
              if (data == null || data.isEmpty) {
                  if (!_emittedHeatmapEmpty) {
                    _emittedHeatmapEmpty = true;
                    ProductTelemetry.instance.emptyState('market_heatmap_empty');
                  }
                  return const Center(child: Text("No heatmap data available", style: TextStyle(color: Colors.white38)));
              }
              _emittedHeatmapEmpty = false;
              
              return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 120, // Responsive width
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                  ),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                      final symbol = data.keys.elementAt(index);
                      final value = data.values.elementAt(index);
                      return _buildHeatmapCard(symbol, value);
                  },
              );
          },
      );
  }

  Widget _buildHeatmapCard(String symbol, double value) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return _HoverableMarketHeatmapCard(
        symbol: symbol,
        value: value,
        isDark: isDark,
        onTap: () => _onHeatmapItemTap(symbol, value),
      );
  }

}

class _HoverableHeatmapCell extends StatefulWidget {
  final double? val;
  final Color baseColor;
  final Color glowColor;

  const _HoverableHeatmapCell({
    Key? key,
    required this.val,
    required this.baseColor,
    required this.glowColor,
  }) : super(key: key);

  @override
  State<_HoverableHeatmapCell> createState() => _HoverableHeatmapCellState();
}

class _HoverableHeatmapCellState extends State<_HoverableHeatmapCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered && widget.val != null ? 1.12 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 32,
          decoration: BoxDecoration(
            color: widget.baseColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: _isHovered && widget.val != null
                ? [
                    BoxShadow(
                      color: widget.glowColor.withOpacity(0.6), // Boosted glow opacity
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.val != null ? widget.val!.toStringAsFixed(1) : '-',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: widget.val != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverableMarketHeatmapCard extends StatefulWidget {
  final String symbol;
  final double value;
  final bool isDark;
  final VoidCallback onTap;

  const _HoverableMarketHeatmapCard({
    Key? key,
    required this.symbol,
    required this.value,
    required this.isDark,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_HoverableMarketHeatmapCard> createState() => _HoverableMarketHeatmapCardState();
}

class _HoverableMarketHeatmapCardState extends State<_HoverableMarketHeatmapCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    Color textColor;
    Color borderOutlineColor;
    List<BoxShadow> glowShadows;

    final themeColors = context.colors;
    if (widget.value > 0) {
      cardColor = themeColors.marketPositiveIndicator;
      textColor = themeColors.marketPositiveIndicator;
      borderOutlineColor = cardColor.withValues(alpha: 0.12);
      glowShadows = _isHovered ? [
        BoxShadow(
          color: cardColor.withValues(alpha: 0.6),
          blurRadius: 16,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        )
      ] : (widget.isDark ? [
        BoxShadow(
          color: cardColor.withValues(alpha: 0.12),
          blurRadius: 12,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        )
      ] : []);
    } else if (widget.value < 0) {
      cardColor = themeColors.marketNegativeIndicator;
      textColor = themeColors.marketNegativeIndicator;
      borderOutlineColor = cardColor.withValues(alpha: 0.12);
      glowShadows = _isHovered ? [
        BoxShadow(
          color: cardColor.withValues(alpha: 0.6),
          blurRadius: 16,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        )
      ] : (widget.isDark ? [
        BoxShadow(
          color: cardColor.withValues(alpha: 0.12),
          blurRadius: 12,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        )
      ] : []);
    } else {
      cardColor = themeColors.textTertiary;
      textColor = themeColors.textTertiary;
      borderOutlineColor = cardColor.withValues(alpha: 0.12);
      glowShadows = [];
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderOutlineColor, width: 1.0),
              boxShadow: glowShadows,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.symbol,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'Hanken Grotesk',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "${widget.value > 0 ? '+' : ''}${widget.value.toStringAsFixed(2)}%",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
