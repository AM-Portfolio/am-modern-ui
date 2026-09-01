import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../providers/equity_insider_provider.dart';
import 'package:am_market_sdk/market/api.dart';

import '../widgets/equity_insider_hero.dart';
import '../widgets/equity_insider_kpis.dart';
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
      backgroundColor: context.backgroundColor,
      body: _submittedSymbol == null
          ? _buildEmptySearch()
          : _buildDataView(_submittedSymbol!),
    );
  }

  Widget _buildEmptySearch() {
    final accentColor = context.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics_outlined, size: 48, color: accentColor),
              const SizedBox(height: 16),
              Text(
                'EQUITY INSIDER',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a stock symbol for fundamental analysis.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textTertiary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              _SearchField(controller: _controller, onSubmit: _search),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['TCS', 'RELIANCE', 'INFY', 'HDFCBANK', 'WIPRO']
                    .map(
                      (s) => ActionChip(
                        label: Text(s, style: TextStyle(color: context.textSecondary)),
                        backgroundColor: context.cardColor,
                        side: BorderSide(color: context.borderColor),
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
    final asyncData = ref.watch(fundamentalAnalysisProvider(symbol));
    final accentColor = context.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    return asyncData.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: accentColor, strokeWidth: 2),
      ),
      error: (err, _) => _ErrorPanel(
        message: 'Could not load "$symbol".\n\n$err',
        onBack: () => setState(() => _submittedSymbol = null),
      ),
      data: (data) {
        if (data == null) {
          return _ErrorPanel(
            message: 'No fundamental data for "$symbol".',
            onBack: () => setState(() => _submittedSymbol = null),
          );
        }
        return _FundamentalsBody(
          data: data,
          symbol: symbol,
          controller: _controller,
          onSearch: _search,
          onBack: () => setState(() => _submittedSymbol = null),
        );
      },
    );
  }
}

class _FundamentalsBody extends StatelessWidget {
  const _FundamentalsBody({
    required this.data,
    required this.symbol,
    required this.controller,
    required this.onSearch,
    required this.onBack,
  });

  final FundamentalRatiosResponse data;
  final String symbol;
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final accentColor = context.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // Top Navigation Bar
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back, color: accentColor),
            ),
            Expanded(
              child: Text(
                'EQUITY INSIDER',
                style: TextStyle(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: _SearchField(controller: controller, onSubmit: onSearch, compact: true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Modular Widgets
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EquityInsiderHero(data: data),
              const SizedBox(height: 20),
              EquityInsiderKpis(data: data),
              const SizedBox(height: 20),
              EquityInsiderFinancials(data: data),
              if (data.shareholding != null && data.shareholding!.isNotEmpty) ...[
                const SizedBox(height: 20),
                EquityInsiderShareholding(data: data),
              ],
              if (data.peers != null && data.peers!.isNotEmpty) ...[
                const SizedBox(height: 20),
                EquityInsiderPeers(peers: data.peers!, currentSymbol: data.symbol ?? symbol),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onSubmit,
    this.compact = false,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accentColor = context.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    return TextField(
      controller: controller,
      onSubmitted: (_) => onSubmit(),
      textCapitalization: TextCapitalization.characters,
      style: TextStyle(color: context.textPrimary, fontSize: compact ? 13 : 15),
      decoration: InputDecoration(
        hintText: compact ? 'Symbol…' : 'e.g. TCS',
        hintStyle: TextStyle(color: context.textTertiary),
        filled: true,
        fillColor: context.backgroundColor,
        prefixIcon: Icon(Icons.search, color: accentColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor.withOpacity(0.4)),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: compact ? 10 : 14, horizontal: 8),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onBack});
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 40),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textPrimary, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: onBack, child: const Text('Search again')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
