import 'package:am_dashboard_ui/domain/models/top_movers_response.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'glass_card.dart';

/// Pixel-perfect Lumina Market Movers widget based on image.
class DashboardRankingWidget extends StatefulWidget {
  final List<MoverItem> gainers;
  final List<MoverItem> losers;

  const DashboardRankingWidget({
    super.key,
    required this.gainers,
    required this.losers,
  });

  factory DashboardRankingWidget.errorState() {
    return const DashboardRankingWidget(gainers: [], losers: []);
  }

  @override
  State<DashboardRankingWidget> createState() => _DashboardRankingWidgetState();
}

class _DashboardRankingWidgetState extends State<DashboardRankingWidget> {
  bool _showGainers = true;

  @override
  Widget build(BuildContext context) {
    final items = _showGainers ? widget.gainers : widget.losers;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic Colors
    final onSurface = isDark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final toggleBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6F8);
    
    return AmGlassCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Market Movers',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: onSurface,
                  fontFamily: 'Inter',
                ),
              ),
              // Gainers / Losers Toggle
              Container(
                decoration: BoxDecoration(
                  color: toggleBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildToggleButton('Gainers', true, isDark),
                    _buildToggleButton('Losers', false, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No data available',
                  style: TextStyle(
                    color: onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            )
          else
            Column(
              children: items.map((item) => _buildMoverItem(item, isDark)).toList(),
            ),
            
          const Spacer(),
          // Bottom button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'EXPLORE MARKET FEEDS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: onSurface,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isGainers, bool isDark) {
    final isSelected = _showGainers == isGainers;
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    return GestureDetector(
      onTap: () => setState(() => _showGainers = isGainers),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.white : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected 
                ? (isDark ? Colors.black : const Color(0xFF111827)) 
                : onSurfaceVariant,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildMoverItem(MoverItem item, bool isDark) {
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2);
    final isPositive = item.changePercentage >= 0;
    
    // Exact colors from image
    final boxColor = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFF0F4FF); // light blue box
    final boxBorder = isDark ? const Color(0xFF2563EB) : const Color(0xFFD6E4FF); // slightly darker border
    final tickerColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF004CCA);
    final onSurface = isDark ? Colors.white : const Color(0xFF0B1C30);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF737687);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo / Ticker Box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: boxBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              item.symbol.substring(0, 1),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: tickerColor,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name and Ticker
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: onSurface,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.symbol,
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          // Price and Percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(item.price),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: onSurface,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 6),
              // Colored percentage bar layout
              Row(
                children: [
                  Text(
                    '${isPositive ? "+" : ""}${item.changePercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? const Color(0xFF00C853) : const Color(0xFFD50000),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isPositive ? const Color(0xFF00C853) : const Color(0xFFD50000),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
