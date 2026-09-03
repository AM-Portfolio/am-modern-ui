import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../utils/basket_responsive.dart';
import 'fp_status_pill.dart';

class FpStockRow extends StatelessWidget {
  final String symbol;
  final String? sector;
  final double weightage;
  final double? value;
  final String? valueSubLabel;
  final FpStatusPill? statusPill;
  final bool showValue;
  final bool showStatus;
  final bool isEven;

  const FpStockRow({
    super.key,
    required this.symbol,
    required this.sector,
    required this.weightage,
    this.value,
    this.valueSubLabel,
    this.statusPill,
    this.showValue = true,
    this.showStatus = true,
    this.isEven = false,
  });

  Color _getSectorColor(String? sector) {
    if (sector == null || sector.isEmpty) return Colors.blueGrey;
    final hash = sector.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromARGB(255, 100 + (r % 100), 100 + (g % 100), 100 + (b % 100));
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: _getSectorColor(sector),
      child: Text(
        symbol.isNotEmpty ? symbol[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    final theme = Theme.of(context);
    final fmtValue = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      color: isEven ? context.colors.cardSurface : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  symbol,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (statusPill != null && showStatus) statusPill!,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _compactMetric(
                  context,
                  label: 'Weight',
                  value: '${weightage.toStringAsFixed(1)}%',
                ),
              ),
              if (showValue)
                Expanded(
                  child: _compactMetric(
                    context,
                    label: 'Allocation',
                    value: value != null ? fmtValue.format(value) : '—',
                    sub: valueSubLabel,
                    alignEnd: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactMetric(
    BuildContext context, {
    required String label,
    required String value,
    String? sub,
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
              ),
        ),
        if (sub != null)
          Text(
            sub,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: sub == 'Covered'
                      ? context.statusSuccess
                      : context.colors.textSecondary,
                  fontSize: 10,
                ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (BasketResponsive.useCompactPreview(context)) {
      return _buildCompactCard(context);
    }

    final theme = Theme.of(context);
    final fmtValue = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    const minTableWidth = 520.0;

    final row = Container(
      color: isEven ? context.colors.cardSurface : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: (showValue && showStatus) ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: (showValue && showStatus) ? 3 : 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAvatar(),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    symbol,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: (showValue && showStatus) ? 2 : 0,
            child: Text(
              '${weightage.toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
              textAlign: (showValue && showStatus) ? TextAlign.left : TextAlign.right,
            ),
          ),
          if (showValue)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value != null ? fmtValue.format(value) : '—',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  if (valueSubLabel != null)
                    Text(
                      valueSubLabel!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: valueSubLabel == 'Covered'
                            ? context.statusSuccess
                            : context.colors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          if (showStatus)
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: statusPill ?? const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );

    if (BasketResponsive.useScrollablePreviewTable(context) && showValue && showStatus) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: minTableWidth),
          child: row,
        ),
      );
    }

    return row;
  }
}
