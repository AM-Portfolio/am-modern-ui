import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';
import '../services/real_analysis_service.dart';
import '../models/analysis_models.dart';
import '../models/analysis_enums.dart';

/// Enhanced responsive allocation widget with horizontal stacked bar chart
class AnalysisAllocationWidget extends StatefulWidget {
  const AnalysisAllocationWidget({
    required this.portfolioId,
    this.groupBy = GroupBy.sector,
    this.height,
    super.key,
  });

  final String portfolioId;
  final GroupBy groupBy;
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

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final storage = SecureStorageService();
    final token = await storage.getAccessToken();
    _service = RealAnalysisService(authToken: token != null ? 'Bearer $token' : null);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.getAllocation(
        widget.portfolioId,
        AnalysisEntityType.PORTFOLIO,
        groupBy: widget.groupBy,
      );
      
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
        final height = widget.height ?? (isMobile ? 350 : isTablet ? 320 : 300);
        final padding = isMobile ? 16.0 : 20.0;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
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
                  Flexible(
                    child: Text(
                      'Allocation by ${widget.groupBy.value}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isLoading)
                    SizedBox(
                      width: isMobile ? 16 : 20,
                      height: isMobile ? 16 : 20,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 20),
              Expanded(
                child: _buildContent(isMobile, isTablet),
              ),
            ],
          ),
        );
      },
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStackedBar(isMobile),
        SizedBox(height: isMobile ? 16 : 24),
        Expanded(
          child: _buildLegend(isMobile, isTablet),
        ),
      ],
    );
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
                        child: _hoveredIndex == index && !isMobile
                            ? Text(
                                '${item.percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 10 : 12,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
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

  Widget _buildLegend(bool isMobile, bool isTablet) {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final color = _getColorForIndex(context, index);
        final isHovered = _hoveredIndex == index;
        
        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredIndex = index),
          onExit: (_) => setState(() => _hoveredIndex = null),
          child: GestureDetector(
            onTap: () => setState(() => _hoveredIndex = isHovered ? null : index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              constraints: const BoxConstraints(minHeight: 44), // Touch target
              decoration: BoxDecoration(
                color: isHovered 
                    ? color.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isHovered
                      ? color.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: isMobile ? 3 : 4,
                    height: isMobile ? 32 : 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 13 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${_formatNumber(item.value)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: isMobile ? 11 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
