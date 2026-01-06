import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/trade_holding_view_model.dart';

class ModernTradeHeader extends StatefulWidget {
  const ModernTradeHeader({required this.trade, required this.onClose, required this.onFilterChanged, this.onSymbolTap, super.key});

  final TradeHoldingViewModel trade;
  final VoidCallback? onClose;
  final ValueChanged<String?> onFilterChanged;
  final Function(String symbol)? onSymbolTap;

  @override
  State<ModernTradeHeader> createState() => _ModernTradeHeaderState();
}

class _ModernTradeHeaderState extends State<ModernTradeHeader> with SingleTickerProviderStateMixin {
  late AnimationController _shineController;
  late Animation<double> _shineAnimation;
  bool _showDetails = true;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this)..repeat();

    _shineAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _shineController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = widget.trade.isProfit;
    final statusColor = _getStatusColor(widget.trade.status);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        return isMobile ? _buildMobileLayout(context, statusColor, isProfit) : _buildDesktopLayout(context, statusColor, isProfit);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Color statusColor, bool isProfit) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Clean white background for the header section
        borderRadius: BorderRadius.circular(16), // Rounded corners
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
           padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               // Top Row: Back Button and Main Info
               Row(
                 children: [
                   // Back Button with Animation
                   _buildBackButton(context),
                   const SizedBox(width: 20),

                // Main Trade Info Card
                Expanded(
                  child: _buildDesktopInfoCard(context, statusColor),
                ),
                const SizedBox(width: 20),

                // P&L Showcase Card with Shine Effect
                _buildDesktopPnLCard(context, isProfit),
              ],
            ),

            const SizedBox(height: 16),

            // Bottom Row: Filter and Details Toggle
            Row(
              children: [
                // Filter by Symbol
                Expanded(
                  child: _buildSearchBar(context),
                ),
                const SizedBox(width: 16),

                // Details Toggle Button
                _buildDetailsToggle(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Color statusColor, bool isProfit) {
    return Container(
      color: const Color(0xFFF5F5F5), // Background color match
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Navigation Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBackButton(context, isCompact: true),
                const Text(
                  'Trade Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // Moon Icon / Context Action
                 Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.nightlight_round, size: 20, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main Compact Card (White Theme)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // P&L Badge (Top Right)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                           colors: [
                               const Color(0xFF00C853), // Material Green A700
                               const Color(0xFF00E676), // Material Green A400
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.trade.displayProfitLossPercentage,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.trade.displayProfitLoss,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Main Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Symbol & Status
                        Row(
                          children: [
                            Text(
                              widget.trade.displaySymbol,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C4DFF), // Purple
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Subtitle
                        Text(
                          "${widget.trade.displaySymbol} - ${widget.trade.displayCompanyName} Corp.",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tags Row
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Mobile Tags (Reusing specific tag builder if possible, or recreating styles)
                             if (widget.trade.tradePositionType != null)
                              _buildSpecificTag(
                                context, 
                                widget.trade.tradePositionType == 'LONG' ? Icons.trending_up : Icons.trending_down, 
                                widget.trade.tradePositionType!, 
                                widget.trade.tradePositionType == 'LONG' ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9), 
                                widget.trade.tradePositionType == 'LONG' ? const Color(0xFFD32F2F) : const Color(0xFF388E3C),
                              ),
                             _buildSpecificTag(context, Icons.pie_chart, "Equity", const Color(0xFFE3F2FD), const Color(0xFF1976D2)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Date
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              widget.trade.entryTimestamp != null
                                  ? 'Entered: ${_formatDate(widget.trade.entryTimestamp!)}'
                                  : 'Entry date unavailable',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search Bar
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Filter trade logs...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  suffixIcon: widget.onFilterChanged != null ? TextButton(
                       onPressed: () => widget.onFilterChanged(null),
                       child: const Text("HIDE", style: TextStyle(fontSize: 12, color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold)),
                  ) : null
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: widget.onFilterChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTag(String label, Color bgColor, Color textColor, IconData icon) {
     // Replaced by _buildSpecificTag but keeping for interface if needed or removing
     return _buildSpecificTag(context, icon, label, bgColor, textColor); 
  }

  Widget _buildBackButton(BuildContext context, {bool isCompact = false}) {
     return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onClose,
          borderRadius: BorderRadius.circular(isCompact ? 20 : 12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 12, vertical: 10),
            decoration: BoxDecoration(
              color: isCompact ? Colors.grey.shade100 : Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(isCompact ? 20 : 12),
              border: isCompact ? null : Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: isCompact ? 22 : 18, color: Theme.of(context).colorScheme.onSurface),
                if (!isCompact) ...[
                   const SizedBox(width: 6),
                   Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 300)).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildDesktopInfoCard(BuildContext context, Color statusColor) {
     return Container(
        padding: const EdgeInsets.all(0), // Clean, no container padding needed if we use columns directly, or minimal
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Symbol Row with Status Badge
            Row(
              children: [
                // Symbol
                widget.onSymbolTap != null ?
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => widget.onSymbolTap!(widget.trade.displaySymbol),
                    child: Text(
                      widget.trade.displaySymbol,
                      style: const TextStyle(
                        fontSize: 28, // Larger font
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C4DFF), // Purple accent from image
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ) : 
                Text(
                  widget.trade.displaySymbol,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C4DFF),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Status Badge (Breakeven - Grey Pill)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade500, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        widget.trade.displayStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Company Name
            Text(
              "${widget.trade.displaySymbol} - ${widget.trade.displayCompanyName} Corp.", // Formatting like image
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tags Row (Long, Equity, etc)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Position Type (Red for Long)
                 if (widget.trade.tradePositionType != null)
                  _buildSpecificTag(
                    context, 
                    widget.trade.tradePositionType == 'LONG' ? Icons.trending_up : Icons.trending_down, 
                    widget.trade.tradePositionType!, 
                    widget.trade.tradePositionType == 'LONG' ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9), // Light Red/Green
                    widget.trade.tradePositionType == 'LONG' ? const Color(0xFFD32F2F) : const Color(0xFF388E3C), // Dark Red/Green
                  ),

                // Asset Class (Equity - Blue)
                _buildSpecificTag(context, Icons.pie_chart, "Equity", const Color(0xFFE3F2FD), const Color(0xFF1976D2)),

                // Market / Exchange (Purple)
                if (widget.trade.exchange != null)
                   _buildSpecificTag(context, Icons.account_balance, widget.trade.exchange!, const Color(0xFFF3E5F5), const Color(0xFF7B1FA2)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Entry Date
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  widget.trade.entryTimestamp != null
                      ? 'Entered: ${_formatDate(widget.trade.entryTimestamp!)}'
                      : 'Entry date unavailable',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildSpecificTag(BuildContext context, IconData icon, String label, Color bgColor, Color textColor) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 6),
              Text(
                label, // Title case?
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
      );
  }

  Widget _buildDesktopPnLCard(BuildContext context, bool isProfit) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                   const Color(0xFF00C853), // Material Green A700
                   const Color(0xFF00E676), // Material Green A400
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isProfit ? Colors.green : Colors.red).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.trade.displayProfitLossPercentage,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.trade.displayProfitLoss,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
               Text(
                "Unrealized P/L",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        // Shine Effect Overlay
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _shineAnimation,
            builder: (context, child) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment(-1 - _shineAnimation.value, -1),
                  end: Alignment(1 - _shineAnimation.value, 1),
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: const Duration(milliseconds: 500)).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildSearchBar(BuildContext context) {
      return SizedBox(
        height: 44,
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Filter similar trades by symbol...',
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () => widget.onFilterChanged(null),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: widget.onFilterChanged,
        ),
      );
  }

  Widget _buildDetailsToggle(BuildContext context) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _showDetails = !_showDetails),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _showDetails
                  ? Theme.of(context).primaryColor.withOpacity(0.15)
                  : Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _showDetails
                    ? Theme.of(context).primaryColor.withOpacity(0.4)
                    : Theme.of(context).dividerColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showDetails ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: _showDetails
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  _showDetails ? 'Hide' : 'Show',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _showDetails
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'WIN':
        return Colors.green;
      case 'LOSS':
        return Colors.red;
      case 'BREAK_EVEN':
        return Colors.orange;
      case 'OPEN':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTagPill(BuildContext context, IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Theme.of(context).primaryColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  Widget _buildInfoTag(BuildContext context, IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
