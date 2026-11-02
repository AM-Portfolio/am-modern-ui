import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/ipo_navigation.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/ipo_subscription_sorting.dart';
import 'package:flutter/material.dart';

class IpoTableView extends StatelessWidget {
  const IpoTableView({
    super.key,
    required this.items,
  });

  final List<AsraxIpoSummaryDto> items;

  @override
  Widget build(BuildContext context) {
    final showSubscription = items.any(_hasSubscription);
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The IPO table shares its surface with a collapsible Market sidebar.
        // Reduce spacing before overflow on the narrow shell and use the extra
        // space when the sidebar is collapsed.
        final columnSpacing =
            (constraints.maxWidth * 0.035).clamp(28.0, 56.0).toDouble();

        final accent = ModuleColorProvider.of(context);

        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: context.borderColor),
          ),
          child: AdaptiveDataTable<AsraxIpoSummaryDto>(
            data: items,
            keepTableOnMobile: true,
            expandToAvailableWidth: true,
            columnSpacing: columnSpacing,
            resetSortOnThirdTap: true,
            rowHeight: 72,
            headerBackgroundColor:
                colors.marketCardSurface.withValues(alpha: 0.72),
            rowHoverColor: accent.withValues(alpha: 0.06),
            headerTextStyle: TextStyle(
              color: context.textSecondary,
              fontSize: AppTypeScale.sm,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
            ),
            rowTextStyle: TextStyle(
              color: context.textPrimary,
              fontSize: AppTypeScale.sm,
              fontWeight: FontWeight.w600,
            ),
            columns: [
              DataTableColumn(
                key: 'ipo',
                title: 'IPO',
                cellBuilder: (ipo) => _IpoIdentityCell(ipo: ipo),
              ),
              DataTableColumn(
                key: 'board',
                title: 'BOARD',
                cellBuilder: (ipo) => _BoardLabel(issueType: ipo.issueType),
              ),
              DataTableColumn(
                key: 'status',
                title: 'STATUS',
                cellBuilder: (ipo) => _StatusBadge(status: ipo.status),
              ),
              if (showSubscription)
                DataTableColumn(
                  key: 'subscription',
                  title: 'SUB',
                  sortable: true,
                  nullableSortValue: (ipo) =>
                      ipoSubscriptionSortValue(ipo.totalSubscription),
                  cellBuilder: (ipo) => _TableValue(
                    value: _formatSubscription(ipo.totalSubscription),
                    muted: !_hasSubscription(ipo),
                  ),
                ),
              DataTableColumn(
                key: 'price',
                title: 'PRICE BAND',
                sortable: true,
                sortValue: _priceSortValue,
                cellBuilder: (ipo) => _TableValue(value: _formatPriceBand(ipo)),
              ),
              DataTableColumn(
                key: 'size',
                title: 'ISSUE SIZE',
                sortable: true,
                sortValue: (ipo) => ipo.issueSizeCr ?? double.infinity,
                cellBuilder: (ipo) =>
                    _TableValue(value: _formatIssueSize(ipo.issueSizeCr)),
              ),
              DataTableColumn(
                key: 'open',
                title: 'BIDDING OPENS',
                sortable: true,
                sortValue: (ipo) => _dateSortValue(ipo.biddingStartDate),
                cellBuilder: (ipo) =>
                    _TableValue(value: _formatDate(ipo.biddingStartDate)),
              ),
              DataTableColumn(
                key: 'close',
                title: 'BIDDING CLOSES',
                sortable: true,
                sortValue: (ipo) => _dateSortValue(ipo.biddingEndDate),
                cellBuilder: (ipo) =>
                    _TableValue(value: _formatDate(ipo.biddingEndDate)),
              ),
            ],
            onRowTap: (ipo) => openIpoDetailsForSummary(context, ipo),
          ),
        );
      },
    );
  }
}

class _IpoIdentityCell extends StatelessWidget {
  const _IpoIdentityCell({required this.ipo});

  final AsraxIpoSummaryDto ipo;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColorProvider.of(context);
    final name = ipo.companyName?.trim().isNotEmpty == true
        ? ipo.companyName!.trim()
        : ipo.symbol?.trim().isNotEmpty == true
            ? ipo.symbol!.trim()
            : 'Unknown IPO';
    final symbol = ipo.symbol?.trim();
    final initials = _initials(name);

    return SizedBox(
      width: 230,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadii.sm + 1),
            ),
            child: Text(
              initials,
              style: TextStyle(
                color: accent,
                fontSize: AppTypeScale.sm,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: AppTypeScale.md,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (symbol != null && symbol.isNotEmpty)
                  Text(
                    symbol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: AppTypeScale.sm,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardLabel extends StatelessWidget {
  const _BoardLabel({required this.issueType});

  final String? issueType;

  @override
  Widget build(BuildContext context) {
    final isSme = (issueType ?? '').toLowerCase().contains('sme');
    return Text(
      isSme ? 'SME' : 'Mainboard',
      style: TextStyle(
        color: isSme
            ? ModuleColorProvider.of(context)
            : context.textSecondary,
        fontSize: AppTypeScale.sm,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final value = (status ?? 'unknown').trim().toUpperCase();
    final color = value == 'OPEN'
        ? context.colors.statusSuccess
        : value == 'UPCOMING'
            ? context.colors.statusWarning
            : context.colors.statusError;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: AppTypeScale.xs,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _TableValue extends StatelessWidget {
  const _TableValue({required this.value, this.muted = false});

  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        color: muted ? context.textTertiary : context.textPrimary,
        fontSize: AppTypeScale.sm,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

bool _hasSubscription(AsraxIpoSummaryDto ipo) =>
    ipo.totalSubscription?.trim().isNotEmpty == true;

double _priceSortValue(AsraxIpoSummaryDto ipo) =>
    ipo.minimumPrice ?? ipo.maximumPrice ?? double.infinity;

DateTime _dateSortValue(String? value) =>
    DateTime.tryParse(value?.trim() ?? '') ?? DateTime.utc(9999, 12, 31);

String _formatSubscription(String? value) =>
    value?.trim().isNotEmpty == true ? '${value!.trim()}x' : '—';

String _formatPriceBand(AsraxIpoSummaryDto ipo) {
  final min = ipo.minimumPrice;
  final max = ipo.maximumPrice;
  if (min == null && max == null) return '₹—';
  if (min != null && max != null && min != max) {
    return '₹${min.toStringAsFixed(0)} – ₹${max.toStringAsFixed(0)}';
  }
  return '₹${(min ?? max)!.toStringAsFixed(0)}';
}

String _formatIssueSize(double? value) => value == null
    ? '₹—'
    : '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} Cr';

String _formatDate(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return 'TBA';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}

String _initials(String value) {
  final parts = value
      .replaceAll(RegExp(r'(IPO|Limited|Ltd|\.)', caseSensitive: false), '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'IP';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(1, 2))
        .toUpperCase();
  }
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}
