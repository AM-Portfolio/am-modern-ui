import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';
import '../services/real_analysis_service.dart';
import 'package:am_analysis_core/am_analysis_core.dart';
import 'package:am_design_system/am_design_system.dart' as ds;

/// Enhanced responsive allocation widget with horizontal stacked bar chart
class AnalysisAllocationWidget extends StatefulWidget {
  const AnalysisAllocationWidget({
    required this.portfolioId,
    this.groupBy = GroupBy.sector,
    this.initialTimeFrame = ds.TimeFrame.oneMonth,
    this.height,
    super.key,
  });

  final String portfolioId;
  final GroupBy groupBy;
  final ds.TimeFrame initialTimeFrame;
  final double? height;

  @override
  State<AnalysisAllocationWidget> createState() => _AnalysisAllocationWidgetState();
}

class _AnalysisAllocationWidgetState extends State<AnalysisAllocationWidget> {
  late final RealAnalysisService _service;
  bool _isLoading = true;
  String? _error;
  List<AllocationItem> _items = [];
  int? _hoveredIndex;
  late GroupBy _selectedGroupBy;
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    _selectedGroupBy = widget.groupBy;
    _initService();
  }

  Future<void> _initService() async {
    final storage = SecureStorageService();
    final token = await storage.getAccessToken();
    _service = RealAnalysisService(authToken: token != null ? 'Bearer $token' : null);
    _loadData();
  }

  Future<void> _loadData({int attempt = 0}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.getAllocation(
        widget.portfolioId,
        AnalysisEntityType.PORTFOLIO,
        groupBy: _selectedGroupBy,
      );

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      final message = e.toString();
      final isNetworkError = message.contains('Failed to fetch') ||
          message.contains('HTTP connection failed');
      if (isNetworkError && attempt < 1) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (mounted) return _loadData(attempt: attempt + 1);
      }
      if (mounted) {
        setState(() {
          _error = isNetworkError
              ? 'Could not reach allocation service. Check connection and retry.'
              : 'Error loading allocation data';
          _isLoading = false;
        });
      }
    }
  }

  void _onGroupByChanged(GroupBy groupBy) {
    if (_selectedGroupBy == groupBy) return;
    setState(() {
      _selectedGroupBy = groupBy;
    });
    _loadData();
  }

  String _getGroupByDisplayName(GroupBy groupBy) {
    switch (groupBy) {
      case GroupBy.sector:
        return 'SECTOR';
      case GroupBy.industry:
        return 'INDUSTRY';
      case GroupBy.marketCap:
        return 'MARKET CAP';
      case GroupBy.stock:
        return 'STOCK';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
        final height = widget.height ?? (isMobile ? 500 : isTablet ? 480 : 450); // Increased height for selector and badges
        final padding = isMobile ? 14.0 : 16.0;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Allocation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 15 : 16,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildGroupSelector(isMobile),
              SizedBox(height: isMobile ? 12 : 14),
              Expanded(
                child: _buildContent(isMobile, isTablet),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupSelector(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGroupOption(GroupBy.sector, 'Sector', isMobile),
          _buildGroupOption(GroupBy.industry, 'Industry', isMobile),
          _buildGroupOption(GroupBy.marketCap, 'Cap', isMobile),
        ],
      ),
    );
  }

  Widget _buildGroupOption(GroupBy group, String label, bool isMobile) {
    final isSelected = _selectedGroupBy == group;
    return GestureDetector(
      onTap: () => _onGroupByChanged(group),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 11 : 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected 
                ? Colors.white 
                : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isMobile, bool isTablet) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, 
              color: Theme.of(context).colorScheme.error, 
              size: isMobile ? 40 : 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Error loading data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: isMobile ? 13 : 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44, // Touch target
              child: ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'No allocation data available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: isMobile ? 13 : 14,
          ),
        ),
      );
    }

    // Get top 5 items for display
    final topItems = _items.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stacked Bar with labels
        _buildStackedBar(isMobile),
        SizedBox(height: isMobile ? 12 : 16),
        
        Text(
          'Top ${topItems.length} ${_getGroupByDisplayName(_selectedGroupBy)}s',
          style: TextStyle(
            fontSize: isMobile ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: ListView.builder(
            itemCount: topItems.length + (_items.length > 5 ? 1 : 0),
            padding: EdgeInsets.zero,
            itemBuilder: (context, i) {
              if (i == topItems.length) {
                // "Show more" item
                return Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Center(
                    child: Text(
                      '+${_items.length - 5} more',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              final index = i;
              final item = topItems[index];
              final color = _getColorForIndex(context, index);
              final isExpanded = _expandedIndices.contains(index);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedIndices.remove(index);
                          } else {
                            _expandedIndices.add(index);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Increased padding
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(8),
                            topRight: const Radius.circular(8),
                            bottomLeft: isExpanded ? Radius.zero : const Radius.circular(8),
                            bottomRight: isExpanded ? Radius.zero : const Radius.circular(8),
                          ),
                          border: Border.all(
                            color: color.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color, // Ensure visible color
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 20,
                              color: color,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border(
                            left: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
                            right: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
                            bottom: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Header Row
                            Row(
                              children: [
                                Expanded(
                                  flex: 3, 
                                  child: Text(
                                    "HOLDING", 
                                    style: TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
                                    )
                                  )
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "% SECTOR", 
                                    textAlign: TextAlign.end, 
                                    style: TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
                                    )
                                  )
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "% PORTFOLIO", 
                                    textAlign: TextAlign.end, 
                                    style: TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
                                    )
                                  )
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            // Holdings List
                            if (item.holdings != null && item.holdings!.isNotEmpty)
                              ...item.holdings!.take(7).map((h) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        h.symbol,
                                        style: TextStyle(
                                          fontSize: 12, 
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).textTheme.bodyMedium?.color
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${h.percentage.toStringAsFixed(1)}%',
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).textTheme.bodyMedium?.color // Ensure Visible
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${h.portfolioPercentage.toStringAsFixed(1)}%',
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).textTheme.bodySmall?.color // Slightly lighter
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                            else
                              const Center(child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("No holdings data"),
                              )),
                            
                            if (item.holdings != null && item.holdings!.length > 7)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '+ ${item.holdings!.length - 7} more holdings',
                                  style: TextStyle(fontSize: 11, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getSectorAbbreviation(String name) {
    // Get first 2-3 letters of sector name
    if (name.length <= 3) return name.toUpperCase();
    
    // For multi-word names, take first letter of each word
    final words = name.split(' ');
    if (words.length > 1) {
      return words.take(2).map((w) => w[0]).join('').toUpperCase();
    }
    
    // Otherwise first 3 letters
    return name.substring(0, 3).toUpperCase();
  }


  Widget _buildStackedBar(bool isMobile) {
    final barHeight = isMobile ? 50.0 : 60.0;
    
    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        child: Row(
          children: _items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final color = _getColorForIndex(context, index);
            final abbreviation = _getSectorAbbreviation(item.name);
            
            // Only show label if segment is big enough (>= 5%)
            final showLabel = item.percentage >= 0.05;
            
            return Expanded(
              flex: (item.percentage * 100).round(),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredIndex = index),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: GestureDetector(
                  onTap: () => setState(() => _hoveredIndex = index),
                  child: Tooltip(
                    message: '${item.name}\n₹${_formatNumber(item.value)}\n${item.percentage.toStringAsFixed(1)}%',
                    preferBelow: false,
                    child: Container(
                      color: color.withValues(alpha: _hoveredIndex == index ? 1.0 : 0.9),
                      child: Center(
                        child: showLabel
                            ? Text(
                                _hoveredIndex == index && !isMobile
                                    ? '${item.percentage.toStringAsFixed(1)}%'
                                    : abbreviation,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 9 : (_hoveredIndex == index ? 12 : 10),
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

  }


  String _formatNumber(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)} L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)} K';
    }
    return value.toStringAsFixed(2);
  }

  List<Color> _getSectorColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [
            const Color(0xFF6C5DD3),
            const Color(0xFF00B894),
            const Color(0xFFFFA502),
            const Color(0xFFFF7675),
            const Color(0xFF74B9FF),
            const Color(0xFFFD79A8),
          ]
        : [
            const Color(0xFF5B4AC4),
            const Color(0xFF009975),
            const Color(0xFFE89400),
            const Color(0xFFE85656),
            const Color(0xFF5BA0E8),
            const Color(0xFFE56A91),
          ];
  }

  Color _getColorForIndex(BuildContext context, int index) {
    final colors = _getSectorColors(context);
    return colors[index % colors.length];
  }
}
