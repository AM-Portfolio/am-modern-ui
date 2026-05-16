import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart' as ds;
import '../services/real_analysis_service.dart';
import 'package:am_analysis_core/am_analysis_core.dart';

/// Responsive top movers widget with time frame selector
class AnalysisTopMoversWidget extends StatefulWidget {
  const AnalysisTopMoversWidget({
    required this.portfolioId,
    this.initialTimeFrame = ds.TimeFrame.oneDay,
    this.height,
    this.showTimeFrameSelector = true,
    this.fallbackMovers,
    super.key,
  });

  final String portfolioId;
  final ds.TimeFrame initialTimeFrame;
  final double? height;
  final bool showTimeFrameSelector;
  /// When analysis API fails (e.g. 500), show these movers from portfolio holdings.
  final List<MoverItem>? fallbackMovers;

  @override
  State<AnalysisTopMoversWidget> createState() => _AnalysisTopMoversWidgetState();
}

class _AnalysisTopMoversWidgetState extends State<AnalysisTopMoversWidget> {
  late final RealAnalysisService _service;
  late ds.TimeFrame _selectedTimeFrame;
  bool _isLoading = true;
  String? _error;
  List<MoverItem> _movers = [];
  bool _usingHoldingsFallback = false;

  @override
  void initState() {
    super.initState();
    _selectedTimeFrame = widget.initialTimeFrame;
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
      print('[TopMovers] Loading data for portfolio=${widget.portfolioId}, timeFrame=${_selectedTimeFrame.code}');
      final movers = await _service.getTopMovers(
        id: widget.portfolioId,
        type: AnalysisEntityType.PORTFOLIO,
        timeFrame: _selectedTimeFrame.code,
      );
      print('[TopMovers] Successfully loaded ${movers.length} movers');
      
      if (mounted) {
        setState(() {
          _movers = movers;
          _usingHoldingsFallback = false;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('[TopMovers] Error loading data: $e');
      print('[TopMovers] Stack trace: $stackTrace');
      if (mounted) {
        final fallback = widget.fallbackMovers;
        if (fallback != null && fallback.isNotEmpty) {
          setState(() {
            _movers = fallback;
            _error = null;
            _usingHoldingsFallback = true;
            _isLoading = false;
          });
          return;
        }
        final message = e.toString();
        final isServerError = message.contains('500') ||
            message.contains('currentPrice');
        setState(() {
          _error = isServerError
              ? 'Top movers temporarily unavailable'
              : 'Failed to load top movers';
          _usingHoldingsFallback = false;
          _isLoading = false;
        });
      }
    }
  }

  void _onTimeFrameChanged(ds.TimeFrame timeFrame) {
    setState(() {
      _selectedTimeFrame = timeFrame;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
        final height = widget.height ?? (isMobile ? 380 : isTablet ? 340 : 300);
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Movers',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 16 : 18,
                          ),
                        ),
                        if (_usingHoldingsFallback)
                          Text(
                            'From portfolio holdings',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
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
              SizedBox(height: isMobile ? 10 : 12),
              if (widget.showTimeFrameSelector)
                ds.TimeFrameSelector.trading(
                  selectedTimeFrame: _selectedTimeFrame,
                  onTimeFrameChanged: _onTimeFrameChanged,
                  compact: true,
                ),
              SizedBox(height: isMobile ? 12 : 16),
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
              'Error loading top movers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: isMobile ? 13 : 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    if (_movers.isEmpty) {
      return Center(
        child: Text(
          'No movers data available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: isMobile ? 13 : 14,
          ),
        ),
      );
    }

    final gainers = _movers.where((m) => m.changePercentage >= 0).toList();
    final losers = _movers.where((m) => m.changePercentage < 0).toList();

    // Mobile: Single column with horizontal scroll OR vertical stack
    if (isMobile) {
      return SingleChildScrollView(
        child: Column(
          children: [
            if (gainers.isNotEmpty) _buildMoversList('Gainers', gainers, true, isMobile),
            if (gainers.isNotEmpty && losers.isNotEmpty) const SizedBox(height: 16),
            if (losers.isNotEmpty) _buildMoversList('Losers', losers, false, isMobile),
          ],
        ),
      );
    }

    // Tablet & Web: Side by side
    return Row(
      children: [
        if (gainers.isNotEmpty) ...[
          Expanded(child: _buildMoversList('Gainers', gainers, true, isMobile)),
        ],
        if (gainers.isNotEmpty && losers.isNotEmpty) const SizedBox(width: 16),
        if (losers.isNotEmpty) ...[
          Expanded(child: _buildMoversList('Losers', losers, false, isMobile)),
        ],
      ],
    );
  }

  Widget _buildMoversList(String title, List<MoverItem> items, bool isGainer, bool isMobile) {
    final color = isGainer 
        ? (Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF00B894) : const Color(0xFF009975))
        : (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFFF7675) : const Color(0xFFE85656));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 10 : 12),
        isMobile
            ? Column(
                children: items.take(5).map((mover) => _buildMoverItem(mover, color, isMobile)).toList(),
              )
            : Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: items.take(5).length,
                  itemBuilder: (context, index) => _buildMoverItem(items[index], color, isMobile),
                ),
              ),
      ],
    );
  }

  Widget _buildMoverItem(MoverItem mover, Color color, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Symbol with colored indicator
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mover.symbol,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 13 : 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  '₹${mover.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: isMobile ? 10 : 11,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Percentage badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${mover.changePercentage >= 0 ? '+' : ''}${mover.changePercentage.toStringAsFixed(2)}%',
              style: TextStyle(
                color: color,
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
