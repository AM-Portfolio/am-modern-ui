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
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final toggleBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    
    return AmGlassCard(
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
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: onSurface,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Gainers / Losers Toggle
          Container(
            decoration: BoxDecoration(
              color: toggleBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('Gainers', true, isDark),
                _buildToggleButton('Losers', false, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Table Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isDark ? Colors.transparent : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ticker',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Price',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Change',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: items.map((item) => _buildMoverItem(item, isDark)).toList(),
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
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final isPositive = item.changePercentage >= 0;
    
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        hoverColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Symbol & Name
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        item.symbol,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: onSurface,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Tooltip(
                        message: item.name,
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurfaceVariant,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Price and Percentage
              Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      currencyFormat.format(item.price),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${isPositive ? "+" : ""}${item.changePercentage.toStringAsFixed(2)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
