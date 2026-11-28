import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/mf_scheme_view.dart';
import 'mf_fund_card.dart';
import 'mf_risk_meter.dart';

/// Dense fund explorer with client-side pagination.
/// Wide = AdaptiveDataTable page; narrow = MfFundCard list page.
class MfFundExplorerTable extends StatefulWidget {
  const MfFundExplorerTable({
    required this.funds,
    required this.period,
    required this.accent,
    required this.onRowTap,
    required this.onInvest,
    required this.onSip,
    this.pageSize = 10,
    this.pageSizeOptions = const [5, 10, 25],
    super.key,
  });

  final List<MfSchemeView> funds;
  final MfReturnPeriod period;
  final Color accent;
  final ValueChanged<MfSchemeView> onRowTap;
  final ValueChanged<MfSchemeView>? onInvest;
  final ValueChanged<MfSchemeView>? onSip;
  final int pageSize;
  final List<int> pageSizeOptions;

  @override
  State<MfFundExplorerTable> createState() => _MfFundExplorerTableState();
}

class _MfFundExplorerTableState extends State<MfFundExplorerTable> {
  late int _pageSize;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageSize = widget.pageSize;
  }

  @override
  void didUpdateWidget(covariant MfFundExplorerTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.funds.length != widget.funds.length ||
        oldWidget.period != widget.period) {
      _page = 0;
    }
    _clampPage();
  }

  void _clampPage() {
    final pages = _totalPages;
    if (_page >= pages) _page = (pages - 1).clamp(0, pages - 1);
  }

  int get _totalPages {
    if (widget.funds.isEmpty) return 1;
    return (widget.funds.length / _pageSize).ceil();
  }

  List<MfSchemeView> get _pageItems {
    if (widget.funds.isEmpty) return const [];
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.funds.length);
    if (start >= widget.funds.length) return const [];
    return widget.funds.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTable = constraints.maxWidth >= AmBreakpoints.mobile;
        final pageItems = _pageItems;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!useTable)
              Column(
                children: [
                  for (final f in pageItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: MfFundCard(
                        fund: f,
                        period: widget.period,
                        compact: true,
                        onTap: () => widget.onRowTap(f),
                        onInvest: f.digPurchaseEnabled &&
                                widget.onInvest != null
                            ? () => widget.onInvest!(f)
                            : null,
                        onSip: f.digPurchaseEnabled && widget.onSip != null
                            ? () => widget.onSip!(f)
                            : null,
                      ),
                    ),
                ],
              )
            else
              _DenseTable(
                funds: pageItems,
                period: widget.period,
                accent: widget.accent,
                onRowTap: widget.onRowTap,
                onInvest: widget.onInvest,
                onSip: widget.onSip,
              ),
            if (widget.funds.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _PaginationFooter(
                page: _page,
                pageSize: _pageSize,
                totalItems: widget.funds.length,
                totalPages: _totalPages,
                pageSizeOptions: widget.pageSizeOptions,
                accent: widget.accent,
                onPageChanged: (p) => setState(() => _page = p),
                onPageSizeChanged: (s) => setState(() {
                  _pageSize = s;
                  _page = 0;
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.pageSizeOptions,
    required this.accent,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final List<int> pageSizeOptions;
  final Color accent;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : page * pageSize + 1;
    final end = ((page + 1) * pageSize).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Text(
            '$start–$end of $totalItems',
            style: context.text.caption().copyWith(color: context.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Rows',
            style: context.text.caption().copyWith(color: context.textSecondary),
          ),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: pageSize,
              isDense: true,
              dropdownColor: context.cardColor,
              style: context.text.label().copyWith(color: context.textPrimary),
              iconEnabledColor: accent,
              items: [
                for (final s in pageSizeOptions)
                  DropdownMenuItem(value: s, child: Text('$s')),
              ],
              onChanged: (v) {
                if (v != null) onPageSizeChanged(v);
              },
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Previous',
            onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
            color: accent,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '${page + 1} / $totalPages',
            style: context.text.label().copyWith(color: context.textPrimary),
          ),
          IconButton(
            tooltip: 'Next',
            onPressed:
                page < totalPages - 1 ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
            color: accent,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _DenseTable extends StatelessWidget {
  const _DenseTable({
    required this.funds,
    required this.period,
    required this.accent,
    required this.onRowTap,
    required this.onInvest,
    required this.onSip,
  });

  final List<MfSchemeView> funds;
  final MfReturnPeriod period;
  final Color accent;
  final ValueChanged<MfSchemeView> onRowTap;
  final ValueChanged<MfSchemeView>? onInvest;
  final ValueChanged<MfSchemeView>? onSip;

  @override
  Widget build(BuildContext context) {
    final pctFmt = NumberFormat('+0.00%;-0.00%');
    final navFmt = NumberFormat('#,##0.00');
    final aumFmt =
        NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 0);

    Widget pctCell(double? v) {
      if (v == null) {
        return Text(
          '—',
          style: context.text.caption().copyWith(color: context.textSecondary),
        );
      }
      final up = v >= 0;
      return Text(
        pctFmt.format(v / 100),
        style: context.text.label().copyWith(
              fontWeight: FontWeight.w700,
              color: up ? context.marketPositive : context.marketNegative,
            ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      borderRadius: AppRadii.lg,
      child: AdaptiveDataTable<MfSchemeView>(
        data: funds,
        expandToAvailableWidth: true,
        keepTableOnMobile: true,
        rowHeight: 56,
        columnSpacing: 16,
        headerBackgroundColor: context.cardColor,
        headerTextStyle: context.text.caption().copyWith(
              color: context.textSecondary,
              fontWeight: FontWeight.w700,
            ),
        onRowTap: onRowTap,
        columns: [
          DataTableColumn<MfSchemeView>(
            key: 'fund',
            title: 'Fund / AMC',
            width: 240,
            cellBuilder: (f) => Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    f.amcLabel.isNotEmpty ? f.amcLabel[0].toUpperCase() : 'F',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        f.shortName,
                        style: context.text.label().copyWith(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        f.amcLabel.isNotEmpty ? f.amcLabel : f.isin,
                        style: context.text.caption().copyWith(
                              color: context.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DataTableColumn<MfSchemeView>(
            key: 'category',
            title: 'Category',
            sortable: true,
            sortValue: (f) => f.category,
            cellBuilder: (f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: context.borderColor),
              ),
              child: Text(
                f.category,
                style: context.text.caption().copyWith(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          DataTableColumn<MfSchemeView>(
            key: 'risk',
            title: 'Risk',
            width: 100,
            cellBuilder: (f) => SizedBox(
              width: 96,
              child: MfRiskMeter(
                riskLevel: f.riskLevel,
                height: 5,
                showLabel: true,
              ),
            ),
          ),
          DataTableColumn<MfSchemeView>(
            key: '1y',
            title: '1Y',
            numeric: true,
            sortable: true,
            nullableSortValue: (f) => f.returnFor('1Y'),
            cellBuilder: (f) => pctCell(f.returnFor('1Y')),
          ),
          DataTableColumn<MfSchemeView>(
            key: '3y',
            title: '3Y',
            numeric: true,
            sortable: true,
            nullableSortValue: (f) => f.returnFor('3Y'),
            cellBuilder: (f) => pctCell(f.returnFor('3Y')),
          ),
          DataTableColumn<MfSchemeView>(
            key: '5y',
            title: '5Y',
            numeric: true,
            sortable: true,
            nullableSortValue: (f) => f.returnFor('5Y'),
            cellBuilder: (f) => pctCell(f.returnFor('5Y')),
          ),
          DataTableColumn<MfSchemeView>(
            key: 'nav',
            title: 'NAV',
            numeric: true,
            sortable: true,
            nullableSortValue: (f) => f.nav,
            cellBuilder: (f) => Text(
              f.nav != null ? '₹${navFmt.format(f.nav)}' : '—',
              style: context.text.label().copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          DataTableColumn<MfSchemeView>(
            key: 'aum',
            title: 'AUM',
            numeric: true,
            sortable: true,
            nullableSortValue: (f) => f.displayAum,
            cellBuilder: (f) => Text(
              f.displayAum != null ? aumFmt.format(f.displayAum) : '—',
              style: context.text.caption().copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          DataTableColumn<MfSchemeView>(
            key: 'action',
            title: '',
            cellBuilder: (f) {
              if (!f.digPurchaseEnabled || onInvest == null) {
                return Text(
                  'Browse',
                  style: context.text.caption().copyWith(
                        color: context.textSecondary,
                      ),
                );
              }
              return FilledButton(
                onPressed: () => onInvest!(f),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: context.colors.actionPrimaryFg,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                ),
                child: const Text('Invest'),
              );
            },
          ),
        ],
      ),
    );
  }
}
