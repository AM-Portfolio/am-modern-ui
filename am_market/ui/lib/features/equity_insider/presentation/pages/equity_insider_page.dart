import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';

import '../../providers/equity_insider_provider.dart';
import '../widgets/equity_insider_hero.dart';
import '../widgets/equity_insider_kpis.dart';
import '../widgets/equity_insider_chart.dart';
import '../widgets/equity_insider_financials.dart';
import '../widgets/equity_insider_shareholding.dart';
import '../widgets/equity_insider_peers.dart';
import '../widgets/equity_insider_section_nav_bar.dart';
import '../widgets/equity_insider_empty_view.dart';

/// Equity Insider – Fundamental Analysis.
class EquityInsiderPage extends ConsumerStatefulWidget {
  const EquityInsiderPage({super.key, this.initialSymbol});

  /// When set (e.g. paper desk watchlist), loads this symbol instead of empty search.
  final String? initialSymbol;

  @override
  ConsumerState<EquityInsiderPage> createState() => EquityInsiderPageState();
}

class EquityInsiderPageState extends ConsumerState<EquityInsiderPage> {
  final TextEditingController _controller = TextEditingController();
  final MarketDataSdkService _sdkService = MarketDataSdkService();

  void resetToLanding() {
    setState(() {
      _submittedSymbol = null;
      _controller.clear();
      _symbolHistory.clear();
    });
  }
  final List<String> _symbolHistory = [];
  String? _submittedSymbol;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSymbol?.trim().toUpperCase();
    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
      _submittedSymbol = initial;
    }
  }

  @override
  void didUpdateWidget(covariant EquityInsiderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialSymbol?.trim().toUpperCase();
    final prev = oldWidget.initialSymbol?.trim().toUpperCase();
    if (next != null && next.isNotEmpty && next != prev && next != _submittedSymbol) {
      _navigateToSymbol(next);
    }
  }

  static const List<String> _typewriterHints = [
    'HDFC',
    'TCS',
    'RELIANCE',
    'INFY',
    'ICICIBANK',
    'WIPRO',
    'TATAMOTORS',
    'BHARTIARTL',
  ];

  void navigateToSymbol(String newSymbol) {
    final text = newSymbol.trim().toUpperCase();
    if (text.isEmpty) return;

    if (_submittedSymbol != null && _submittedSymbol != text) {
      _symbolHistory.add(_submittedSymbol!);
    }

    _controller.text = text;
    setState(() => _submittedSymbol = text);
  }

  void _search() {
    final text = _controller.text.trim().toUpperCase();
    if (text.isEmpty) return;
    navigateToSymbol(text);
  }

  void _handleBack() {
    if (_symbolHistory.isNotEmpty) {
      final prevSymbol = _symbolHistory.removeLast();
      _controller.text = prevSymbol;
      setState(() => _submittedSymbol = prevSymbol);
    } else {
      setState(() => _submittedSymbol = null);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: _submittedSymbol == null
              ? _buildEmptySearch()
              : _buildDataView(_submittedSymbol!),
        ),
      ),
    );
  }

  Widget _buildEmptySearch() {
    return EquityInsiderEmptyView(
      controller: _controller,
      sdkService: _sdkService,
      typewriterHints: _typewriterHints,
      onSelectSymbol: navigateToSymbol,
      onSearch: _search,
    );
  }

  Widget _buildDataView(String symbol) {
    return _FundamentalsBody(
      symbol: symbol,
      controller: _controller,
      sdkService: _sdkService,
      onSearch: _search,
      onSelectSymbol: navigateToSymbol,
      onBack: _handleBack,
    );
  }
}

class _FundamentalsBody extends ConsumerStatefulWidget {
  const _FundamentalsBody({
    required this.symbol,
    required this.controller,
    required this.sdkService,
    required this.onSearch,
    required this.onSelectSymbol,
    required this.onBack,
  });

  final String symbol;
  final TextEditingController controller;
  final MarketDataSdkService sdkService;
  final VoidCallback onSearch;
  final ValueChanged<String> onSelectSymbol;
  final VoidCallback onBack;

  @override
  ConsumerState<_FundamentalsBody> createState() => _FundamentalsBodyState();
}

class _FundamentalsBodyState extends ConsumerState<_FundamentalsBody> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _sectionKeys = List.generate(5, (_) => GlobalKey());
  int _activeIndex = 0;
  bool _isManualScrolling = false;
  bool _isSearchOverlayOpen = false;

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

    for (int i = _sectionKeys.length - 1; i >= 0; i--) {
      final key = _sectionKeys[i];
      if (key.currentContext != null) {
        final renderBox = key.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero).dy;
        if (position < 300) {
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
        alignment: 0.05,
      );
      _isManualScrolling = false;
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
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: child,
      ),
    );
  }

  void _openSearchOverlay() {
    setState(() {
      _isSearchOverlayOpen = true;
    });
  }

  void _closeSearchOverlay() {
    setState(() {
      _isSearchOverlayOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final recent = ref.watch(recentlyViewedStocksProvider);

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 12 : 16,
                      isMobile ? 12 : 16,
                      isMobile ? 12 : 16,
                      32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section 0: Header (Company Hero + Section Nav Bar without card wrapper)
                        Column(
                          key: _sectionKeys[0],
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EquityInsiderHero(
                              symbol: widget.symbol,
                              onSearchTap: _openSearchOverlay,
                            ),
                            const SizedBox(height: 24),
                            EquityInsiderSectionNavBar(
                              activeIndex: _activeIndex,
                              onTabSelected: _scrollToSection,
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 1: Valuation & Key Metrics (Left 60%) + Price Performance & Chart (Right 40%)
                        if (isMobile) ...[
                          _buildSectionCard(
                            context: context,
                            isMobile: isMobile,
                            child: EquityInsiderKpis(symbol: widget.symbol),
                          ),
                          const SizedBox(height: 14),
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
                        const SizedBox(height: 14),

                        // Row 2: Financial Performance (Left 60%) + Shareholding Pattern (Right 40%)
                        if (isMobile) ...[
                          _buildSectionCard(
                            sectionKey: _sectionKeys[2],
                            context: context,
                            isMobile: isMobile,
                            child: EquityInsiderFinancials(symbol: widget.symbol),
                          ),
                          const SizedBox(height: 14),
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
                        const SizedBox(height: 14),

                        // Row 3: Full-width Peer Comparison Section
                        _buildSectionCard(
                          sectionKey: _sectionKeys[4],
                          context: context,
                          isMobile: isMobile,
                          child: EquityInsiderPeers(
                            symbol: widget.symbol,
                            onPeerSelected: widget.onSelectSymbol,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Full Screen Search Overlay with Soft Backdrop Blur
        if (_isSearchOverlayOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeSearchOverlay,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.only(
                    top: isMobile ? 40 : 80,
                    left: 20,
                    right: 20,
                  ),
                  child: GestureDetector(
                    onTap: () {}, // Prevent backdrop tap from dismissing when tapping dialog
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: _closeSearchOverlay,
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: context.colors.textSecondary,
                                  size: 24,
                                ),
                                tooltip: 'Close Search',
                              ),
                            ],
                          ),
                          SmartSearchAnchor(
                            controller: widget.controller,
                            recentSearches: recent,
                            onRemoveRecent: (sym) {
                              ref.read(recentlyViewedStocksProvider.notifier).removeView(sym);
                            },
                            onClearRecent: () {
                              ref.read(recentlyViewedStocksProvider.notifier).clear();
                            },
                            accentColor: ModuleColors.market,
                            searchHandler: (q) => widget.sdkService.securityApi.search(
                              q,
                              smartRecommendations: true,
                              category: 'STOCKS',
                              limit: 8,
                            ),
                            onSelected: (sym) {
                              _closeSearchOverlay();
                              widget.onSelectSymbol(sym);
                            },
                            onSubmit: () {
                              _closeSearchOverlay();
                              widget.onSearch();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

