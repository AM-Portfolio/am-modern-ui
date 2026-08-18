import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../domain/models/basket_opportunity.dart';
import '../../../domain/models/basket_enums.dart';
import 'inline_swap_panel.dart';

class PreviewStockRow extends StatefulWidget {
  final BasketItem item;
  final ValueChanged<String>? onSwapSelected;

  const PreviewStockRow({
    super.key,
    required this.item,
    this.onSwapSelected,
  });

  @override
  State<PreviewStockRow> createState() => _PreviewStockRowState();
}

class _PreviewStockRowState extends State<PreviewStockRow> {
  bool _isExpanded = false;

  void _toggleExpand() {
    if (widget.item.status == ItemStatus.held) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Color _getStatusColor(BuildContext context) {
    switch (widget.item.status) {
      case ItemStatus.held:
        return context.statusSuccess;
      case ItemStatus.substitute:
        return context.statusWarning;
      case ItemStatus.missing:
        return context.statusError;
    }
  }

  String _getStatusText() {
    switch (widget.item.status) {
      case ItemStatus.held:
        return 'HELD';
      case ItemStatus.substitute:
        return 'SUBSTITUTE';
      case ItemStatus.missing:
        return 'MISSING';
    }
  }

  Widget _buildDeltaColumn(BuildContext context) {
    final double delta = widget.item.userWeight - widget.item.etfWeight;
    final bool isZero = delta.abs() < 0.1;
    final bool isNegative = delta < -0.1;
    
    final Color color = isZero
        ? context.colors.textTertiary
        : isNegative
            ? context.statusError
            : context.statusSuccess;

    final String sign = delta > 0 ? '+' : '';

    return Text(
      isZero ? '0.0%' : '$sign${delta.toStringAsFixed(1)}%',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);
    final canExpand = widget.item.status != ItemStatus.held;

    return Column(
      children: [
        InkWell(
          onTap: canExpand ? _toggleExpand : null,
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
                // Symbol Column
                Expanded(
                  flex: 3,
                  child: Text(
                    widget.item.stockSymbol,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                
                // ETF Target
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.item.etfWeight.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'ETF Target',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.colors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
                
                // User Holding
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.item.userWeight.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Your Holding',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.colors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
                
                // Delta Column
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildDeltaColumn(context),
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
                          horizontal: AppSpacing.xs,
                          vertical: 2,
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
                      if (canExpand) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: context.colors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded && widget.item.alternatives != null)
          InlineSwapPanel(
            alternatives: widget.item.alternatives!,
            onSwapSelected: (symbol) {
              _toggleExpand();
              if (widget.onSwapSelected != null) {
                widget.onSwapSelected!(symbol);
              }
            },
          ),
      ],
    );
  }
}
