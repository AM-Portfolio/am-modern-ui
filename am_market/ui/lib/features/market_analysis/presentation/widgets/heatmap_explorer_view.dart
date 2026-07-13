import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:provider/provider.dart' show ReadContext, WatchContext;
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/shared/widgets/glass_container.dart';
import 'package:intl/intl.dart';
import 'package:am_market_common/models/historical_performance_model.dart';
import 'package:am_market_common/models/seasonality_model.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/historical_performance_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/shared/widgets/selectors/global_time_frame_bar.dart';

class HeatmapExplorerView extends ConsumerStatefulWidget {
  const HeatmapExplorerView({super.key});

  @override
  ConsumerState<HeatmapExplorerView> createState() => _HeatmapExplorerViewState();
}

class _HeatmapExplorerViewState extends ConsumerState<HeatmapExplorerView> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  String _selectedSymbol = 'NIFTY BANK'; // Default symbol
  final List<String> _months = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
  ];

  final List<String> _shortMonths = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];
  
  late TextEditingController _searchController;

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
    _searchController = TextEditingController(text: _selectedSymbol);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
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
    
    context.read<MarketProvider>().loadHeatmap(heatmapTarget, _heatmapTimeframe);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = provider_pkg.Provider.of<MarketProvider>(context, listen: false);

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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF0F0F1A), // Deep shadow
                  Color(0xFF151524), // Custom base shade (rgba(21, 21, 36, 1))
                  Color(0xFF1F1F35), // Subtle lighter highlight
                ]
              : const [
                  Color(0xFFF5F5FC), // Light lilac backdrop
                  Color(0xFFECECF8), // Base light theme shade
                  Color(0xFFE2E2F2), // Subtle accent light highlight
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Header & Search
            Container(
              padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C).withOpacity(0.4) : AppColors.lightCard.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
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
              // Title REMOVED or Changed to Generic
              /*
              const Text(
                'Historical Performance',
                style: TextStyle(...),
              ),
              const SizedBox(height: 16),
              */
              
              // Search & Controls Row
              Row(
                children: [
                   // Expanded Search Field
                   Expanded(
                     child: Container(
                       height: 48,
                       decoration: BoxDecoration(
                         color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
                       ),
                       child: TextField(
                         controller: _searchController,
                         style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                         decoration: InputDecoration(
                           hintText: 'Search Symbol (e.g. RELIANCE, NIFTY 50)',
                           hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                           prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
                           border: InputBorder.none,
                           contentPadding: const EdgeInsets.symmetric(vertical: 14),
                         ),
                         onSubmitted: (value) {
                           if (value.isNotEmpty) {
                             setState(() {
                               _selectedSymbol = value.toUpperCase();
                             });
                             _fetchData();
                           }
                         },
                       ),
                     ),
                   ),
                   const SizedBox(width: 12),
                   
                   // Go Button
                   GestureDetector(
                     onTap: () {
                        if (_searchController.text.isNotEmpty) {
                           setState(() {
                             _selectedSymbol = _searchController.text.toUpperCase();
                           });
                           _fetchData();
                        }
                     },
                     child: Container(
                       height: 48,
                       padding: const EdgeInsets.symmetric(horizontal: 24),
                       decoration: BoxDecoration(
                         gradient: const LinearGradient(
                           colors: [Color(0xFF00D1FF), Color(0xFF0055FF)],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                         ),
                         borderRadius: BorderRadius.circular(12),
                         boxShadow: [
                           BoxShadow(
                             color: const Color(0xFF0055FF).withOpacity(0.3),
                             blurRadius: 8,
                             offset: const Offset(0, 4),
                           )
                         ],
                       ),
                        child: Center(
                          child: provider_pkg.Selector<MarketProvider, bool>(
                            selector: (_, p) => p.isLoading,
                            builder: (context, isLoading, child) {
                              return isLoading 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text(
                                      'GO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    );
                            },
                          ),
                        ),
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 12),
              
                  // Quick Suggestions
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickActionChip(provider, "NIFTY BANK", "NIFTY BANK"),
                        _buildQuickActionChip(provider, "NIFTY IT", "NIFTY IT"),
                        _buildQuickActionChip(provider, "MIDCAP", "NIFTY MIDCAP 50"),
                        _buildQuickActionChip(provider, "INDIA VIX", "INDIA VIX"),
                        _buildQuickActionChip(provider, "NIFTY 50", "NIFTY 50"),
                        // Note: Using "NIFTY SMLCAP 50" to match database index symbol
                        _buildQuickActionChip(provider, "SMALL CAP", "NIFTY SMLCAP 50"),
                      ],
                    ),
                  )
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Main Content Area
        Expanded(
          child: _showingIndices
            ? SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _buildHeatmapSection(),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2C).withOpacity(0.4) : AppColors.lightCard.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
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
                    const SizedBox(height: 16),
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
                                  color: isDark ? const Color(0xFF1E1E2C).withOpacity(0.4) : AppColors.lightCard.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
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
                                                                final baseColor = val != null ? _getColorForChange(val).withOpacity(0.8) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05));
                                                                final glowColor = (val != null && val >= 0) ? const Color(0xFF47E266).withOpacity(0.3) : const Color(0xFFFFB4AB).withOpacity(0.3);
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
        color: isDark ? const Color(0xFF1E1E2C).withOpacity(0.4) : AppColors.lightCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
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
      if (pChange > 0) return const Color(0xFF47E266); // Success Green
      if (pChange == 0) return const Color(0xFF918FA0); // Outline/Neutral Gray
      return const Color(0xFFFFB4AB); // Error Red
  }

  // --- New Market Heatmap Section ---

  Widget _buildHeatmapSection() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      // Logic to determine title
      String title = _showingIndices ? "Market Heatmap (Indices)" : "Heatmap: $_selectedSymbol";

      return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C).withOpacity(0.4) : AppColors.lightCard.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
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
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                          Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  if (!_showingIndices)
                                    IconButton(
                                        icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: _onBackToIndices,
                                    ),
                                  if (!_showingIndices) const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                      icon: Icon(_isHeatmapExpanded ? Icons.expand_less : Icons.expand_more, color: isDark ? Colors.white70 : Colors.black54),
                                      onPressed: () => setState(() => _isHeatmapExpanded = !_isHeatmapExpanded),
                                      tooltip: _isHeatmapExpanded ? "Minimize Section" : "Expand Section",
                                  ),
                              ],
                          ),
                          // Timeframe Selector
                          // Align global timeframe bar cleanly on the right (or stacked on mobile)
                          if (_isHeatmapExpanded)
                            GlobalTimeFrameBar(),
                      ],
                  ),
                  if (_isHeatmapExpanded) ...[
                      const SizedBox(height: 20),
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
          _searchController.clear();
          _isHeatmapExpanded = true; // Reset expansion when going back
      });
      _fetchData();
  }

  void _onHeatmapTimeframeChanged(String tf) {
      setState(() {
          _heatmapTimeframe = tf;
      });
      _fetchHeatmapData();
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
                  return const Center(child: Text("No heatmap data available", style: TextStyle(color: Colors.white38)));
              }
              
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

  Widget _buildQuickActionChip(MarketProvider provider, String label, String symbol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = _selectedSymbol == symbol;
    return GestureDetector(
      onTap: () {
        setState(() {
          _showingIndices = false; // Drill down into this index
          _selectedSymbol = symbol;
          _searchController.text = symbol;
        });
        _fetchData();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2))
              : (isSelected ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? (isDark ? Colors.white54 : Colors.black26) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(isSelected ? 1 : 0.7)
                : Colors.black.withOpacity(isSelected ? 1 : 0.7),
            fontSize: 12,
          ),
        ),
      ),
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

    if (widget.value > 0) {
      cardColor = const Color(0xFF47E266);
      textColor = const Color(0xFF47E266);
      borderOutlineColor = cardColor.withOpacity(0.12);
      glowShadows = _isHovered ? [
        BoxShadow(
          color: cardColor.withOpacity(0.6),
          blurRadius: 16,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        )
      ] : (widget.isDark ? [
        BoxShadow(
          color: cardColor.withOpacity(0.12),
          blurRadius: 12,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        )
      ] : []);
    } else if (widget.value < 0) {
      cardColor = const Color(0xFFFFB4AB);
      textColor = const Color(0xFFFFB4AB);
      borderOutlineColor = cardColor.withOpacity(0.12);
      glowShadows = _isHovered ? [
        BoxShadow(
          color: cardColor.withOpacity(0.6),
          blurRadius: 16,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        )
      ] : (widget.isDark ? [
        BoxShadow(
          color: cardColor.withOpacity(0.12),
          blurRadius: 12,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        )
      ] : []);
    } else {
      cardColor = const Color(0xFF918FA0);
      textColor = const Color(0xFF918FA0);
      borderOutlineColor = cardColor.withOpacity(0.12);
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
