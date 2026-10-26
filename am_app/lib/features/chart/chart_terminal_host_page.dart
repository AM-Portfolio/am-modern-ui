import 'package:am_chart_ui/am_chart_ui.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/am_market_ui.dart';
import 'package:am_news_ui/am_news_ui.dart';
import 'package:am_paper_ui/am_paper_ui.dart';
import 'package:am_portfolio_ui/am_portfolio_ui.dart';
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
  heatmap,
  news,
  optionChain,
  futures,
  margin,
  healthScore,
  portfolioXRay,
  riskRadar,
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
    with TickerProviderStateMixin {
  _ChartBottomSection _section = _ChartBottomSection.overview;
  late final TabController _sidebarTabController;
  late final WatchlistController _watchlistController;
  late final MarketProvider _marketProvider;
  ChartTerminalController? _currentTerminalCtrl;
  String _indicesSearchQuery = '';
  IndicesRegion _region = IndicesRegion.indian;

  static const _baseTags = <(_ChartBottomSection, String)>[
    (_ChartBottomSection.overview, 'Overview'),
    (_ChartBottomSection.financials, 'Financials'),
    (_ChartBottomSection.shareholding, 'Shareholding'),
    (_ChartBottomSection.news, 'News'),
    (_ChartBottomSection.optionChain, 'Option Chain'),
    (_ChartBottomSection.futures, 'Futures'),
    (_ChartBottomSection.margin, 'Margin'),
  ];

  static const _indexTags = <(_ChartBottomSection, String)>[
    (_ChartBottomSection.heatmap, 'Heatmap'),
    (_ChartBottomSection.news, 'News'),
    (_ChartBottomSection.optionChain, 'Option Chain'),
    (_ChartBottomSection.futures, 'Futures'),
    (_ChartBottomSection.margin, 'Margin'),
  ];

  bool _isIndexSymbol(String symbol) {
    final s = symbol.trim().toUpperCase();
    if (s.isEmpty) return false;
    if (_marketProvider.allIndicesData
            .any((idx) => idx.indexSymbol.toUpperCase() == s) ||
        _marketProvider.globalIndicesData
            .any((idx) => idx.indexSymbol.toUpperCase() == s)) {
      return true;
    }
    return s.startsWith('NIFTY') ||
        s.startsWith('BANKNIFTY') ||
        s.startsWith('FINNIFTY') ||
        s.startsWith('MIDCPNIFTY') ||
        s.contains('SENSEX') ||
        s.contains('INDIA VIX') ||
        s.startsWith('BSE ') ||
        s.startsWith('CNX ') ||
        const {
          'NASDAQ',
          'DOW JONES',
          'S&P 500',
          'FTSE 100',
          'DAX',
          'NIKKEI 225',
          'HANG SENG',
          'KOSPI',
          'SHANGHAI COMPOSITE',
          'CAC 40',
          'GIFT NIFTY',
        }.contains(s);
  }

  List<(_ChartBottomSection, String)> _getTags(String activeSymbol) {
    final selected = ref.watch(chartSelectedPortfolioProvider);
    if (selected != null && _sidebarTabController.index == 2) {
      return [
        (_ChartBottomSection.overview, 'Overview'),
        (_ChartBottomSection.holdings, 'Holdings'),
        (_ChartBottomSection.healthScore, 'Health Score'),
        (_ChartBottomSection.portfolioXRay, 'Portfolio X-Ray'),
        (_ChartBottomSection.riskRadar, 'Risk Radar'),
      ];
    }
    if (_isIndexSymbol(activeSymbol)) {
      return _indexTags;
    }
    return _baseTags;
  }

  bool _isFoSection(_ChartBottomSection s) =>
      s == _ChartBottomSection.optionChain ||
      s == _ChartBottomSection.futures ||
      s == _ChartBottomSection.margin;

  void _syncFoSymbol(String symbol) {
    var sym = symbol.trim().toUpperCase();
    if (sym == 'NIFTY 50') sym = 'NIFTY';
    if (sym == 'NIFTY BANK') sym = 'BANKNIFTY';
    if (sym.isEmpty) return;
    ref.read(foActiveSymbolProvider.notifier).state = sym;
  }

  @override
  void initState() {
    super.initState();
    _marketProvider = MarketProvider();
    _marketProvider.addListener(() {
      if (mounted) setState(() {});
    });

    _watchlistController = WatchlistController(
      onSelectSymbol: (s) {
        _currentTerminalCtrl?.selectSymbol(s);
        _syncFoSymbol(s);
        if (_isIndexSymbol(s)) {
          _marketProvider.selectIndex(s);
          if (_section == _ChartBottomSection.overview ||
              _section == _ChartBottomSection.financials ||
              _section == _ChartBottomSection.shareholding) {
            setState(() => _section = _ChartBottomSection.heatmap);
          }
        } else {
          if (_section == _ChartBottomSection.heatmap) {
            setState(() => _section = _ChartBottomSection.overview);
          }
        }
      },
    );
    _watchlistController.bootstrap();

    _sidebarTabController = TabController(length: 3, vsync: this);
    _sidebarTabController.addListener(() {
      if (!mounted) return;
      if (_sidebarTabController.index != 2) {
        if (_section == _ChartBottomSection.healthScore ||
            _section == _ChartBottomSection.portfolioXRay ||
            _section == _ChartBottomSection.riskRadar ||
            _section == _ChartBottomSection.holdings) {
          final sym = ref.read(chartTerminalProvider).symbol;
          _section = _isIndexSymbol(sym)
              ? _ChartBottomSection.heatmap
              : _ChartBottomSection.overview;
        }
      } else {
        if (_isFoSection(_section) ||
            _section == _ChartBottomSection.news ||
            _section == _ChartBottomSection.financials ||
            _section == _ChartBottomSection.shareholding ||
            _section == _ChartBottomSection.heatmap) {
          _section = _ChartBottomSection.overview;
        }
      }
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_marketProvider.allIndicesData.isEmpty) {
          _marketProvider.loadAllIndicesData();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ChartTerminalBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSym = widget.initialSymbol?.trim();
    final prevSym = oldWidget.initialSymbol?.trim();
    if (nextSym == null || nextSym.isEmpty) return;
    if (nextSym == prevSym) return;
    final current = ref.read(chartTerminalProvider).symbol.trim();
    if (current.toUpperCase() == nextSym.toUpperCase()) return;
    final existing = _currentTerminalCtrl;
    if (existing != null) {
      existing.selectSymbol(nextSym);
    } else {
      ref.read(chartTerminalProvider.notifier).selectSymbol(nextSym);
    }
    _syncFoSymbol(nextSym);
  }

  @override
  void dispose() {
    ChartSearchBridge.unbind();
    _marketProvider.dispose();
    _watchlistController.dispose();
    _sidebarTabController.dispose();
    super.dispose();
  }

  void _bindChartSearch(ChartTerminalController ctrl, ChartTerminalState state) {
    ChartSearchBridge.bind(
      recentSymbols: state.recentSearches,
      selectSymbol: (sym) {
        ctrl.selectSymbol(sym);
        _syncFoSymbol(sym);
        if (_isIndexSymbol(sym)) {
          _marketProvider.selectIndex(sym);
          if (_section == _ChartBottomSection.overview ||
              _section == _ChartBottomSection.financials ||
              _section == _ChartBottomSection.shareholding) {
            setState(() => _section = _ChartBottomSection.heatmap);
          }
        } else if (_section == _ChartBottomSection.heatmap) {
          setState(() => _section = _ChartBottomSection.overview);
        }
      },
    );
  }

  void _handleIndexSelected(
    StockIndicesMarketData data,
    ChartTerminalController ctrl,
  ) {
    final sym = data.indexSymbol.trim();
    ctrl.selectSymbol(sym);
    _syncFoSymbol(sym);
    _marketProvider.selectIndex(sym);
    _watchlistController.selectIndexSource(sym);
    setState(() {
      _section = _ChartBottomSection.heatmap;
    });
    if (mounted && MediaQuery.sizeOf(context).width < 768 && Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
    }
  }

  Widget _sectionBody(
    String symbol, {
    bool scrollable = true,
    _ChartBottomSection? sectionOverride,
  }) {
    final effectiveSection = sectionOverride ?? _section;
    final selectedPortfolio = ref.watch(chartSelectedPortfolioProvider);

    if (selectedPortfolio != null && _sidebarTabController.index == 2) {
      Widget? portfolioBody;
      switch (effectiveSection) {
        case _ChartBottomSection.holdings:
          return const SizedBox.shrink();
        case _ChartBottomSection.overview:
          portfolioBody = PortfolioOverviewWidget(
            portfolioId: selectedPortfolio.id,
            showBottomCards: false,
          );
          break;
        case _ChartBottomSection.healthScore:
          portfolioBody = PortfolioHealthCard(
            portfolioId: selectedPortfolio.id,
          );
          break;
        case _ChartBottomSection.portfolioXRay:
          portfolioBody = PortfolioXrayPanel(
            portfolioId: selectedPortfolio.id,
          );
          break;
        case _ChartBottomSection.riskRadar:
          portfolioBody = PortfolioRiskRadarCard(
            portfolioId: selectedPortfolio.id,
          );
          break;
        default:
          return const SizedBox.shrink();
      }

      return _PortfolioCubitProvider(
        portfolioId: selectedPortfolio.id,
        child: portfolioBody,
      );
    }

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
    switch (effectiveSection) {
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
      case _ChartBottomSection.heatmap:
        return MarketHeatmapWidget(
          key: ValueKey('heatmap-$sym'),
          provider: _marketProvider,
          symbol: sym,
          onSelectStock: (stockSym) {
            _currentTerminalCtrl?.selectSymbol(stockSym);
            _syncFoSymbol(stockSym);
            setState(() {
              _section = _ChartBottomSection.overview;
            });
          },
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
      default:
        return const SizedBox.shrink();
    }

    if (!scrollable) return body;

    // Financials / Shareholding fill the bottom panel height (no dead scroll gap).
    final fillPanel = effectiveSection == _ChartBottomSection.financials ||
        effectiveSection == _ChartBottomSection.shareholding;
    if (fillPanel) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: body,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: double.infinity,
          child: body,
        ),
      ),
    );
  }

  void _openFullView(String symbol) {
    PaperOmsCubit? cubit;
    try {
      cubit = context.read<PaperOmsCubit>();
    } catch (_) {
      cubit = null;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final dialog = Dialog.fullscreen(
          child: _MaximizedChartPanelDialog(
            initialSection: _section,
            symbol: symbol,
            getTags: _getTags,
            isIndexSymbol: _isIndexSymbol,
            onSectionChanged: (newSection) {
              setState(() => _section = newSection);
            },
            onSyncFoSymbol: (sym) {
              if (_isFoSection(_section)) {
                _syncFoSymbol(sym);
              }
            },
            bodyBuilder: (dialogContext, section, sym) {
              if (section == _ChartBottomSection.holdings) {
                return ChartPortfolioHoldingsPanel(
                  onSelectSymbol: (s) {
                    _currentTerminalCtrl?.selectSymbol(s);
                    _syncFoSymbol(s);
                  },
                );
              }
              return _sectionBody(
                sym,
                scrollable: true,
                sectionOverride: section,
              );
            },
          ),
        );
        if (cubit != null) {
          return BlocProvider<PaperOmsCubit>.value(
            value: cubit,
            child: dialog,
          );
        }
        return dialog;
      },
    );
  }

  Widget _buildIndicesSidebarTab(
    BuildContext context,
    ChartTerminalState state,
    ChartTerminalController ctrl,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = _marketProvider;

    final rawIndices = _region == IndicesRegion.global
        ? provider.globalIndicesData
        : provider.allIndicesData;

    final q = _indicesSearchQuery.trim().toLowerCase();
    final filtered = rawIndices.where((idx) {
      if (q.isEmpty) return true;
      return idx.indexSymbol.toLowerCase().contains(q) ||
          (idx.indexName ?? '').toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: MarketRegionToggle(
            value: _region,
            onChanged: (r) {
              setState(() => _region = r);
              if (r == IndicesRegion.global &&
                  provider.globalIndicesData.isEmpty) {
                provider.loadGlobalIndicesData();
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: TextField(
            onChanged: (v) => setState(() => _indicesSearchQuery = v),
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search indices...',
              hintStyle: TextStyle(fontSize: 13, color: theme.hintColor),
              prefixIcon: Icon(Icons.search, size: 18, color: theme.hintColor),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: context.glassOverlay(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: provider.isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          _region == IndicesRegion.global
                              ? 'No global indices found'
                              : 'No indices found',
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.15),
                  ),
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    final isSelected = item.indexSymbol.toUpperCase() ==
                        state.symbol.toUpperCase();
                    final isPositive = item.change >= 0;
                    final changeColor = isPositive
                        ? context.marketPositive
                        : context.marketNegative;
                    return InkWell(
                      onTap: () => _handleIndexSelected(item, ctrl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? context.colors.marketCardSurface
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.08))
                              : Colors.transparent,
                          border: isSelected
                              ? Border(
                                  left: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 3,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.indexSymbol.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? context.textPrimary
                                          : context.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (item.indexName ?? '').isNotEmpty
                                        ? item.indexName!
                                        : 'Index',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.hintColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item.lastPrice > 0
                                      ? '₹${item.lastPrice.toStringAsFixed(2)}'
                                      : '—',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? changeColor
                                        : context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${isPositive ? '+' : ''}${item.pChange.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: changeColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final terminalState = ref.watch(chartTerminalProvider);
    final terminalCtrl = ref.read(chartTerminalProvider.notifier);
    _currentTerminalCtrl = terminalCtrl;
    _bindChartSearch(terminalCtrl, terminalState);
    final activeSymbol = terminalState.symbol;
    final isIndex = _isIndexSymbol(activeSymbol);
    final tags = _getTags(activeSymbol);

    if (isIndex &&
        _marketProvider.currentIndexData?.indexSymbol.toUpperCase() !=
            activeSymbol.toUpperCase()) {
      _marketProvider.selectIndex(activeSymbol);
    }

    if (!tags.any((t) => t.$1 == _section)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _section = isIndex
                ? _ChartBottomSection.heatmap
                : _ChartBottomSection.overview;
          });
        }
      });
    }

    final selectedPortfolio = ref.watch(chartSelectedPortfolioProvider);
    if (_section == _ChartBottomSection.holdings && selectedPortfolio == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _section = isIndex
              ? _ChartBottomSection.heatmap
              : _ChartBottomSection.overview);
        }
      });
    }

    final chartWorkspace = ChartWorkspacePage(
      initialSymbol: widget.initialSymbol,
      initialTimeframe: widget.initialTimeframe,
      sidebarWidth: 300,
      bottomPanelHeight: 360,
      showHeaderSearch: true,
      sidebarBuilder: (context, state, ctrl) {
        _currentTerminalCtrl = ctrl;
        final theme = Theme.of(context);
        final sidebarWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
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
                        Tab(text: 'Indices', height: 36),
                        Tab(text: 'Portfolio', height: 36),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Minimize sidebar',
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      Icons.chevron_right,
                      color: theme.hintColor,
                    ),
                    onPressed: () {
                      ctrl.setSidebarMinimized(true);
                      if (MediaQuery.sizeOf(context).width < 768 &&
                          Navigator.of(context).canPop()) {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _sidebarTabController,
                children: [
                  PaperWatchlistPane(
                    controller: _watchlistController,
                    selectedSymbol: state.symbol,
                    onSelectSymbol: (s) {
                      ctrl.selectSymbol(s);
                      if (MediaQuery.sizeOf(context).width < 768 &&
                          Navigator.of(context).canPop()) {
                        Navigator.of(context).maybePop();
                      }
                    },
                    onBuySell: (_, __) {},
                    onOpenFundamentals: (s) {
                      ctrl.selectSymbol(s);
                      setState(() => _section = _ChartBottomSection.overview);
                      if (MediaQuery.sizeOf(context).width < 768 &&
                          Navigator.of(context).canPop()) {
                        Navigator.of(context).maybePop();
                      }
                    },
                    compactChrome: true,
                    showRecentHistory: widget.paperEnabled,
                    showSearch: false,
                    onOpenAllIndices: () => _sidebarTabController.animateTo(1),
                  ),
                  _buildIndicesSidebarTab(context, state, ctrl),
                  ChartPortfolioSidebar(
                    paperEnabled: widget.paperEnabled,
                    onPortfolioSelected: (_) {
                      setState(() => _section = _ChartBottomSection.holdings);
                      if (MediaQuery.sizeOf(context).width < 768 &&
                          Navigator.of(context).canPop()) {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );

        PaperOmsCubit? cubit;
        try {
          cubit = context.read<PaperOmsCubit>();
        } catch (_) {
          cubit = null;
        }

        if (cubit != null) {
          return BlocProvider<PaperOmsCubit>.value(
            value: cubit,
            child: sidebarWidget,
          );
        }
        return sidebarWidget;
      },
      bottomPanelBuilder: (context, state, ctrl) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChartBottomSectionBar(
              tags: _getTags(state.symbol),
              selected: _section,
              onSelected: (tag) {
                setState(() => _section = tag);
                if (tag == _ChartBottomSection.heatmap) {
                  ctrl.setBottomMinimized(false);
                }
                if (_isFoSection(tag)) {
                  _syncFoSymbol(state.symbol);
                }
              },
              onOpenFullView: () => _openFullView(state.symbol),
              onMinimize: () => ctrl.setBottomMinimized(true),
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

    return chartWorkspace;
  }
}

/// Modern below-chart section switcher: icon + label, underline active state.
class _ChartBottomSectionBar extends StatelessWidget {
  const _ChartBottomSectionBar({
    required this.tags,
    required this.selected,
    required this.onSelected,
    required this.onOpenFullView,
    this.onMinimize,
  });

  final List<(_ChartBottomSection, String)> tags;
  final _ChartBottomSection selected;
  final ValueChanged<_ChartBottomSection> onSelected;
  final VoidCallback onOpenFullView;
  final VoidCallback? onMinimize;

  static IconData _iconFor(_ChartBottomSection section) {
    return switch (section) {
      _ChartBottomSection.holdings => Icons.account_balance_wallet_outlined,
      _ChartBottomSection.overview => Icons.grid_view_rounded,
      _ChartBottomSection.financials => Icons.bar_chart_rounded,
      _ChartBottomSection.shareholding => Icons.account_tree_outlined,
      _ChartBottomSection.heatmap => Icons.view_quilt_rounded,
      _ChartBottomSection.news => Icons.article_outlined,
      _ChartBottomSection.optionChain => Icons.hub_outlined,
      _ChartBottomSection.futures => Icons.trending_up_rounded,
      _ChartBottomSection.margin => Icons.link_rounded,
      _ChartBottomSection.healthScore => Icons.favorite_border_rounded,
      _ChartBottomSection.portfolioXRay => Icons.auto_awesome_rounded,
      _ChartBottomSection.riskRadar => Icons.radar_rounded,
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
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
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
            if (onMinimize != null) ...[
              IconButton(
                tooltip: 'Minimize bottom panel',
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: onMinimize,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: muted,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _PortfolioCubitProvider extends ConsumerWidget {
  final Widget child;
  final String portfolioId;

  const _PortfolioCubitProvider({
    required this.child,
    required this.portfolioId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioServiceAsync = ref.watch(portfolioServiceProvider);
    final analyticsServiceAsync = ref.watch(portfolioAnalyticsServiceProvider);

    if (portfolioServiceAsync.isLoading || analyticsServiceAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (portfolioServiceAsync.hasError || analyticsServiceAsync.hasError) {
      return const Center(child: Text('Failed to load portfolio services'));
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<PortfolioCubit>(
          create: (_) => PortfolioCubit(portfolioServiceAsync.requireValue)..loadPortfolioById(portfolioId),
        ),
        BlocProvider<PortfolioAnalyticsCubit>(
          create: (_) => PortfolioAnalyticsCubit(analyticsServiceAsync.requireValue),
        ),
      ],
      child: child,
    );
  }
}

/// Maximized fullscreen view for chart panel with all section tabs visible in the upper section.
class _MaximizedChartPanelDialog extends ConsumerStatefulWidget {
  const _MaximizedChartPanelDialog({
    required this.initialSection,
    required this.symbol,
    required this.getTags,
    required this.isIndexSymbol,
    required this.onSectionChanged,
    required this.onSyncFoSymbol,
    required this.bodyBuilder,
  });

  final _ChartBottomSection initialSection;
  final String symbol;
  final List<(_ChartBottomSection, String)> Function(String symbol) getTags;
  final bool Function(String symbol) isIndexSymbol;
  final ValueChanged<_ChartBottomSection> onSectionChanged;
  final void Function(String symbol) onSyncFoSymbol;
  final Widget Function(
    BuildContext context,
    _ChartBottomSection section,
    String symbol,
  ) bodyBuilder;

  @override
  ConsumerState<_MaximizedChartPanelDialog> createState() =>
      _MaximizedChartPanelDialogState();
}

class _MaximizedChartPanelDialogState
    extends ConsumerState<_MaximizedChartPanelDialog> {
  late _ChartBottomSection _currentSection;
  String? _lastSymbol;

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSection;
  }

  void _selectSection(_ChartBottomSection section, String activeSymbol) {
    if (_currentSection == section) return;
    setState(() => _currentSection = section);
    widget.onSectionChanged(section);
    widget.onSyncFoSymbol(activeSymbol);
  }

  @override
  Widget build(BuildContext context) {
    final terminalState = ref.watch(chartTerminalProvider);
    final activeSymbol = terminalState.symbol.isNotEmpty
        ? terminalState.symbol
        : widget.symbol;

    if (_lastSymbol != null && _lastSymbol != activeSymbol) {
      _currentSection = _ChartBottomSection.overview;
    }
    _lastSymbol = activeSymbol;

    final tags = widget.getTags(activeSymbol);
    final validSection = tags.any((t) => t.$1 == _currentSection)
        ? _currentSection
        : (tags.isNotEmpty ? tags.first.$1 : _currentSection);

    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final border = theme.dividerColor.withValues(alpha: 0.45);
    final isCompact = MediaQuery.sizeOf(context).width < 680;
    final isIndex = widget.isIndexSymbol(activeSymbol);

    Widget buildTabs() {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 2),
        itemBuilder: (context, i) {
          final (tag, label) = tags[i];
          final isActive = validSection == tag;
          final color = isActive ? accent : muted;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectSection(tag, activeSymbol),
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
                    Icon(_ChartBottomSectionBar._iconFor(tag),
                        size: 15, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isActive ? theme.colorScheme.onSurface : muted,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    Widget buildSymbolBadge() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: accent.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isIndex ? Icons.show_chart : Icons.candlestick_chart,
              size: 13,
              color: accent,
            ),
            const SizedBox(width: 5),
            Text(
              activeSymbol.trim().toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    Widget header;
    if (isCompact) {
      header = DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(bottom: BorderSide(color: border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Exit full view',
                    iconSize: 20,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  buildSymbolBadge(),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Exit full view',
                    iconSize: 18,
                    icon: Icon(Icons.close_fullscreen, color: muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 40,
              child: buildTabs(),
            ),
          ],
        ),
      );
    } else {
      header = DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(bottom: BorderSide(color: border)),
        ),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Exit full view',
                iconSize: 20,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 4),
              buildSymbolBadge(),
              const SizedBox(width: 10),
              Container(
                height: 22,
                width: 1,
                color: border,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: buildTabs(),
              ),
              IconButton(
                tooltip: 'Exit full view',
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(Icons.close_fullscreen, color: muted),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(
              child: widget.bodyBuilder(context, validSection, activeSymbol),
            ),
          ],
        ),
      ),
    );
  }
}

