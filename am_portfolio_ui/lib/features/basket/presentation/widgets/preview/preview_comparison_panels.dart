import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_opportunity.dart';
import '../../shared/basket_item_status_theme.dart';
import '../../utils/basket_responsive.dart';
import '../final_preview/fp_status_pill.dart';
import 'inline_swap_panel.dart';
import 'preview_layout.dart';

/// Step-1 Preview: ETF Index vs Your Holdings with aligned rows.
class PreviewComparisonPanels extends StatefulWidget {
  final BasketOpportunity opportunity;
  final Set<String> swappingSymbols;
  final void Function(BasketItem item, Alternative selected)? onSwapSelected;
  final bool sectorialBasket;
  final String? dominantSector;
  final String? etfName;
  final List<String> etfConstituentIsins;

  const PreviewComparisonPanels({
    super.key,
    required this.opportunity,
    this.swappingSymbols = const {},
    this.onSwapSelected,
    this.sectorialBasket = false,
    this.dominantSector,
    this.etfName,
    this.etfConstituentIsins = const [],
  });

  /// ETF weight order keeps left/right rows horizontally scannable.
  static List<BasketItem> orderedItems(List<BasketItem> composition) {
    final items = List<BasketItem>.from(composition);
    items.sort((a, b) => b.etfWeight.compareTo(a.etfWeight));
    return items;
  }

  @override
  State<PreviewComparisonPanels> createState() =>
      _PreviewComparisonPanelsState();
}

class _PreviewComparisonPanelsState extends State<PreviewComparisonPanels> {
  String? _expandedMissingIsin;

  @override
  Widget build(BuildContext context) {
    final items = PreviewComparisonPanels.orderedItems(
      widget.opportunity.composition,
    );
    final sideBySide = BasketResponsive.isDesktop(context) ||
        (BasketResponsive.isTablet(context) &&
            MediaQuery.sizeOf(context).width >= 900);

    final pagePad = BasketResponsive.pagePadding(context).copyWith(top: 0);

    return sideBySide
        ? Padding(
            padding: pagePad.copyWith(
              bottom: PreviewLayout.sectionGap,
            ),
            child: _AlignedSideBySideGrid(
              items: items,
              etfIsin: widget.opportunity.etfIsin,
              swappingSymbols: widget.swappingSymbols,
              expandedMissingIsin: _expandedMissingIsin,
              onToggleMissing: _toggleMissing,
              onSwapSelected: _handleSwap,
              sectorialBasket: widget.sectorialBasket,
              dominantSector: widget.dominantSector,
              etfName: widget.etfName,
              etfConstituentIsins: widget.etfConstituentIsins,
            ),
          )
        : SingleChildScrollView(
            padding: pagePad.copyWith(
              bottom: PreviewLayout.sectionGap,
            ),
            child: _StackedPanels(
              items: items,
              etfIsin: widget.opportunity.etfIsin,
              swappingSymbols: widget.swappingSymbols,
              expandedMissingIsin: _expandedMissingIsin,
              onToggleMissing: _toggleMissing,
              onSwapSelected: _handleSwap,
              sectorialBasket: widget.sectorialBasket,
              dominantSector: widget.dominantSector,
              etfName: widget.etfName,
              etfConstituentIsins: widget.etfConstituentIsins,
            ),
          );
  }

  void _toggleMissing(BasketItem item) {
    if (item.status != ItemStatus.missing || item.alternatives.isEmpty) {
      return;
    }
    setState(() {
      final key = item.isin.isNotEmpty ? item.isin : item.stockSymbol;
      _expandedMissingIsin = _expandedMissingIsin == key ? null : key;
    });
  }

  void _handleSwap(BasketItem item, Alternative alt) {
    setState(() => _expandedMissingIsin = null);
    widget.onSwapSelected?.call(item, alt);
  }
}

class _AlignedSideBySideGrid extends StatefulWidget {
  final List<BasketItem> items;
  final String etfIsin;
  final Set<String> swappingSymbols;
  final String? expandedMissingIsin;
  final void Function(BasketItem item) onToggleMissing;
  final void Function(BasketItem item, Alternative alt) onSwapSelected;
  final bool sectorialBasket;
  final String? dominantSector;
  final String? etfName;
  final List<String> etfConstituentIsins;

  const _AlignedSideBySideGrid({
    required this.items,
    required this.etfIsin,
    required this.swappingSymbols,
    required this.expandedMissingIsin,
    required this.onToggleMissing,
    required this.onSwapSelected,
    required this.sectorialBasket,
    this.dominantSector,
    this.etfName,
    this.etfConstituentIsins = const [],
  });

  @override
  State<_AlignedSideBySideGrid> createState() => _AlignedSideBySideGridState();
}

class _AlignedSideBySideGridState extends State<_AlignedSideBySideGrid> {
  late final ScrollController _leftScroll;
  late final ScrollController _rightScroll;
  bool _syncingScroll = false;

  @override
  void initState() {
    super.initState();
    _leftScroll = ScrollController()..addListener(_syncFromLeft);
    _rightScroll = ScrollController()..addListener(_syncFromRight);
  }

  @override
  void dispose() {
    _leftScroll.removeListener(_syncFromLeft);
    _rightScroll.removeListener(_syncFromRight);
    _leftScroll.dispose();
    _rightScroll.dispose();
    super.dispose();
  }

  void _syncFromLeft() {
    if (_syncingScroll || !_rightScroll.hasClients) return;
    _syncingScroll = true;
    if (_leftScroll.offset != _rightScroll.offset) {
      _rightScroll.jumpTo(_leftScroll.offset);
    }
    _syncingScroll = false;
  }

  void _syncFromRight() {
    if (_syncingScroll || !_leftScroll.hasClients) return;
    _syncingScroll = true;
    if (_rightScroll.offset != _leftScroll.offset) {
      _leftScroll.jumpTo(_rightScroll.offset);
    }
    _syncingScroll = false;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _PreviewTableCard(
            header: _PanelHeader(
              icon: Icons.pie_chart_outline,
              iconColor: context.colors.actionPrimaryBg,
              title: 'ETF Index',
              subtitle: '${widget.etfIsin} · Target allocation',
            ),
            columnHeader: const _IndexColumnHeader(),
            footer: _IndexFooter(),
            body: ListView.builder(
              controller: _leftScroll,
              padding: EdgeInsets.zero,
              itemCount: widget.items.length,
              itemBuilder: (context, index) => _IndexDataRow(
                item: widget.items[index],
                striped: index.isEven,
              ),
            ),
          ),
        ),
        const SizedBox(width: PreviewLayout.sectionGap),
        Expanded(
          child: _PreviewTableCard(
            header: _PanelHeader(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: context.statusSuccess,
              title: 'Your Holdings',
              subtitle: 'Current portfolio exposure',
            ),
            columnHeader: const _HoldingsColumnHeader(),
            footer: const SizedBox(height: PreviewLayout.cardPadding),
            body: ListView.builder(
              controller: _rightScroll,
              padding: EdgeInsets.zero,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final key = item.isin.isNotEmpty ? item.isin : item.stockSymbol;
                final expanded = widget.expandedMissingIsin == key;
                final canSwap =
                    item.status == ItemStatus.missing &&
                        item.alternatives.isNotEmpty;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HoldingsDataRow(
                      item: item,
                      striped: index.isEven,
                      swapping: widget.swappingSymbols.contains(item.stockSymbol),
                      onTap: canSwap ? () => widget.onToggleMissing(item) : null,
                    ),
                    if (expanded && canSwap)
                      InlineSwapPanel(
                        alternatives: item.alternatives,
                        sectorialBasket: widget.sectorialBasket,
                        dominantSector: widget.dominantSector,
                        etfName: widget.etfName,
                        etfConstituentIsins: widget.etfConstituentIsins,
                        missingSector: item.sector,
                        onSwapSelected: (alt) => widget.onSwapSelected(item, alt),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StackedPanels extends StatelessWidget {
  final List<BasketItem> items;
  final String etfIsin;
  final Set<String> swappingSymbols;
  final String? expandedMissingIsin;
  final void Function(BasketItem item) onToggleMissing;
  final void Function(BasketItem item, Alternative alt) onSwapSelected;
  final bool sectorialBasket;
  final String? dominantSector;
  final String? etfName;
  final List<String> etfConstituentIsins;

  const _StackedPanels({
    required this.items,
    required this.etfIsin,
    required this.swappingSymbols,
    required this.expandedMissingIsin,
    required this.onToggleMissing,
    required this.onSwapSelected,
    required this.sectorialBasket,
    this.dominantSector,
    this.etfName,
    this.etfConstituentIsins = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreviewTableCard(
          header: _PanelHeader(
            icon: Icons.pie_chart_outline,
            iconColor: context.colors.actionPrimaryBg,
            title: 'ETF Index',
            subtitle: '$etfIsin · Target allocation',
          ),
          columnHeader: const _IndexColumnHeader(),
          footer: _IndexFooter(),
          shrinkWrap: true,
          body: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _IndexDataRow(item: items[i], striped: i.isEven),
            ],
          ),
        ),
        const SizedBox(height: PreviewLayout.sectionGap),
        _PreviewTableCard(
          header: _PanelHeader(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: context.statusSuccess,
            title: 'Your Holdings',
            subtitle: 'Current portfolio exposure',
          ),
          columnHeader: const _HoldingsColumnHeader(),
          shrinkWrap: true,
          body: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _HoldingsDataRow(
                  item: items[i],
                  striped: i.isEven,
                  swapping: swappingSymbols.contains(items[i].stockSymbol),
                  onTap: items[i].status == ItemStatus.missing &&
                          items[i].alternatives.isNotEmpty
                      ? () => onToggleMissing(items[i])
                      : null,
                ),
                if (expandedMissingIsin ==
                        (items[i].isin.isNotEmpty
                            ? items[i].isin
                            : items[i].stockSymbol) &&
                    items[i].status == ItemStatus.missing &&
                    items[i].alternatives.isNotEmpty)
                  InlineSwapPanel(
                    alternatives: items[i].alternatives,
                    sectorialBasket: sectorialBasket,
                    dominantSector: dominantSector,
                    etfName: etfName,
                    etfConstituentIsins: etfConstituentIsins,
                    missingSector: items[i].sector,
                    onSwapSelected: (alt) => onSwapSelected(items[i], alt),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewTableCard extends StatelessWidget {
  final Widget header;
  final Widget columnHeader;
  final Widget body;
  final Widget? footer;
  final bool shrinkWrap;

  const _PreviewTableCard({
    required this.header,
    required this.columnHeader,
    required this.body,
    this.footer,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          columnHeader,
          Divider(color: context.colors.border, height: 1),
          if (shrinkWrap)
            body
          else
            Expanded(child: body),
          if (footer != null) ...[
            Divider(color: context.colors.border, height: 1),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _PanelHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PreviewLayout.cardPadding,
        PreviewLayout.cardPadding,
        PreviewLayout.cardPadding,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.colors.textSecondary,
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

class _IndexColumnHeader extends StatelessWidget {
  const _IndexColumnHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PreviewLayout.cardPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(flex: 58, child: Text('Stock', style: style)),
          Expanded(
            flex: 42,
            child: Text('Weight', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _HoldingsColumnHeader extends StatelessWidget {
  const _HoldingsColumnHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PreviewLayout.cardPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(flex: 25, child: Text('Units', style: style)),
          Expanded(flex: 45, child: Text('Value', style: style)),
          Expanded(
            flex: 30,
            child: Text('Status', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _IndexDataRow extends StatelessWidget {
  final BasketItem item;
  final bool striped;

  const _IndexDataRow({required this.item, required this.striped});

  @override
  Widget build(BuildContext context) {
    final w = item.etfWeight.clamp(0.0, 100.0);
    return Container(
      height: PreviewLayout.dataRowHeight,
      color: striped
          ? context.colors.cardSurface.withValues(alpha: 0.35)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: PreviewLayout.cardPadding,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 58,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.stockSymbol,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 42,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${w.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: LinearProgressIndicator(
                    value: (w / 100.0).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor:
                        context.colors.border.withValues(alpha: 0.4),
                    color: context.colors.actionPrimaryBg,
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

class _IndexFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PreviewLayout.cardPadding,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            '100.0%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _HoldingsDataRow extends StatelessWidget {
  final BasketItem item;
  final bool striped;
  final bool swapping;
  final VoidCallback? onTap;

  const _HoldingsDataRow({
    required this.item,
    required this.striped,
    this.swapping = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final priceFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final isMissing = item.status == ItemStatus.missing;
    final qty = isMissing ? null : item.heldQuantity;
    final avg = item.heldAveragePrice;
    final price = item.lastPrice;
    final value =
        (qty != null && price != null && qty > 0) ? qty * price : null;
    final themeLabel = BasketItemStatusTheme.labelFor(item.status);
    final themeColor = BasketItemStatusTheme.colorFor(context, item.status);

    return Material(
      color: striped
          ? context.colors.cardSurface.withValues(alpha: 0.35)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: PreviewLayout.dataRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PreviewLayout.cardPadding,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 25,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMissing ? '0' : (qty?.toStringAsFixed(0) ?? '—'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (avg != null && !isMissing)
                        Text(
                          'avg ${priceFmt.format(avg)}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: context.colors.textTertiary,
                                fontSize: 11,
                              ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 45,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMissing
                              ? '₹0'
                              : (value != null ? fmt.format(value) : '—'),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                        ),
                        if (price != null && !isMissing)
                          Text(
                            '@ ${priceFmt.format(price)}',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: context.colors.textTertiary,
                                      fontSize: 11,
                                    ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 30,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: swapping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : FpStatusPill(label: themeLabel, color: themeColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
