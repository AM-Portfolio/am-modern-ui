import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart' as market;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import 'intelligence_glass_card.dart';
import 'portfolio_stress_catalog.dart';

export 'portfolio_stress_catalog.dart';

/// Shared Stress Test body for phone, tablet, and desktop.
class StressMobileBody extends StatelessWidget {
  const StressMobileBody({
    required this.sectorCtrl,
    required this.shockCtrl,
    required this.shockFocus,
    required this.rows,
    required this.failed,
    required this.loading,
    required this.applying,
    required this.error,
    required this.viewAllExpanded,
    required this.selectedChip,
    required this.searchHandler,
    required this.onApply,
    required this.onRetryLoad,
    required this.onToggleViewAll,
    required this.onChipSelected,
    required this.onSectorSelected,
    this.onQueryChanged,
    required this.onShockChanged,
    this.appliedRow,
    this.fillHeight = false,
    super.key,
  });

  final TextEditingController sectorCtrl;
  final TextEditingController shockCtrl;
  final FocusNode shockFocus;
  final Map<String, StressScenario> rows;
  final Set<String> failed;
  final bool loading;
  final bool applying;
  final String? error;
  final bool viewAllExpanded;
  final String selectedChip;
  final bool fillHeight;
  final Future<List<market.SecurityDocument>> Function(String query)
      searchHandler;
  final VoidCallback onApply;
  final VoidCallback onRetryLoad;
  final VoidCallback onToggleViewAll;
  final ValueChanged<String> onChipSelected;
  final ValueChanged<String> onSectorSelected;
  final ValueChanged<String>? onQueryChanged;
  final VoidCallback onShockChanged;
  /// Search/sector Apply result pinned above the catalog (not a NIFTY relabel).
  final StressViewRow? appliedRow;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= AmBreakpoints.tablet;
    final phone = width < AmBreakpoints.mobile;
    final openCatalog = fillHeight || desktop;
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final scrollPad = EdgeInsets.only(bottom: kb > 0 ? kb + 24 : 280);
    final catalog = viewAllExpanded || openCatalog
        ? kStressViewRows
        : (appliedRow != null
            ? const <StressViewRow>[]
            : kStressViewRows.take(1).toList());
    final visible = <StressViewRow>[
      if (appliedRow != null) appliedRow!,
      for (final row in catalog)
        if (appliedRow == null || row.id != appliedRow!.id) row,
    ];
    final showHeader = desktop;

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          StressScenarioRow(
            meta: visible[i],
            scenario: failed.contains(visible[i].id) ? null : rows[visible[i].id],
            failed: failed.contains(visible[i].id),
            currency: currency,
            dense: desktop,
            showImpactCaption: false,
          ),
        ],
      ],
    );
    final scroller = SingleChildScrollView(
      primary: false,
      physics: const ClampingScrollPhysics(),
      child: list,
    );

    final chrome = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SmartSearchAnchor(
          controller: sectorCtrl,
          compact: true,
          hintText: 'Search index, sector or scenario',
          accentColor: ModuleColors.portfolio,
          forceUppercase: false,
          resultBadge: null,
          overlayPlacement: phone
              ? SmartSearchOverlayPlacement.above
              : SmartSearchOverlayPlacement.below,
          overlayMaxHeight: phone ? 280 : 420,
          onSelected: onSectorSelected,
          onQueryChanged: onQueryChanged,
          searchHandler: searchHandler,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final label in [
              kStressChipNifty,
              kStressChipSensex,
              kStressChipBanking,
              kStressChipIt,
            ])
              IntelligenceModeChip(
                label: label,
                selected: selectedChip == label,
                onTap: () => onChipSelected(label),
                accentColor: ModuleColors.portfolio,
                compact: true,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _StressApplyBar(
          shockCtrl: shockCtrl,
          shockFocus: shockFocus,
          scrollPad: scrollPad,
          applying: applying,
          stackLabel: phone,
          onApply: onApply,
          onShockChanged: onShockChanged,
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          if (error == 'Could not load stress scenarios')
            IntelligenceTextLink(label: 'Retry →', onPressed: onRetryLoad),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (!openCatalog)
          InkWell(
            onTap: onToggleViewAll,
            borderRadius: AppRadii.button,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt_rounded,
                    size: 18,
                    color: ModuleColors.portfolio,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'View all',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    viewAllExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: ModuleColors.portfolio,
                  ),
                ],
              ),
            ),
          ),
        if (showHeader)
          const StressTableHeader()
        else
          const StressImpactColumnLabel(),
      ],
    );

    if (loading && rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          chrome,
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          chrome,
          Expanded(child: scroller),
        ],
      );
    }

    final maxList = viewAllExpanded && !desktop ? 240.0 : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chrome,
        if (maxList != null)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxList),
            child: scroller,
          )
        else
          list,
      ],
    );
  }
}

/// Label may stack on phones; stepper and Apply stay on one row at every width.
class _StressApplyBar extends StatelessWidget {
  const _StressApplyBar({
    required this.shockCtrl,
    required this.shockFocus,
    required this.scrollPad,
    required this.applying,
    required this.stackLabel,
    required this.onApply,
    required this.onShockChanged,
  });

  final TextEditingController shockCtrl;
  final FocusNode shockFocus;
  final EdgeInsets scrollPad;
  final bool applying;
  final bool stackLabel;
  final VoidCallback onApply;
  final VoidCallback onShockChanged;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      'Impact on market (%)',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
    final stepper = StressImpactStepper(
      controller: shockCtrl,
      focusNode: shockFocus,
      scrollPadding: scrollPad,
      onChanged: onShockChanged,
    );
    final apply = SizedBox(
      height: 40,
      child: Semantics(
        button: true,
        label: 'Apply stress scenario',
        child: FilledButton(
          onPressed: applying ? null : onApply,
          style: FilledButton.styleFrom(
            backgroundColor: ModuleColors.portfolio,
            foregroundColor: context.colors.actionPrimaryFg,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(64, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: applying
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.actionPrimaryFg,
                  ),
                )
              : const Text('Apply'),
        ),
      ),
    );
    final controls = Row(
      children: [
        Expanded(child: stepper),
        const SizedBox(width: AppSpacing.sm),
        apply,
      ],
    );
    if (stackLabel) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 8),
          controls,
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: label,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(width: 148, child: stepper),
        const SizedBox(width: AppSpacing.sm),
        apply,
      ],
    );
  }
}

class StressImpactColumnLabel extends StatelessWidget {
  const StressImpactColumnLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          'Impact on Portfolio',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class StressTableHeader extends StatelessWidget {
  const StressTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).hintColor,
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Expanded(flex: 5, child: Text('Scenario', style: style)),
          Expanded(
            flex: 2,
            child: Text(
              'Market fall (%)',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Impact on Portfolio',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class StressScenarioRow extends StatelessWidget {
  const StressScenarioRow({
    required this.meta,
    required this.scenario,
    required this.failed,
    required this.currency,
    required this.dense,
    required this.showImpactCaption,
    super.key,
  });

  final StressViewRow meta;
  final StressScenario? scenario;
  final bool failed;
  final NumberFormat currency;
  final bool dense;
  final bool showImpactCaption;

  @override
  Widget build(BuildContext context) {
    final pct = failed ? null : scenario?.pctImpact;
    final abs = failed ? null : scenario?.absImpact;
    final fall = failed ? null : scenario?.appliedShockPct;
    final negative = pct != null && pct < 0;
    final positive = pct != null && pct > 0;
    final accent = pct == null
        ? context.colors.textTertiary
        : (negative
            ? context.marketNegative
            : (positive
                ? context.marketPositive
                : context.colors.textSecondary));
    final fallText = fall == null
        ? '—'
        : '${fall >= 0 ? '+' : ''}${fall.toStringAsFixed(fall == fall.roundToDouble() ? 0 : 1)}%';
    final pctText = pct == null
        ? '—'
        : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ModuleColors.portfolio.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              stressPresetIcon(meta.id, isEvent: meta.isEvent),
              size: 16,
              color: ModuleColors.portfolio,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (meta.date != null)
                  Text(
                    meta.date!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colors.textTertiary,
                        ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              fallText,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showImpactCaption)
                  Text(
                    'Impact on Portfolio',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colors.textTertiary,
                          fontSize: 10,
                        ),
                  ),
                Text(
                  pctText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: dense ? 13 : 14,
                      ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    abs == null ? '—' : currency.format(abs),
                    maxLines: 1,
                    softWrap: false,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
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

class StressImpactStepper extends StatelessWidget {
  const StressImpactStepper({
    required this.controller,
    required this.focusNode,
    required this.scrollPadding,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final EdgeInsets scrollPadding;
  final VoidCallback onChanged;

  void _step(double delta) {
    final current = double.tryParse(controller.text.trim()) ?? 0;
    final next = current + delta;
    controller.text = next == next.roundToDouble()
        ? next.toStringAsFixed(0)
        : next.toStringAsFixed(1);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: AppRadii.button,
        border: Border.all(
          color: ModuleColors.portfolio.withValues(alpha: 0.35),
        ),
        color: context.glassOverlay(
          Theme.of(context).brightness == Brightness.dark ? 0.04 : 0.03,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
            onPressed: () => _step(-1),
            icon: Icon(Icons.remove, size: 18, color: ModuleColors.portfolio),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              scrollPadding: scrollPadding,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                suffixText: '%',
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
            onPressed: () => _step(1),
            icon: Icon(Icons.add, size: 18, color: ModuleColors.portfolio),
          ),
        ],
      ),
    );
  }
}
