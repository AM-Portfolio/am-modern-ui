import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mf_error_message.dart';
import '../../data/mf_scheme_view.dart';
import '../../providers/mf_providers.dart';
import '../widgets/mf_catalog_pulse.dart';
import '../widgets/mf_category_icon_row.dart';
import '../widgets/mf_empty_state.dart';
import '../widgets/mf_explore_filter_bar.dart';
import '../widgets/mf_explore_right_rail.dart';
import '../widgets/mf_fund_card.dart';
import '../widgets/mf_fund_explorer_table.dart';

class MfExplorePage extends ConsumerStatefulWidget {
  const MfExplorePage({super.key});

  @override
  ConsumerState<MfExplorePage> createState() => _MfExplorePageState();
}

class _MfExplorePageState extends ConsumerState<MfExplorePage> {
  MfExploreCategoryFilter _category = MfExploreCategoryFilter.all;
  // Default All so seed peer (Growth + IDCW) both show; Growth still one tap away.
  MfExploreOptionFilter _optionFilter = MfExploreOptionFilter.all;
  MfExploreRiskFilter _riskFilter = MfExploreRiskFilter.all;
  String? _amcFilter;
  MfReturnPeriod _period = MfReturnPeriod.y1;
  bool _purchaseOnly = true;

  Color get _accent =>
      ModuleColorProvider.maybeOf(context) ?? ModuleColors.mutualFund;

  List<MfSchemeView> _viewsFromCatalog(List<MfSchemeView> all) {
    var list = all;
    switch (_category) {
      case MfExploreCategoryFilter.all:
        break;
      case MfExploreCategoryFilter.equity:
        list = list.where((f) => f.category.toLowerCase() == 'equity').toList();
      case MfExploreCategoryFilter.hybrid:
        list = list.where((f) => f.category.toLowerCase() == 'hybrid').toList();
      case MfExploreCategoryFilter.debt:
        list = list.where((f) => f.category.toLowerCase() == 'debt').toList();
      case MfExploreCategoryFilter.indexFunds:
        list = list.where((f) => f.category.toLowerCase() == 'index').toList();
    }
    list = list.where(_optionFilter.matches).toList();
    list = list.where(_riskFilter.matches).toList();
    final amcLabels = {
      for (final f in all)
        if (f.amcLabel.isNotEmpty) f.amcLabel,
    };
    if (_amcFilter != null && amcLabels.contains(_amcFilter)) {
      final amc = _amcFilter!.toLowerCase();
      list = list.where((f) => f.amcLabel.toLowerCase() == amc).toList();
    }
    if (_purchaseOnly) {
      list = list.where((f) => f.summary.purchaseAllowed != false).toList();
    }
    list = [...list]
      ..sort((a, b) {
        final ar = a.returnFor(_period.apiKey);
        final br = b.returnFor(_period.apiKey);
        if (ar != null && br != null) return br.compareTo(ar);
        if (ar != null) return -1;
        if (br != null) return 1;
        final aHasNav = a.nav != null;
        final bHasNav = b.nav != null;
        if (aHasNav != bHasNav) return aHasNav ? -1 : 1;
        final amcCmp =
            a.amcLabel.toLowerCase().compareTo(b.amcLabel.toLowerCase());
        if (amcCmp != 0) return amcCmp;
        return a.shortName.compareTo(b.shortName);
      });
    return list;
  }

  void _goScheme(MfSchemeView f) =>
      context.go('/app/mutual-funds/schemes/${f.isin}');

  void _goInvest(MfSchemeView f) =>
      context.go('/app/mutual-funds/invest/${f.isin}');

  void _goSip(MfSchemeView f) =>
      context.go('/app/mutual-funds/systematic?isin=${f.isin}');

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      mfSchemeSearchProvider((
        query: '',
        purchaseAllowed: _purchaseOnly ? true : null,
      )),
    );
    final accent = _accent;

    return AmAdaptiveLayout(
      primaryFlex: 7,
      secondaryFlex: 3,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      columnSpacing: AppSpacing.md,
      primary: async.when(
        loading: () => const MfLoadingBlock(),
        error: (e, _) => MfErrorBanner(
          message: mfErrorMessage(e),
          onRetry: () => ref.invalidate(
            mfSchemeSearchProvider((
              query: '',
              purchaseAllowed: _purchaseOnly ? true : null,
            )),
          ),
        ),
        data: (catalog) {
          final views = dedupeSchemesByIsin(
            catalog.items.map(MfSchemeView.fromSummary).toList(),
          );
          final filtered = _viewsFromCatalog(views);
          final top = filtered.take(3).toList();
          final returnsMissing = filtered.isNotEmpty &&
              filtered.every((v) => v.returnFor(_period.apiKey) == null);
          final amcOptions = {
            for (final v in views)
              if (v.amcLabel.isNotEmpty) v.amcLabel,
          }.toList()
            ..sort();
          final effectiveAmc =
              (_amcFilter != null && amcOptions.contains(_amcFilter))
                  ? _amcFilter
                  : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (catalog.isSeedFallback || catalog.unavailable)
                const MfQuietNote(
                  compact: true,
                  message:
                      'Catalog unavailable — showing UAT seed schemes only.',
                )
              else if (views.any((v) => v.navStale))
                const MfQuietNote(
                  compact: true,
                  message:
                      'Some EOD NAVs are >1 day old — waiting on daily catalog refresh (not live LTP).',
                ),
              MfCatalogPulse(
                funds: filtered,
                period: _period,
                accent: accent,
                onTap: _goScheme,
              ),
              const SizedBox(height: AppSpacing.md),
              MfCategoryIconRow(
                selected: _category,
                accent: accent,
                onSelected: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Explore Mutual Funds',
                style: context.text.sectionTitle().copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Browse dig EOD catalog — filter, then invest or start a SIP.',
                style: context.text.caption().copyWith(
                      color: context.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              MfExploreFilterBar(
                accent: accent,
                category: _category,
                optionFilter: _optionFilter,
                riskFilter: _riskFilter,
                amcFilter: effectiveAmc,
                amcOptions: amcOptions,
                period: _period,
                purchaseOnly: _purchaseOnly,
                onCategory: (c) => setState(() => _category = c),
                onOption: (o) => setState(() => _optionFilter = o),
                onRisk: (r) => setState(() => _riskFilter = r),
                onAmc: (a) => setState(() => _amcFilter = a),
                onPeriod: (p) => setState(() => _period = p),
                onPurchaseOnly: (b) => setState(() => _purchaseOnly = b),
              ),
              const SizedBox(height: AppSpacing.md),
              if (filtered.isEmpty)
                const MfEmptyState(
                  title: 'No funds match',
                  body:
                      'Try another category, clear Buyable, or change Options.',
                  icon: Icons.search_off_rounded,
                )
              else ...[
                if (top.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Top picks',
                    subtitle: returnsMissing
                        ? 'By EOD NAV when ${_period.label} returns are missing'
                        : 'Ranked by ${_period.label} return',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TopPicksRow(
                    funds: top,
                    period: _period,
                    onTap: _goScheme,
                    onInvest: _goInvest,
                    onSip: _goSip,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _SectionHeader(
                  title: 'All schemes',
                  subtitle: '${filtered.length} funds',
                ),
                const SizedBox(height: AppSpacing.sm),
                MfFundExplorerTable(
                  funds: filtered,
                  period: _period,
                  accent: accent,
                  onRowTap: _goScheme,
                  onInvest: _goInvest,
                  onSip: _goSip,
                ),
              ],
            ],
          );
        },
      ),
      secondary: async.maybeWhen(
        data: (catalog) {
          final views = dedupeSchemesByIsin(
            catalog.items.map(MfSchemeView.fromSummary).toList(),
          );
          final filtered = _viewsFromCatalog(views);
          final buyable = filtered.where((f) => f.digPurchaseEnabled);
          final firstBuyable = buyable.isEmpty ? null : buyable.first.isin;
          return MfExploreRightRail(
            accent: accent,
            firstBuyableIsin: firstBuyable,
          );
        },
        orElse: () => MfExploreRightRail(accent: accent),
      ),
    );
  }
}

class _TopPicksRow extends StatelessWidget {
  const _TopPicksRow({
    required this.funds,
    required this.period,
    required this.onTap,
    required this.onInvest,
    required this.onSip,
  });

  final List<MfSchemeView> funds;
  final MfReturnPeriod period;
  final ValueChanged<MfSchemeView> onTap;
  final ValueChanged<MfSchemeView> onInvest;
  final ValueChanged<MfSchemeView> onSip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AmBreakpoints.mobile;
        if (!wide || funds.length == 1) {
          return Column(
            children: [
              for (final f in funds)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: MfFundCard(
                    fund: f,
                    period: period,
                    compact: true,
                    onTap: () => onTap(f),
                    onInvest: f.digPurchaseEnabled ? () => onInvest(f) : null,
                    onSip: f.digPurchaseEnabled ? () => onSip(f) : null,
                  ),
                ),
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < funds.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: MfFundCard(
                    fund: funds[i],
                    period: period,
                    compact: true,
                    onTap: () => onTap(funds[i]),
                    onInvest: funds[i].digPurchaseEnabled
                        ? () => onInvest(funds[i])
                        : null,
                    onSip: funds[i].digPurchaseEnabled
                        ? () => onSip(funds[i])
                        : null,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: context.text.sectionTitle().copyWith(
                color: context.textPrimary,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            subtitle,
            style: context.text.caption().copyWith(
                  color: context.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}
