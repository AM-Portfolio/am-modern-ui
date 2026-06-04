import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:am_design_system/am_design_system.dart' as ds;
import 'package:intl/intl.dart';

import '../../../../core/services/market_movers_service.dart';

/// A widget that displays real global market Top Gainers and Top Losers.
/// Designed to match the glassmorphism theme of the portfolio overview,
/// while providing a tabbed "Groww-style" experience.
class PortfolioMarketMoversWidget extends StatefulWidget {
  final ds.TimeFrame timeFrame;
  final double? height;

  const PortfolioMarketMoversWidget({
    required this.timeFrame,
    this.height,
    super.key,
  });

  @override
  State<PortfolioMarketMoversWidget> createState() =>
      _PortfolioMarketMoversWidgetState();
}

class _PortfolioMarketMoversWidgetState extends State<PortfolioMarketMoversWidget> {
  final MarketMoversService _service = MarketMoversService();
  final NumberFormat _currencyFormat = NumberFormat('#,##,###.##', 'en_IN');

  bool _isLoading = true;
  MarketMoversData? _data;
  bool _showGainers = true; // true = Gainers tab, false = Losers tab

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant PortfolioMarketMoversWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timeFrame != oldWidget.timeFrame) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _service.fetchMarketMovers(
      limit: 5,
      indexSymbol: 'NIFTY 50',
      timeFrame: widget.timeFrame.code,
    );

    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
        
        // Auto-switch to Losers tab if there are no gainers but there are losers
        if (data.gainers.isEmpty && data.losers.isNotEmpty) {
          _showGainers = false;
        } else if (data.gainers.isNotEmpty) {
          _showGainers = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withOpacity(isDark ? 0.4 : 0.6),
            cardColor.withOpacity(isDark ? 0.2 : 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Market Movers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NIFTY 50 • ${widget.timeFrame.code}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tabs
              _buildTabs(isDark),
              
              const SizedBox(height: 16),

              // Content List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _buildMoversList(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Row(
      children: [
        _buildTabButton('Top Gainers', true, isDark),
        const SizedBox(width: 8),
        _buildTabButton('Top Losers', false, isDark),
      ],
    );
  }

  Widget _buildTabButton(String title, bool isGainersTab, bool isDark) {
    final isSelected = _showGainers == isGainersTab;
    final color = isGainersTab ? const Color(0xFF00B894) : const Color(0xFFFF7675);

    return InkWell(
      onTap: () {
        setState(() {
          _showGainers = isGainersTab;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : (isDark ? Colors.white24 : Colors.black12),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildMoversList(bool isDark) {
    final list = _showGainers ? (_data?.gainers ?? []) : (_data?.losers ?? []);

    if (list.isEmpty) {
      return Center(
        child: Text(
          'No market data available.',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: list.length,
      separatorBuilder: (context, index) => Divider(
        color: Theme.of(context).dividerColor.withOpacity(0.1),
        height: 16,
      ),
      itemBuilder: (context, index) {
        final item = list[index];
        final isGainer = item.changePercent >= 0;
        final color = isGainer ? const Color(0xFF00B894) : const Color(0xFFFF7675);

        return Row(
          children: [
            // Rank Badge
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Symbol & Company
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.companyName,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Price & Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${_currencyFormat.format(item.lastPrice)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${isGainer ? '+' : ''}${item.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.05, end: 0);
      },
    );
  }
}
