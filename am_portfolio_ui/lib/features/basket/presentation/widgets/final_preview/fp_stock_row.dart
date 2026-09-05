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

  Widget _buildAvatar({double radius = 16}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _getSectorColor(sector),
      child: Text(
        symbol.isNotEmpty ? symbol[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius >= 16 ? 14 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final fmtValue =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final metaParts = <String>[
      'Wt ${weightage.toStringAsFixed(1)}%',
      if (showValue)
        value != null ? fmtValue.format(value) : '—',
      if (showValue && valueSubLabel != null) valueSubLabel!,
    ];

    Widget? pill;
    if (statusPill != null && showStatus) {
      pill = FpStatusPill(
        label: statusPill!.label,
        subLabel: statusPill!.subLabel,
        color: statusPill!.color,
        compact: true,
      );
    }

    return Container(
      color: isEven ? colors.cardSurface : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _buildAvatar(radius: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  metaParts.join(' · '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (pill != null) ...[
            const SizedBox(width: AppSpacing.sm),
            pill,
          ],
        ],
      ),
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
