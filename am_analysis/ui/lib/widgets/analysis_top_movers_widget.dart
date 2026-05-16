import 'package:flutter/material.dart';
import 'dart:convert';
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
    this.authToken,
    super.key,
  });

  final String portfolioId;
  final ds.TimeFrame initialTimeFrame;
  final double? height;
  final bool showTimeFrameSelector;
  final String? authToken;

  @override
  State<AnalysisTopMoversWidget> createState() => _AnalysisTopMoversWidgetState();
}

class _AnalysisTopMoversWidgetState extends State<AnalysisTopMoversWidget> {
  late final RealAnalysisService _service;
  late ds.TimeFrame _selectedTimeFrame;
  bool _isLoading = true;
  String? _error;
  List<MoverItem> _movers = [];

  @override
  void initState() {
    super.initState();
    _selectedTimeFrame = widget.initialTimeFrame;
    _initService();
  }

  Future<void> _initService() async {
    if (widget.authToken != null) {
      _service = RealAnalysisService(authToken: widget.authToken);
    } else {
      final storage = SecureStorageService();
      final token = await storage.getAccessToken();
      _service = RealAnalysisService(authToken: token != null ? 'Bearer $token' : null);
    }
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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error loading data';
        if (e is ApiException) {
          try {
            final body = jsonDecode(e.message ?? '{}');
            errorMessage = body['message'] ?? 'Server error (500)';
          } catch (_) {
            errorMessage = e.message ?? 'API Error';
          }
        } else {
          errorMessage = e.toString();
        }
        
        setState(() {
          _error = errorMessage;
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
        final padding = isMobile ? 12.0 : 16.0;

        // Header and filter row
        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_graph,
                      size: isMobile ? 20 : 24,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Top Movers',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  SizedBox(
                    width: isMobile ? 16 : 20,
                    height: isMobile ? 16 : 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            if (widget.showTimeFrameSelector) ...[
              ds.TimeFrameSelector.trading(
                selectedTimeFrame: _selectedTimeFrame,
                onTimeFrameChanged: _onTimeFrameChanged,
                compact: true,
              ),
              SizedBox(height: isMobile ? 12 : 16),
            ],
          ],
        );

        final content = _buildContent(isMobile, isTablet);

        return SizedBox(
          height: height,
          child: ds.AppCard(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.all(padding),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
            child: isMobile 
              ? Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    header,
                    content,
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    header,
                    Expanded(child: content),
                  ],
                ),
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
            Opacity(
              opacity: 0.1,
              child: Icon(Icons.swap_vert, size: isMobile ? 64 : 80),
            ),
            const SizedBox(height: 16),
            Text(
              'Market movers temporarily unavailable',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: isMobile ? 12 : 13,
                letterSpacing: 0.2,
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

    final gainers = _movers.where((m) => m.isGainer).toList();
    final losers = _movers.where((m) => !m.isGainer).toList();

    if (gainers.isEmpty && losers.isEmpty) {
      return Center(
        child: Text(
          'No significant movers for this period',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    // Mobile: Stack naturally (parent provides scrolling)
    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (gainers.isNotEmpty) _buildMoversList('Gainers', gainers, true, isMobile),
          if (gainers.isNotEmpty && losers.isNotEmpty) const SizedBox(height: 16),
          if (losers.isNotEmpty) _buildMoversList('Losers', losers, false, isMobile),
        ],
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
            ? SingleChildScrollView(
                child: Column(
                  children: items.take(10).map((mover) => _buildMoverItem(mover, color, isMobile)).toList(),
                ),
              )
            : Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: items.take(10).length,
                  itemBuilder: (context, index) => _buildMoverItem(items[index], color, isMobile),
                ),
              ),
      ],
    );
  }

  Widget _buildMoverItem(MoverItem mover, Color color, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Symbol with colored indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              mover.symbol,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 12 : 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mover.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 13 : 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${mover.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: isMobile ? 11 : 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Percentage change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${mover.changePercentage >= 0 ? '+' : ''}${mover.changePercentage.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: color,
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '₹${mover.changeAmount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: color.withValues(alpha: 0.6),
                  fontSize: isMobile ? 10 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
