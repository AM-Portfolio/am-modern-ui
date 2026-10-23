import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart' as market;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import 'intelligence_glass_card.dart';

IconData stressPresetIcon(String presetId) {
  if (presetId.startsWith('NIFTY')) return Icons.trending_down_rounded;
  if (presetId.startsWith('BANKING')) return Icons.account_balance_rounded;
  if (presetId.startsWith('IT')) return Icons.laptop_mac_rounded;
  if (presetId.startsWith('CRASH')) return Icons.thunderstorm_rounded;
  if (presetId.startsWith('CUSTOM')) return Icons.tune_rounded;
  return Icons.bolt_rounded;
}

/// Mobile-only Stress Test body (width &lt; 600).
class StressMobileBody extends StatelessWidget {
  const StressMobileBody({
    required this.sectorCtrl,
    required this.shockCtrl,
    required this.shockFocus,
    required this.rows,
    required this.failed,
    required this.customRow,
    required this.customFailed,
    required this.customLabel,
    required this.loading,
    required this.customLoading,
    required this.error,
    required this.viewAllExpanded,
    required this.scenarioFilter,
    required this.presets,
    required this.searchHandler,
    required this.onApply,
    required this.onRetryLoad,
    required this.onToggleViewAll,
    required this.onSectorSelected,
    required this.onShockChanged,
    super.key,
  });

  final TextEditingController sectorCtrl;
  final TextEditingController shockCtrl;
  final FocusNode shockFocus;
  final Map<String, StressScenario> rows;
  final Set<String> failed;
  final StressScenario? customRow;
  final bool customFailed;
  final String customLabel;
  final bool loading;
  final bool customLoading;
  final String? error;
  final bool viewAllExpanded;
  final String scenarioFilter;
  final Map<String, String> presets;
  final Future<List<market.SecurityDocument>> Function(String query)
      searchHandler;
  final VoidCallback onApply;
  final VoidCallback onRetryLoad;
  final VoidCallback onToggleViewAll;
  final ValueChanged<String> onSectorSelected;
  final VoidCallback onShockChanged;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final scrollPad = EdgeInsets.only(bottom: kb > 0 ? kb + 24 : 280);

    final showCustom = customRow != null || customFailed;
    final primaryId = showCustom ? 'CUSTOM' : 'NIFTY_DOWN_10';
    final primaryLabel = showCustom
        ? customLabel
        : (presets['NIFTY_DOWN_10'] ?? 'NIFTY −10%');
    final primaryScenario = showCustom
        ? (customFailed ? null : customRow)
        : (failed.contains('NIFTY_DOWN_10') ? null : rows['NIFTY_DOWN_10']);
    final primaryFailed =
        showCustom ? customFailed : failed.contains('NIFTY_DOWN_10');

    final filter = scenarioFilter.toLowerCase();
    final otherPresets = presets.entries.where((e) {
      if (e.key == primaryId) return false;
      if (filter.isEmpty) return true;
      return e.value.toLowerCase().contains(filter) ||
          e.key.toLowerCase().contains(filter);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SmartSearchAnchor(
          controller: sectorCtrl,
          compact: true,
          hintText: 'Index / sector',
          accentColor: ModuleColors.portfolio,
          forceUppercase: false,
          resultBadge: null,
          overlayPlacement: SmartSearchOverlayPlacement.above,
          onSelected: onSectorSelected,
          searchHandler: searchHandler,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Impact (%)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StressImpactStepper(
                controller: shockCtrl,
                focusNode: shockFocus,
                scrollPadding: scrollPad,
                onChanged: onShockChanged,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: Semantics(
                button: true,
                label: 'Apply stress scenario',
                child: FilledButton(
                  onPressed: customLoading ? null : onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: ModuleColors.portfolio,
                    foregroundColor: context.colors.actionPrimaryFg,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(64, 40),
                  ),
                  child: customLoading
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
            ),
          ],
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
        const SizedBox(height: 10),
        if (loading && rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else ...[
          StressMobileResultCard(
            presetId: primaryId,
            label: primaryLabel,
            scenario: primaryScenario,
            failed: primaryFailed,
            currency: currency,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onToggleViewAll,
            borderRadius: AppRadii.button,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                      'View all scenarios',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    viewAllExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.chevron_right_rounded,
                    color: ModuleColors.portfolio,
                  ),
                ],
              ),
            ),
          ),
          if (viewAllExpanded)
            SizedBox(
              height: 200,
              child: ListView.separated(
                primary: false,
                physics: const ClampingScrollPhysics(),
                itemCount: otherPresets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final e = otherPresets[i];
                  return StressMobileResultCard(
                    presetId: e.key,
                    label: e.value,
                    scenario: failed.contains(e.key) ? null : rows[e.key],
                    failed: failed.contains(e.key),
                    currency: currency,
                    compact: true,
                  );
                },
              ),
            ),
        ],
      ],
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

class StressMobileResultCard extends StatelessWidget {
  const StressMobileResultCard({
    required this.presetId,
    required this.label,
    required this.scenario,
    required this.failed,
    required this.currency,
    this.compact = false,
    super.key,
  });

  final String presetId;
  final String label;
  final StressScenario? scenario;
  final bool failed;
  final NumberFormat currency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pct = failed ? null : scenario?.pctImpact;
    final abs = failed ? null : scenario?.absImpact;
    final negative = pct != null && pct < 0;
    final positive = pct != null && pct > 0;
    final accent = pct == null
        ? context.colors.textTertiary
        : (negative
            ? context.marketNegative
            : (positive
                ? context.marketPositive
                : context.colors.textSecondary));
    final barFill = pct == null ? 0.0 : (pct.abs() / 30.0).clamp(0.08, 1.0);

    return IntelligenceInsetPanel(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: compact ? 8 : 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            alignment: Alignment.center,
            child: Icon(
              negative
                  ? Icons.trending_down_rounded
                  : (positive
                      ? Icons.trending_up_rounded
                      : stressPresetIcon(presetId)),
              size: 16,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  child: LinearProgressIndicator(
                    value: barFill,
                    minHeight: 4,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Impact on Portfolio',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.colors.textTertiary,
                      fontSize: 10,
                    ),
              ),
              Text(
                pct == null
                    ? '—'
                    : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                abs == null ? '—' : currency.format(abs),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
