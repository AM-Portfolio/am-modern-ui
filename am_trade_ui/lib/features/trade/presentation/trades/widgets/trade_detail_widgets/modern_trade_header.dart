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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
          ],
        ),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 18, color: Theme.of(context).colorScheme.onSurface),
                          const SizedBox(width: 6),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: const Duration(milliseconds: 300)).scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(width: 20),

                // Main Trade Info Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [statusColor.withOpacity(0.08), statusColor.withOpacity(0.02)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
                    ),
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
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor, // Highlight color
                                    letterSpacing: 0.5,
                                    decoration: TextDecoration.underline,
                                    decorationStyle: TextDecorationStyle.dashed,
                                  ),
                                ),
                              ),
                            ) : 
                            Text(
                              widget.trade.displaySymbol,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Status Badge with Pulse Animation
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                                      )
                                      .animate(onPlay: (controller) => controller.repeat())
                                      .scale(
                                        begin: const Offset(1.0, 1.0),
                                        end: const Offset(1.3, 1.3),
                                        duration: const Duration(milliseconds: 1500),
                                      )
                                      .fadeOut(
                                        duration: const Duration(milliseconds: 750),
                                        delay: const Duration(milliseconds: 750),
                                      ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.trade.displayStatus.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                      letterSpacing: 1.0,
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
                          widget.trade.displayCompanyName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        // Market Information & Sector & Industry Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Position Type Badge
                            if (widget.trade.tradePositionType != null && widget.trade.tradePositionType!.isNotEmpty)
                              _buildInfoTag(
                                context,
                                Icons.trending_up_rounded,
                                widget.trade.tradePositionType!,
                                widget.trade.tradePositionType == 'LONG' ? Colors.green : Colors.red,
                              ),
                            // Sector Tag
                            if (widget.trade.sector != null && widget.trade.sector!.isNotEmpty)
                              _buildTagPill(context, Icons.business_rounded, widget.trade.sector!),
                            // Industry/Series Tag
                            if (widget.trade.industry != null && widget.trade.industry!.isNotEmpty)
                              _buildTagPill(context, Icons.category_rounded, widget.trade.industry!),
                            // Exchange Tag
                            if (widget.trade.exchange != null && widget.trade.exchange!.isNotEmpty)
                              _buildTagPill(context, Icons.location_city_rounded, widget.trade.exchange!),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Entry Date
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.trade.entryTimestamp != null
                                    ? 'Entered: ${_formatDate(widget.trade.entryTimestamp!)}'
                                    : 'Entry date unavailable',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideX(begin: -0.2),
                ),
                const SizedBox(width: 20),

                // P&L Showcase Card with Shine Effect
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isProfit
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : [Colors.red.shade400, Colors.red.shade600],
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
                              color: Colors.white.withOpacity(0.95),
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
                ).animate().fadeIn(duration: const Duration(milliseconds: 500)).scale(begin: const Offset(0.9, 0.9)),
              ],
            ),

            const SizedBox(height: 16),

            // Bottom Row: Filter and Details Toggle
            Row(
              children: [
                // Filter by Symbol
                Expanded(
                  child: SizedBox(
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
                  ),
                ),
                const SizedBox(width: 16),

                // Details Toggle Button
                Material(
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
                ),
              ],
            ),
          ],
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
