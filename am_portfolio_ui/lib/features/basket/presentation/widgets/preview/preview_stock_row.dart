import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_opportunity.dart';
import '../../../domain/models/basket_enums.dart';
import 'inline_swap_panel.dart';

class PreviewStockRow extends StatefulWidget {
  final BasketItem item;
  final bool isSwapping;
  final void Function(BasketItem item, Alternative selected)? onSwapSelected;

  const PreviewStockRow({
    super.key,
    required this.item,
    this.isSwapping = false,
    this.onSwapSelected,
  });

  @override
  State<PreviewStockRow> createState() => _PreviewStockRowState();
}

class _PreviewStockRowState extends State<PreviewStockRow> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Color _getStatusColor(BuildContext context) {
    switch (widget.item.status) {
      case ItemStatus.held:
        return context.statusSuccess;
      case ItemStatus.substitute:
        return Theme.of(context).primaryColor;
      case ItemStatus.missing:
        return context.statusError;
    }
  }

  String _getStatusText() {
    switch (widget.item.status) {
      case ItemStatus.held:
        return 'HELD';
      case ItemStatus.substitute:
        return 'SUBSTITUTED';
      case ItemStatus.missing:
        return 'MISSING';
    }
  }

  Color _getSectorColor(String sector) {
    final int hash = sector.hashCode;
    final List<Color> palette = [
      Colors.blueAccent,
      Colors.indigo,
      Colors.deepPurple,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.deepOrange,
    ];
    return palette[hash.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);
    final double units = (widget.item.status == ItemStatus.held)
        ? (widget.item.heldQuantity ?? 0.0)
        : widget.item.buyQuantity;
    final double value = (widget.item.lastPrice ?? 0.0) * units;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Stack(
      children: [
        Column(
          children: [
            InkWell(
              onTap: _toggleExpand,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: context.colors.border,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Drag handle
                    Icon(Icons.drag_indicator, size: 16, color: context.colors.textTertiary),
                    const SizedBox(width: AppSpacing.sm),
                    
                    // Avatar & Full Name (using stockSymbol)
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: _getSectorColor(widget.item.sector),
                            child: Text(
                              widget.item.stockSymbol.isNotEmpty ? widget.item.stockSymbol[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: widget.item.status == ItemStatus.substitute && widget.item.userHoldingSymbol != null
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.item.stockSymbol,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Colors.grey,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Icon(Icons.sync_alt, size: 14, color: context.colors.statusSuccess),
                                      const SizedBox(width: AppSpacing.xs),
                                      Flexible(
                                        child: Text(
                                          widget.item.userHoldingSymbol!,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: context.colors.statusSuccess,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    widget.item.stockSymbol,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Symbol
                    Expanded(
                      flex: 2,
                      child: Text(
                        widget.item.stockSymbol,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                      ),
                    ),
                    
                    // Allocation %
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${widget.item.etfWeight.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    
                    // Units
                    Expanded(
                      flex: 2,
                      child: Text(
                        units.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    
                    // Current Value
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatter.format(value),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    
                    // Status Pill & Chevron
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                            color: context.colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              if (widget.item.status == ItemStatus.held || widget.item.status == ItemStatus.substitute)
                // Show holding details for held and substituted items
                Container(
                  color: context.colors.cardSurface,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      _buildHoldingStat(context, 'Avg. Price', formatter.format(widget.item.heldAveragePrice ?? 0)),
                      const SizedBox(width: AppSpacing.xl),
                      _buildHoldingStat(context, 'Current Price', formatter.format(widget.item.lastPrice ?? 0)),
                      const SizedBox(width: AppSpacing.xl),
                      _buildHoldingStat(context, 'Total Value', formatter.format(value)),
                    ],
                  ),
                )
              else if (widget.item.status == ItemStatus.missing && widget.item.alternatives != null)
                // Show swap panel for missing
                InlineSwapPanel(
                  alternatives: widget.item.alternatives!,
                  onSwapSelected: (selectedAlt) {
                    _toggleExpand();
                    if (widget.onSwapSelected != null) {
                      widget.onSwapSelected!(widget.item, selectedAlt);
                    }
                  },
                ),
          ],
        ),
        if (widget.isSwapping)
          Positioned.fill(
            child: Container(
              color: context.colors.scaffoldBackground.withValues(alpha: 0.7),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHoldingStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colors.textSecondary,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
