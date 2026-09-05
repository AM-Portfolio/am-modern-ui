import 'dart:ui';
import '../../../../core/styles/market_theme_extension.dart';
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

/// Equity Insider – Fundamental Analysis.
class EquityInsiderPage extends ConsumerStatefulWidget {
  const EquityInsiderPage({super.key});

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

  void _navigateToSymbol(String newSymbol) {
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
    _navigateToSymbol(text);
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colors.scaffoldBackground,
              context.marketTheme.background,
              context.marketTheme.surface,
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
    final recent = ref.watch(recentlyViewedStocksProvider);
    final accentColor = context.colors.actionPrimaryBg;
    final surfaceColor = context.colors.cardSurface;
    final borderColor = context.colors.border;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surfaceColor.withValues(alpha: 0.7),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.analytics_outlined,
                  size: 38,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'EQUITY INSIDER',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a stock symbol for deep fundamental analysis, valuation & peers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              SmartSearchAnchor(
                controller: _controller,
                animatedHints: _typewriterHints,
                recentSearches: recent,
                searchHandler: (q) => _sdkService.securityApi.search(
                  q,
                  smartRecommendations: true,
                  category: 'STOCKS',
                  limit: 8,
                ),
                onSelected: (symbol) {
                  _navigateToSymbol(symbol);
                },
                onSubmit: _search,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['TCS', 'RELIANCE', 'INFY', 'HDFCBANK', 'WIPRO', 'RAILTEL']
                    .map(
                      (s) => ActionChip(
                        label: Text(
                          s,
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: context.colors.cardSurface,
                        side: BorderSide(color: context.colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onPressed: () {
                          _navigateToSymbol(s);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataView(String symbol) {
    return _FundamentalsBody(
      symbol: symbol,
      controller: _controller,
      sdkService: _sdkService,
      onSearch: _search,
      onSelectSymbol: _navigateToSymbol,
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
      ref.read(recentlyViewedStocksProvider.notifier).recordView(widget.symbol);
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
    required GlobalKey sectionKey,
    bool isMobile = false,
  }) {
    return Container(
      key: sectionKey,
      padding: EdgeInsets.all(isMobile ? 14 : 22),
      decoration: BoxDecoration(
        color: context.colors.cardSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final recent = ref.watch(recentlyViewedStocksProvider);

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 24,
                  isMobile ? 12 : 20,
                  isMobile ? 12 : 24,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Unified Hero & Section Navbar Card
                    _buildSectionCard(
                      sectionKey: _sectionKeys[0],
                      context: context,
                      isMobile: isMobile,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EquityInsiderHero(
                            symbol: widget.symbol,
                            onSearchTap: _openSearchOverlay,
                          ),
                          const SizedBox(height: 14),
                          EquityInsiderSectionNavBar(
                            activeIndex: _activeIndex,
                            onTabSelected: _scrollToSection,
                            isMobile: isMobile,
                          ),
                          const SizedBox(height: 20),
                          EquityInsiderKpis(symbol: widget.symbol),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionCard(
                      sectionKey: _sectionKeys[1],
                      context: context,
                      isMobile: isMobile,
                      child: EquityInsiderChart(symbol: widget.symbol),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionCard(
                      sectionKey: _sectionKeys[2],
                      context: context,
                      isMobile: isMobile,
                      child: EquityInsiderFinancials(symbol: widget.symbol),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionCard(
                      sectionKey: _sectionKeys[3],
                      context: context,
                      isMobile: isMobile,
                      child: EquityInsiderShareholding(symbol: widget.symbol),
                    ),
                    const SizedBox(height: 20),

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

