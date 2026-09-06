import '../../../../core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';

import '../widgets/equity_insider_hero.dart';
import '../widgets/equity_insider_kpis.dart';
import '../widgets/equity_insider_chart.dart';
import '../widgets/equity_insider_financials.dart';
import '../widgets/equity_insider_shareholding.dart';
import '../widgets/equity_insider_peers.dart';

/// Equity Insider – Fundamental Analysis.
class EquityInsiderPage extends ConsumerStatefulWidget {
  const EquityInsiderPage({super.key});

  @override
  ConsumerState<EquityInsiderPage> createState() => _EquityInsiderPageState();
}

class _EquityInsiderPageState extends ConsumerState<EquityInsiderPage> {
  final TextEditingController _controller = TextEditingController();
  final MarketDataSdkService _sdkService = MarketDataSdkService();
  String? _submittedSymbol;

  void _search() {
    final text = _controller.text.trim().toUpperCase();
    if (text.isEmpty) return;
    setState(() => _submittedSymbol = text);
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
    final chartBlue = context.marketTheme.chartBlue;
    final surfaceColor = context.marketTheme.surface;
    final borderColor = context.marketTheme.border;

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
                      color: chartBlue.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.analytics_outlined,
                  size: 38,
                  color: chartBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'EQUITY INSIDER',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a stock symbol for deep fundamental analysis, valuation & peers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              SmartSearchAnchor(
                controller: _controller,
                searchHandler: (q) => _sdkService.securityApi.search(
                  q,
                  smartRecommendations: true,
                  category: 'STOCKS',
                  limit: 8,
                ),
                onSelected: (symbol) {
                  _controller.text = symbol;
                  setState(() => _submittedSymbol = symbol);
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
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: context.cardColor,
                        side: BorderSide(color: context.borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onPressed: () {
                          _controller.text = s;
                          _search();
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
      onSelectSymbol: (newSymbol) {
        _controller.text = newSymbol;
        setState(() => _submittedSymbol = newSymbol);
      },
      onBack: () => setState(() => _submittedSymbol = null),
    );
  }
}

class _FundamentalsBody extends ConsumerWidget {
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

  Widget _buildSectionCard({
    required BuildContext context,
    required Widget child,
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 22),
      decoration: BoxDecoration(
        color: context.marketTheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.marketTheme.border, width: 1),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final chartBlue = context.marketTheme.chartBlue;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        isMobile ? 12 : 20,
        isMobile ? 12 : 24,
        40,
      ),
      children: [
        // Top Navigation Header Bar matching Market Analysis style
        if (isMobile) ...[
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back, color: chartBlue),
                tooltip: 'Back to Search',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'EQUITY INSIDER',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SmartSearchAnchor(
            controller: controller,
            compact: true,
            searchHandler: (q) => sdkService.securityApi.search(
              q,
              smartRecommendations: true,
              category: 'STOCKS',
              limit: 8,
            ),
            onSelected: onSelectSymbol,
            onSubmit: onSearch,
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: Icon(Icons.arrow_back, color: chartBlue, size: 24),
                    tooltip: 'Back to Search',
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EQUITY INSIDER',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Deep fundamental analysis, valuation & peers',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 260,
                child: SmartSearchAnchor(
                  controller: controller,
                  compact: true,
                  searchHandler: (q) => sdkService.securityApi.search(
                    q,
                    smartRecommendations: true,
                    category: 'STOCKS',
                    limit: 8,
                  ),
                  onSelected: onSelectSymbol,
                  onSubmit: onSearch,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),

        // 1. Hero Summary & KPI Metrics Card
        _buildSectionCard(
          context: context,
          isMobile: isMobile,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EquityInsiderHero(symbol: symbol),
              const SizedBox(height: 20),
              EquityInsiderKpis(symbol: symbol),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Price Performance & Dynamic Chart Card
        _buildSectionCard(
          context: context,
          isMobile: isMobile,
          child: EquityInsiderChart(symbol: symbol),
        ),
        const SizedBox(height: 20),

        // 3. Financial Statements Card (Income Statement, Balance Sheet, Cash Flow)
        _buildSectionCard(
          context: context,
          isMobile: isMobile,
          child: EquityInsiderFinancials(symbol: symbol),
        ),
        const SizedBox(height: 20),

        // 4. Shareholding Pattern Card
        _buildSectionCard(
          context: context,
          isMobile: isMobile,
          child: EquityInsiderShareholding(symbol: symbol),
        ),
        const SizedBox(height: 20),

        // 5. Peer Valuation & Metric Comparison Card
        _buildSectionCard(
          context: context,
          isMobile: isMobile,
          child: EquityInsiderPeers(symbol: symbol),
        ),
      ],
    );
  }
}
