import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_opportunity.dart';
import '../../utils/basket_responsive.dart';
import 'inline_swap_panel.dart';
import 'preview_table_layout.dart';

class PreviewStockRow extends StatefulWidget {
  final BasketItem item;
  final bool isSwapping;
  final void Function(BasketItem item, Alternative selected)? onSwapSelected;
  final bool sectorialBasket;
  final String? dominantSector;
  final String? etfName;
  final List<String> etfConstituentIsins;

  const PreviewStockRow({
    super.key,
    required this.item,
    this.isSwapping = false,
    this.onSwapSelected,
    this.sectorialBasket = false,
    this.dominantSector,
    this.etfName,
    this.etfConstituentIsins = const [],
  });

  @override
  State<PreviewStockRow> createState() => _PreviewStockRowState();
}

class _PreviewStockRowState extends State<PreviewStockRow> {
  bool _isExpanded = false;

  bool get _isMissingWithAlternatives =>
      widget.item.status == ItemStatus.missing &&
      widget.item.alternatives.isNotEmpty;

  bool get _canExpand => _isMissingWithAlternatives;

  void _toggleExpand() {
    if (!_canExpand) return;
    setState(() => _isExpanded = !_isExpanded);
  }

  double _portfolioUnits(BasketItem item) {
    switch (item.status) {
      case ItemStatus.held:
      case ItemStatus.substitute:
        return item.heldQuantity ?? 0.0;
      case ItemStatus.missing:
        return item.buyQuantity ?? 0.0;
      case ItemStatus.excluded:
        return 0.0;
    }
  }

  double _portfolioValue(BasketItem item, double units) {
    final price = item.lastPrice ?? 0.0;
    if (units <= 0 || price <= 0) return 0.0;
    return price * units;
  }

  Color _statusColor(BuildContext context) {
    switch (widget.item.status) {
      case ItemStatus.held:
        return context.statusSuccess;
      case ItemStatus.substitute:
        return context.colors.actionPrimaryBg;
      case ItemStatus.missing:
        return context.statusError;
      case ItemStatus.excluded:
        return context.colors.textTertiary;
    }
  }

  String _statusLabel() {
    switch (widget.item.status) {
      case ItemStatus.held:
        return 'Held';
      case ItemStatus.substitute:
        return 'Substituted';
      case ItemStatus.missing:
        return 'Missing';
      case ItemStatus.excluded:
        return 'Excluded';
    }
  }

  Color _avatarColor(String sector) {
    return AppColors.getMultiColor(sector.hashCode.abs());
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);
    final units = _portfolioUnits(widget.item);
    final value = _portfolioValue(widget.item, units);
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final hasPortfolioData = units > 0 && (widget.item.lastPrice ?? 0) > 0;
    final showDash = !hasPortfolioData && widget.item.status == ItemStatus.missing;
    final compact = BasketResponsive.useCompactPreview(context);

    return Stack(
      children: [
        Column(
          children: [
            Material(
              color: context.colors.surface,
              child: InkWell(
                onTap: _canExpand ? _toggleExpand : null,
                hoverColor: _canExpand
                    ? context.colors.actionPrimaryBg.withValues(alpha: 0.04)
                    : null,
                child: compact
                    ? _buildCompactCard(
                        context,
                        statusColor,
                        units,
                        value,
                        formatter,
                        showDash,
                      )
                    : DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: context.colors.border.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  child: PreviewTableLayout.row(
                    context: context,
                    etfName: _buildEtfNameCell(context),
                    etfWeight: _buildAllocCell(context),
                    units: _buildUnitsCell(context, units, showDash, formatter),
                    value: _buildValueCell(context, value, showDash, formatter),
                    status: _buildStatusCell(context, statusColor),
                  ),
                ),
              ),
            ),
            if (_isExpanded && _isMissingWithAlternatives)
              InlineSwapPanel(
                alternatives: widget.item.alternatives,
                sectorialBasket: widget.sectorialBasket,
                dominantSector: widget.dominantSector,
                etfName: widget.etfName,
                etfConstituentIsins: widget.etfConstituentIsins,
                missingSector: widget.item.sector,
                onSwapSelected: (selectedAlt) {
                  setState(() => _isExpanded = false);
                  widget.onSwapSelected?.call(widget.item, selectedAlt);
                },
              ),
          ],
        ),
        if (widget.isSwapping)
          Positioned.fill(
            child: Container(
              color: context.colors.scaffoldBackground.withValues(alpha: 0.75),
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

  Widget _buildCompactCard(
    BuildContext context,
    Color statusColor,
    double units,
    double value,
    NumberFormat formatter,
    bool showDash,
  ) {
    final item = widget.item;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildEtfNameCell(context)),
              _StatusChip(label: _statusLabel(), color: statusColor),
              if (_canExpand)
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: context.colors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _compactMetric(
                  context,
                  label: 'ETF Weight',
                  value: '${item.etfWeight.toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _compactMetric(
                  context,
                  label: 'Units',
                  value: showDash ? '—' : units.toStringAsFixed(0),
                ),
              ),
              Expanded(
                child: _compactMetric(
                  context,
                  label: 'Value',
                  value: showDash ? '—' : formatter.format(value),
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (_canExpand) ...[
            const SizedBox(height: 4),
            Text(
              'Tap to pick a substitute',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.actionPrimaryBg,
                    fontSize: 10,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _compactMetric(
    BuildContext context, {
    required String label,
    required String value,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colors.textTertiary,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }

  Widget _buildStatusCell(BuildContext context, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusChip(label: _statusLabel(), color: statusColor),
        if (_canExpand) ...[
          const SizedBox(width: 4),
          Icon(
            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: context.colors.textSecondary,
          ),
        ],
      ],
    );
  }

  Widget _buildEtfNameCell(BuildContext context) {
    final item = widget.item;
    final avatarLetter = item.stockSymbol.isNotEmpty
        ? item.stockSymbol[0].toUpperCase()
        : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: _avatarColor(item.sector).withValues(alpha: 0.18),
          child: Text(
            avatarLetter,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _avatarColor(item.sector),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: item.status == ItemStatus.substitute &&
                  item.userHoldingSymbol != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.stockSymbol,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: context.colors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.userHoldingSymbol!,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: context.statusSuccess,
                                      fontWeight: FontWeight.w600,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Text(
                  item.stockSymbol,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }

  Widget _buildAllocCell(BuildContext context) {
    return Text(
      '${widget.item.etfWeight.toStringAsFixed(1)}%',
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
    );
  }

  Widget _buildUnitsCell(
    BuildContext context,
    double units,
    bool showDash,
    NumberFormat formatter,
  ) {
    final hasHeld = widget.item.status == ItemStatus.held ||
        widget.item.status == ItemStatus.substitute;
    final avgPrice = widget.item.heldAveragePrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          showDash ? '—' : units.toStringAsFixed(0),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: showDash
                    ? context.colors.textTertiary
                    : context.colors.textPrimary,
              ),
        ),
        if (hasHeld && avgPrice != null && avgPrice > 0) ...[
          const SizedBox(height: 2),
          Text(
            'avg ${formatter.format(avgPrice)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textTertiary,
                  fontSize: 10,
                ),
          ),
        ] else if (_canExpand) ...[
          const SizedBox(height: 2),
          Text(
            'tap to swap',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.actionPrimaryBg,
                  fontSize: 10,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildValueCell(
    BuildContext context,
    double value,
    bool showDash,
    NumberFormat formatter,
  ) {
    final hasHeld = widget.item.status == ItemStatus.held ||
        widget.item.status == ItemStatus.substitute;
    final lastPrice = widget.item.lastPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          showDash ? '—' : formatter.format(value),
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: showDash
                    ? context.colors.textTertiary
                    : context.colors.textPrimary,
              ),
        ),
        if (hasHeld && lastPrice != null && lastPrice > 0) ...[
          const SizedBox(height: 2),
          Text(
            '@ ${formatter.format(lastPrice)}',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textTertiary,
                  fontSize: 10,
                ),
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}
