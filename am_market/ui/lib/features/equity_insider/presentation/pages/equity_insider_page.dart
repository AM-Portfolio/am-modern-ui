import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_news_ui/am_news_ui.dart';

import '../../providers/equity_insider_provider.dart';
import '../widgets/equity_insider_hero.dart';
import '../widgets/equity_insider_kpis.dart';
import '../widgets/equity_insider_chart.dart';
import '../widgets/equity_insider_financials.dart';
import '../widgets/equity_insider_shareholding.dart';
import '../widgets/equity_insider_peers.dart';
import '../widgets/equity_insider_section_nav_bar.dart';

/// Equity Insider – Fundamental Analysis.
class EquityInsiderPage extends ConsumerStatefulWidget {
  const EquityInsiderPage({
    super.key,
    this.initialSymbol,
    this.showPeers = true,
  });

  /// When set (e.g. paper desk watchlist), loads this symbol instead of empty search.
  final String? initialSymbol;

  /// Paper desk hides Peers; Market Equity Insider keeps it (default true).
  final bool showPeers;

  @override
  ConsumerState<EquityInsiderPage> createState() => EquityInsiderPageState();
}

class EquityInsiderPageState extends ConsumerState<EquityInsiderPage> {
  static const _fallbackSymbols = [
    'RELIANCE',
    'TCS',
    'HDFCBANK',
    'ICICIBANK',
    'INFY',
    'BHARTIARTL',
  ];

  /// Soft-landing: keep/re-apply a useful default instead of an empty screen.
  void resetToLanding() {
    _symbolHistory.clear();
    ensureDefaultSymbol();
  }

  final List<String> _symbolHistory = [];
  String? _submittedSymbol;
  bool _defaultResolveScheduled = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSymbol?.trim().toUpperCase();
    if (initial != null && initial.isNotEmpty) {
      _submittedSymbol = initial;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(equityInsiderActiveSymbolProvider);
      if (pending != null && pending.isNotEmpty) {
        navigateToSymbol(pending);
        return;
      }
      if (_submittedSymbol == null) {
        ensureDefaultSymbol();
      }
    });
  }

  /// Resolves recent → smart recommendations → RELIANCE fallback.
  Future<void> ensureDefaultSymbol() async {
    if (_submittedSymbol != null && _submittedSymbol!.isNotEmpty) return;
    if (_defaultResolveScheduled) return;
    _defaultResolveScheduled = true;
    try {
      final recent = ref.read(recentlyViewedStocksProvider);
      if (recent.isNotEmpty) {
        navigateToSymbol(recent.first);
        return;
      }
      final pending = ref.read(equityInsiderActiveSymbolProvider);
      if (pending != null && pending.isNotEmpty) {
        navigateToSymbol(pending);
        return;
      }
      try {
        final recs = await ref.read(dynamicStockRecommendationsProvider.future);
        if (!mounted) return;
        if (recs.isNotEmpty) {
          navigateToSymbol(recs.first);
          return;
        }
      } catch (_) {}
      if (!mounted) return;
      navigateToSymbol(_fallbackSymbols.first);
    } finally {
      _defaultResolveScheduled = false;
    }
  }

  @override
  void didUpdateWidget(covariant EquityInsiderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialSymbol?.trim().toUpperCase();
    final prev = oldWidget.initialSymbol?.trim().toUpperCase();
    if (next != null && next.isNotEmpty && next != prev && next != _submittedSymbol) {
      navigateToSymbol(next);
    }
  }

  void navigateToSymbol(String newSymbol) {
    final text = newSymbol.trim().toUpperCase();
    if (text.isEmpty) return;

    if (_submittedSymbol != null && _submittedSymbol != text) {
      _symbolHistory.add(_submittedSymbol!);
    }

    setState(() => _submittedSymbol = text);
    ref.read(equityInsiderActiveSymbolProvider.notifier).state = text;
  }

  void _handleBack() {
    if (_symbolHistory.isNotEmpty) {
      final prevSymbol = _symbolHistory.removeLast();
      setState(() => _submittedSymbol = prevSymbol);
      ref.read(equityInsiderActiveSymbolProvider.notifier).state = prevSymbol;
    } else {
      setState(() => _submittedSymbol = null);
      ref.read(equityInsiderActiveSymbolProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(equityInsiderActiveSymbolProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      if (next == _submittedSymbol) return;
      navigateToSymbol(next);
    });

    final marketCyan = ModuleColors.market;
    final scaffoldBg = context.colors.scaffoldBackground;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scaffoldBg,
              Color.alphaBlend(marketCyan.withValues(alpha: 0.05), scaffoldBg),
              context.colors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: _submittedSymbol == null
              ? const Center(child: CircularProgressIndicator())
              : _buildDataView(_submittedSymbol!),
        ),
      ),
    );
  }

  Widget _buildDataView(String symbol) {
    return _FundamentalsBody(
      symbol: symbol,
      onSelectSymbol: navigateToSymbol,
      onBack: _symbolHistory.isNotEmpty ? _handleBack : null,
      showPeers: widget.showPeers,
    );
  }
}

class _FundamentalsBody extends ConsumerStatefulWidget {
  const _FundamentalsBody({
    required this.symbol,
    required this.onSelectSymbol,
    this.onBack,
    this.showPeers = true,
  });

  final String symbol;
  final ValueChanged<String> onSelectSymbol;
  final VoidCallback? onBack;
  final bool showPeers;

  @override
  ConsumerState<_FundamentalsBody> createState() => _FundamentalsBodyState();
}

class _FundamentalsBodyState extends ConsumerState<_FundamentalsBody> {
  static const double _stickyHeroExtentDesktop = 120;
  /// Compact mockup sticky bar (~logo + name/chips + LTP row).
  static const double _stickyHeroExtentMobile = 92;
  static const double _stickyNavExtent = 44;

  final ScrollController _scrollController = ScrollController();
  late final List<GlobalKey> _sectionKeys =
      List.generate(widget.showPeers ? 6 : 5, (_) => GlobalKey());
  int _activeIndex = 0;
  bool _isManualScrolling = false;

  int get _newsKeyIndex => _sectionKeys.length - 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentlyViewedStocksProvider.notifier).recordView(widget.symbol);
    });
  }

  @override
  void didUpdateWidget(covariant _FundamentalsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.symbol != oldWidget.symbol) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(recentlyViewedStocksProvider.notifier).recordView(widget.symbol);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isManualScrolling) return;

    final width = MediaQuery.sizeOf(context).width;
    final heroExtent =
        width < 800 ? _stickyHeroExtentMobile : _stickyHeroExtentDesktop;
    // Activate when a section top crosses under the pinned hero + nav.
    final threshold = heroExtent + _stickyNavExtent + 180;

    for (int i = _sectionKeys.length - 1; i >= 0; i--) {
      final key = _sectionKeys[i];
      if (key.currentContext != null) {
        final renderBox = key.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero).dy;
        if (position < threshold) {
          if (_activeIndex != i) {
            setState(() => _activeIndex = i);
          }
          break;
        }
      }
    }
  }

  void _scrollToSection(int index) async {
    final key = _sectionKeys[index];
    if (key.currentContext != null) {
      setState(() {
        _activeIndex = index;
        _isManualScrolling = true;
      });
      await Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        // Leave room under the pinned section nav.
        alignment: 0.08,
      );
      if (mounted) {
        setState(() => _isManualScrolling = false);
      } else {
        _isManualScrolling = false;
      }
    }
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required Widget child,
    GlobalKey? sectionKey,
    bool isMobile = false,
  }) {
    return Container(
      key: sectionKey,
      child: GlassCard(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            final stickyHeroExtent =
                isMobile ? _stickyHeroExtentMobile : _stickyHeroExtentDesktop;
            final bottomPad = isMobile
                ? PlatformConstants.globalBottomNavReserve(context) + 32
                : 32.0;

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySectionNavDelegate(
                    extent: stickyHeroExtent,
                    backgroundColor: context.colors.scaffoldBackground,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 12 : 16,
                        isMobile ? 4 : 16,
                        isMobile ? 12 : 16,
                        isMobile ? 4 : 8,
                      ),
                      child: EquityInsiderHeroBar(
                        symbol: widget.symbol,
                        onBack: widget.onBack,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                    ),
                    child: EquityInsiderHeroDescription(
                      symbol: widget.symbol,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySectionNavDelegate(
                    extent: _stickyNavExtent,
                    backgroundColor: context.colors.scaffoldBackground,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                      ),
                      child: EquityInsiderSectionNavBar(
                        activeIndex: _activeIndex,
                        onTabSelected: _scrollToSection,
                        isMobile: isMobile,
                        showPeers: widget.showPeers,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 12 : 16,
                      isMobile ? 12 : 14,
                      isMobile ? 12 : 16,
                      bottomPad,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Row 1: Valuation & Key Metrics (Left 60%) + Price Performance & Chart (Right 40%)
                        // Overview tab scrolls to KPIs (sectionKeys[0]).
                        if (isMobile) ...[
                          _buildSectionCard(
                            sectionKey: _sectionKeys[0],
                            context: context,
                            isMobile: isMobile,
                            child: EquityInsiderKpis(symbol: widget.symbol),
                          ),
                          const SizedBox(height: 12),
                          _buildSectionCard(
                            sectionKey: _sectionKeys[1],
                            context: context,
                            isMobile: isMobile,
                            child: EquityInsiderChart(symbol: widget.symbol),
                          ),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 60,
                                child: _buildSectionCard(
                                  sectionKey: _sectionKeys[0],
                                  context: context,
                                  isMobile: false,
                                  child: EquityInsiderKpis(symbol: widget.symbol),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 40,
                                child: _buildSectionCard(
                                  sectionKey: _sectionKeys[1],
                                  context: context,
                                  isMobile: false,
                                  child: EquityInsiderChart(symbol: widget.symbol),
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: isMobile ? 12 : 14),

                        // Row 2: Financial Performance (Left 60%) + Shareholding Pattern (Right 40%)
                        if (isMobile) ...[
                          _buildSectionCard(
                            sectionKey: _sectionKeys[2],
                            context: context,
                            isMobile: isMobile,
                            child: EquityInsiderFinancials(symbol: widget.symbol),
                          ),
                          SizedBox(height: isMobile ? 10 : 14),
                          _buildSectionCard(
                            sectionKey: _sectionKeys[3],
                            context: context,
                            isMobile: isMobile,
                            child: EquityInsiderShareholding(symbol: widget.symbol),
                          ),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 60,
                                child: _buildSectionCard(
                                  sectionKey: _sectionKeys[2],
                                  context: context,
                                  isMobile: false,
                                  child: EquityInsiderFinancials(symbol: widget.symbol),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 40,
                                child: _buildSectionCard(
                                  sectionKey: _sectionKeys[3],
                                  context: context,
                                  isMobile: false,
                                  child: EquityInsiderShareholding(symbol: widget.symbol),
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: isMobile ? 10 : 14),

                        // Row 3: Full-width Peer Comparison Section
                        if (widget.showPeers) ...[
                          _buildSectionCard(
                            sectionKey: _sectionKeys[4],
                            context: context,
                            isMobile: isMobile,
                            child: EquityInsiderPeers(
                              symbol: widget.symbol,
                              onPeerSelected: widget.onSelectSymbol,
                            ),
                          ),
                          SizedBox(height: isMobile ? 10 : 14),
                        ],
                        _buildSectionCard(
                          sectionKey: _sectionKeys[_newsKeyIndex],
                          context: context,
                          isMobile: isMobile,
                          child: SymbolNewsSection(
                            symbol: widget.symbol,
                            surface: NewsUiSurface.equityInsider,
                            embedInScroll: true,
                            compact: isMobile,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
    );
  }
}

class _StickySectionNavDelegate extends SliverPersistentHeaderDelegate {
  _StickySectionNavDelegate({
    required this.child,
    required this.backgroundColor,
    required this.extent,
  });

  final Widget child;
  final Color backgroundColor;
  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: backgroundColor,
      elevation: overlapsContent || shrinkOffset > 0 ? 1.5 : 0,
      shadowColor: context.colors.textPrimary.withValues(alpha: 0.26),
      child: SizedBox(
        height: extent,
        width: double.infinity,
        child: Align(
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySectionNavDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.extent != extent;
  }
}

