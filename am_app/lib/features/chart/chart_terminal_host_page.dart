import 'package:am_chart_ui/am_chart_ui.dart';
import 'package:am_common/am_common.dart';
import 'package:am_market_ui/am_market_ui.dart';
import 'package:am_news_ui/am_news_ui.dart';
import 'package:am_paper_ui/am_paper_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chart_portfolio_holdings_panel.dart';
import 'chart_portfolio_sidebar.dart';
import 'market_sdk_chart_providers.dart';

enum _ChartBottomSection {
  holdings,
  overview,
  financials,
  shareholding,
  news,
  optionChain,
  futures,
  margin,
}

/// Chart terminal host: live market OHLC, watchlist + portfolio sidebar,
/// EI section tags (no hero / no Charts) + F&O bottom strip.
class ChartTerminalHostPage extends ConsumerWidget {
  const ChartTerminalHostPage({
    super.key,
    this.initialSymbol,
    this.initialTimeframe,
  });

  final String? initialSymbol;
  final String? initialTimeframe;

  static final _liveHistorical = MarketSdkHistoricalProvider();
  static final _liveMarket = MarketSdkMarketDataProvider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final omsAsync = ref.watch(paperOmsCubitProvider);

    // Nested scope forces live Market SDK providers for this route only.
    return ProviderScope(
      overrides: [
        chartHistoricalProvider.overrideWithValue(_liveHistorical),
        chartMarketProvider.overrideWithValue(_liveMarket),
      ],
      child: omsAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _ChartTerminalBody(
          initialSymbol: initialSymbol,
          initialTimeframe: initialTimeframe,
          paperEnabled: false,
        ),
        data: (cubit) {
          return BlocProvider<PaperOmsCubit>.value(
            value: cubit,
            child: _ChartTerminalBody(
              initialSymbol: initialSymbol,
              initialTimeframe: initialTimeframe,
              paperEnabled: cubit.state.wallet != null,
            ),
          );
        },
      ),
    );
  }
}

class _ChartTerminalBody extends ConsumerStatefulWidget {
  const _ChartTerminalBody({
    this.initialSymbol,
    this.initialTimeframe,
    required this.paperEnabled,
  });

  final String? initialSymbol;
  final String? initialTimeframe;
  final bool paperEnabled;

  @override
  ConsumerState<_ChartTerminalBody> createState() => _ChartTerminalBodyState();
}

class _ChartTerminalBodyState extends ConsumerState<_ChartTerminalBody>
    with SingleTickerProviderStateMixin {
  _ChartBottomSection _section = _ChartBottomSection.overview;
  late final TabController _sidebarTabController;

  static const _baseTags = <(_ChartBottomSection, String)>[
    (_ChartBottomSection.overview, 'Overview'),
    (_ChartBottomSection.financials, 'Financials'),
    (_ChartBottomSection.shareholding, 'Shareholding'),
    (_ChartBottomSection.news, 'News'),
    (_ChartBottomSection.optionChain, 'Option Chain'),
    (_ChartBottomSection.futures, 'Futures'),
    (_ChartBottomSection.margin, 'Margin'),
  ];

  List<(_ChartBottomSection, String)> get _tags {
    final selected = ref.watch(chartSelectedPortfolioProvider);
    if (selected == null) return _baseTags;
    return [
      (_ChartBottomSection.holdings, 'Holdings'),
      ..._baseTags,
    ];
  }

  bool _isFoSection(_ChartBottomSection s) =>
      s == _ChartBottomSection.optionChain ||
      s == _ChartBottomSection.futures ||
      s == _ChartBottomSection.margin;

  void _syncFoSymbol(String symbol) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    ref.read(foActiveSymbolProvider.notifier).state = sym;
  }

  @override
  void initState() {
    super.initState();
    _sidebarTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _sidebarTabController.dispose();
    super.dispose();
  }

  Widget _sectionBody(String symbol, {bool scrollable = true}) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) {
      return Center(
        child: Text(
          'Select a symbol',
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
        ),
      );
    }

    Widget body;
    switch (_section) {
      case _ChartBottomSection.holdings:
        // Rendered separately in bottomPanelBuilder.
        return const SizedBox.shrink();
      case _ChartBottomSection.overview:
        body = EquityInsiderKpis(key: ValueKey('kpi-$sym'), symbol: sym);
      case _ChartBottomSection.financials:
        body = EquityInsiderFinancials(
          key: ValueKey('fin-$sym'),
          symbol: sym,
          compact: true,
        );
      case _ChartBottomSection.shareholding:
        body = EquityInsiderShareholding(
          key: ValueKey('sh-$sym'),
          symbol: sym,
        );
      case _ChartBottomSection.news:
        return SymbolNewsSection(
          key: ValueKey('news-$sym'),
          symbol: sym,
          surface: NewsUiSurface.equityInsider,
        );
      case _ChartBottomSection.optionChain:
        return FoPage(
          key: ValueKey('fo-oc-$sym'),
          initialSymbol: sym,
          embed: true,
          embedSection: FoEmbedSection.optionChain,
        );
      case _ChartBottomSection.futures:
        return FoPage(
          key: ValueKey('fo-fut-$sym'),
          initialSymbol: sym,
          embed: true,
          embedSection: FoEmbedSection.futures,
        );
      case _ChartBottomSection.margin:
        return FoPage(
          key: ValueKey('fo-mgn-$sym'),
          initialSymbol: sym,
          embed: true,
          embedSection: FoEmbedSection.margin,
        );
    }

    if (!scrollable) return body;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: body,
    );
  }

  void _openFullView(String symbol) {
    final tags = _tags;
    final label = tags.firstWhere((t) => t.$1 == _section).$2;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                _section == _ChartBottomSection.holdings
                    ? label
                    : '$label · ${symbol.trim().toUpperCase()}',
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            body: _section == _ChartBottomSection.holdings
                ? ChartPortfolioHoldingsPanel(
                    onSelectSymbol: (_) {},
                  )
                : _sectionBody(symbol, scrollable: true),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tags = _tags;
    final selectedPortfolio = ref.watch(chartSelectedPortfolioProvider);
    if (_section == _ChartBottomSection.holdings &&
        selectedPortfolio == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _section = _ChartBottomSection.overview);
        }
      });
    }

    return ChartWorkspacePage(
      initialSymbol: widget.initialSymbol,
      initialTimeframe: widget.initialTimeframe,
      sidebarWidth: 300,
      bottomPanelHeight: 360,
      showHeaderSearch: true,
      sidebarBuilder: (context, state, ctrl) {
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: theme.colorScheme.surface,
              child: TabBar(
                controller: _sidebarTabController,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.hintColor,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Watchlist', height: 36),
                  Tab(text: 'Portfolio', height: 36),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _sidebarTabController,
                children: [
                  PaperWatchlistPane(
                    selectedSymbol: state.symbol,
                    onSelectSymbol: (s) => ctrl.selectSymbol(s),
                    onBuySell: (_, __) {},
                    onOpenFundamentals: (s) {
                      ctrl.selectSymbol(s);
                      setState(() => _section = _ChartBottomSection.overview);
                    },
                    compactChrome: true,
                    showRecentHistory: widget.paperEnabled,
                    showSearch: false,
                  ),
                  ChartPortfolioSidebar(
                    paperEnabled: widget.paperEnabled,
                    onPortfolioSelected: (_) {
                      setState(() => _section = _ChartBottomSection.holdings);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
      bottomPanelBuilder: (context, state, ctrl) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChartBottomSectionBar(
              tags: tags,
              selected: _section,
              onSelected: (tag) {
                setState(() => _section = tag);
                if (_isFoSection(tag)) {
                  _syncFoSymbol(state.symbol);
                }
              },
              onOpenFullView: () => _openFullView(state.symbol),
            ),
            Expanded(
              child: _section == _ChartBottomSection.holdings
                  ? ChartPortfolioHoldingsPanel(
                      onSelectSymbol: (s) => ctrl.selectSymbol(s),
                    )
                  : _sectionBody(state.symbol),
            ),
          ],
        );
      },
    );
  }
}

/// Modern below-chart section switcher: icon + label, underline active state.
class _ChartBottomSectionBar extends StatelessWidget {
  const _ChartBottomSectionBar({
    required this.tags,
    required this.selected,
    required this.onSelected,
    required this.onOpenFullView,
  });

  final List<(_ChartBottomSection, String)> tags;
  final _ChartBottomSection selected;
  final ValueChanged<_ChartBottomSection> onSelected;
  final VoidCallback onOpenFullView;

  static IconData _iconFor(_ChartBottomSection section) {
    return switch (section) {
      _ChartBottomSection.holdings => Icons.account_balance_wallet_outlined,
      _ChartBottomSection.overview => Icons.grid_view_rounded,
      _ChartBottomSection.financials => Icons.bar_chart_rounded,
      _ChartBottomSection.shareholding => Icons.account_tree_outlined,
      _ChartBottomSection.news => Icons.article_outlined,
      _ChartBottomSection.optionChain => Icons.hub_outlined,
      _ChartBottomSection.futures => Icons.trending_up_rounded,
      _ChartBottomSection.margin => Icons.link_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final border = theme.dividerColor.withValues(alpha: 0.45);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: tags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 2),
                itemBuilder: (context, i) {
                  final (tag, label) = tags[i];
                  final isActive = selected == tag;
                  final color = isActive ? accent : muted;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelected(tag),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isActive ? accent : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_iconFor(tag), size: 15, color: color),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                    isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive
                                    ? theme.colorScheme.onSurface
                                    : muted,
                                letterSpacing: 0.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              tooltip: 'Full view',
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: onOpenFullView,
              icon: Icon(
                Icons.open_in_full,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
