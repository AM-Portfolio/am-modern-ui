import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mf_error_message.dart';
import '../../data/mf_scheme_view.dart';
import '../../providers/mf_providers.dart';
import '../widgets/mf_empty_state.dart';
import '../widgets/mf_fund_card.dart';
import '../widgets/mf_page_header.dart';

class MfExplorePage extends ConsumerStatefulWidget {
  const MfExplorePage({super.key});

  @override
  ConsumerState<MfExplorePage> createState() => _MfExplorePageState();
}

class _MfExplorePageState extends ConsumerState<MfExplorePage> {
  final _controller = TextEditingController();
  String _query = '';
  MfExploreCategoryFilter _category = MfExploreCategoryFilter.all;
  // Default All so seed peer (Growth + IDCW) both show; Growth still one tap away.
  MfExploreOptionFilter _optionFilter = MfExploreOptionFilter.all;
  MfReturnPeriod _period = MfReturnPeriod.y1;
  bool _purchaseOnly = true;

  Color get _accent =>
      ModuleColorProvider.maybeOf(context) ?? ModuleColors.mutualFund;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        // Dig often lacks mf_scheme_returns; still surface funds that have EOD NAV
        // ahead of SCH-only rows (e.g. new 360 ONE SIF / DYNASIF with null NAV).
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

  void _applyQuery(String q) {
    _controller.value = TextEditingValue(
      text: q,
      selection: TextSelection.collapsed(offset: q.length),
    );
    setState(() => _query = q.trim());
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      mfSchemeSearchProvider((
        query: _query,
        purchaseAllowed: _purchaseOnly ? true : null,
      )),
    );
    final accent = _accent;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const MfPageHeader(
          title: 'Explore funds',
          subtitle:
              'EOD NAV (as-of), not live LTP. Search → filter → invest / SIP.',
        ),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Search by fund name, AMC, or ISIN',
            isDense: true,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (v) => setState(() => _query = v.trim()),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final chip in exploreAmcSearchChips)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AmToggleChip(
                    label: chip,
                    selected: _query.toLowerCase() == chip.toLowerCase(),
                    compact: true,
                    accentColor: accent,
                    onTap: () => _applyQuery(chip),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final o in MfExploreOptionFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AmToggleChip(
                    label: o.label,
                    selected: _optionFilter == o,
                    filled: true,
                    compact: true,
                    accentColor: accent,
                    onTap: () => setState(() => _optionFilter = o),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in MfExploreCategoryFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AmToggleChip(
                    label: _categoryLabel(f),
                    selected: _category == f,
                    filled: true,
                    compact: true,
                    accentColor: accent,
                    onTap: () => setState(() => _category = f),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AmToggleChip(
                  label: 'Buyable',
                  selected: _purchaseOnly,
                  filled: true,
                  compact: true,
                  accentColor: accent,
                  onTap: () => setState(() => _purchaseOnly = !_purchaseOnly),
                ),
              ),
              for (final p in const [
                MfReturnPeriod.m1,
                MfReturnPeriod.m3,
                MfReturnPeriod.m6,
                MfReturnPeriod.y1,
                MfReturnPeriod.y3,
                MfReturnPeriod.y5,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AmToggleChip(
                    label: p.label,
                    selected: _period == p,
                    compact: true,
                    accentColor: accent,
                    onTap: () => setState(() => _period = p),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        async.when(
          loading: () => const MfLoadingBlock(),
          error: (e, _) => MfErrorBanner(message: mfErrorMessage(e)),
          data: (catalog) {
            final views = dedupeSchemesByIsin(
              catalog.items.map(MfSchemeView.fromSummary).toList(),
            );
            final filtered = _viewsFromCatalog(views);
            final top = filtered.take(3).toList();
            final rest = filtered.length > 3
                ? filtered.sublist(3)
                : const <MfSchemeView>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (catalog.isSeedFallback || catalog.unavailable)
                  const MfQuietNote(
                    message:
                        'Catalog unavailable — showing 2 UAT seed schemes only (360 ONE). '
                        'Search HDFC/SBI chips need a healthy dig catalog, not seed-fallback.',
                  )
                else if (views.any((v) => v.navStale))
                  const MfQuietNote(
                    message:
                        'Some EOD NAV dates are more than one day old — waiting on daily catalog refresh (not live LTP).',
                  ),
                if (filtered.isEmpty)
                  const MfEmptyState(
                    title: 'No funds match',
                    body:
                        'Try Growth/IDCW/All options, another category, clear Buyable, or search by ISIN.',
                    icon: Icons.search_off_rounded,
                  )
                else ...[
                  _SectionHeader(
                    title: 'Top picks',
                    subtitle:
                        'Ranked by ${_period.label} return when available',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...top.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: MfFundCard(
                        fund: f,
                        period: _period,
                        onTap: () =>
                            context.go('/app/mutual-funds/schemes/${f.isin}'),
                        onInvest: f.digPurchaseEnabled
                            ? () => context
                                .go('/app/mutual-funds/invest/${f.isin}')
                            : null,
                        onSip: f.digPurchaseEnabled
                            ? () => context.go(
                                  '/app/mutual-funds/systematic?isin=${f.isin}',
                                )
                            : null,
                      ),
                    ),
                  ),
                  if (rest.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SectionHeader(
                      title: 'All schemes',
                      subtitle: '${filtered.length} funds',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...rest.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: MfFundCard(
                          fund: f,
                          period: _period,
                          onTap: () => context
                              .go('/app/mutual-funds/schemes/${f.isin}'),
                          onInvest: f.digPurchaseEnabled
                              ? () => context
                                  .go('/app/mutual-funds/invest/${f.isin}')
                              : null,
                          onSip: f.digPurchaseEnabled
                              ? () => context.go(
                                    '/app/mutual-funds/systematic?isin=${f.isin}',
                                  )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  String _categoryLabel(MfExploreCategoryFilter f) => switch (f) {
        MfExploreCategoryFilter.all => 'All',
        MfExploreCategoryFilter.equity => 'Equity',
        MfExploreCategoryFilter.hybrid => 'Hybrid',
        MfExploreCategoryFilter.debt => 'Debt',
        MfExploreCategoryFilter.indexFunds => 'Index',
      };
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}
