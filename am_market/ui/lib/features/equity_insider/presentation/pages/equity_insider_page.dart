import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/equity_insider_provider.dart';
import 'package:am_market_sdk/market/api.dart';

/// Equity Insider Page – Fundamental Analysis.
/// Starts with a centered search bar. Data loads only after the user submits a symbol.
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
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      color: const Color(0xFF0B1326),
      child: _submittedSymbol == null
          ? _buildEmptySearch(isMobile)
          : _buildDataView(isMobile, _submittedSymbol!),
    );
  }

  // ─── Empty / Search State ───────────────────────────────────────────────────

  Widget _buildEmptySearch(bool isMobile) {
    return Center(
      child: SizedBox(
        width: isMobile ? double.infinity : 600,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF171F33),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                ),
                child: const Icon(Icons.analytics_outlined, size: 36, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(height: 24),
              const Text(
                'EQUITY INSIDER',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDAE2FD),
                  fontFamily: 'Hanken Grotesk',
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a stock symbol to view fundamental analysis, valuation ratios & financial performance.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF87929A),
                  fontFamily: 'Inter',
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _SearchBar(controller: _controller, onSubmit: _search),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['TCS', 'RELIANCE', 'INFY', 'HDFCBANK', 'WIPRO']
                    .map((s) => _HintChip(
                          label: s,
                          onTap: () {
                            _controller.text = s;
                            _search();
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Data View ──────────────────────────────────────────────────────────────

  Widget _buildDataView(bool isMobile, String symbol) {
    final asyncData = ref.watch(fundamentalAnalysisProvider(symbol));

    return asyncData.when(
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 2),
            const SizedBox(height: 16),
            Text(
              'Loading data for $symbol…',
              style: const TextStyle(color: Color(0xFF87929A), fontFamily: 'Inter', fontSize: 13),
            ),
          ],
        ),
      ),
      error: (err, _) => _buildErrorState(
        'Could not load data for "$symbol".\n\n${err.toString()}',
      ),
      data: (data) {
        if (data == null) {
          return _buildErrorState('No fundamental data found for "$symbol".\nCheck that the symbol is correct.');
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(isMobile, symbol),
              const SizedBox(height: 24),
              _buildProfileSection(data),
              const SizedBox(height: 24),
              _buildValuationSection(isMobile, data),
              const SizedBox(height: 24),
              _buildFinancialsAndBalanceSheet(isMobile, data),
              const SizedBox(height: 24),
              _buildPeerComparison(data),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF171F33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF87171).withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFDAE2FD),
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() => _submittedSymbol = null),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF38BDF8)),
              label: const Text('Search again', style: TextStyle(color: Color(0xFF38BDF8), fontFamily: 'Inter')),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Page Header ────────────────────────────────────────────────────────────

  Widget _buildPageHeader(bool isMobile, String symbol) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EQUITY INSIDER',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFDAE2FD),
                  fontFamily: 'Hanken Grotesk',
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Fundamental Analysis & Valuation',
                style: TextStyle(fontSize: 13, color: Color(0xFF87929A), fontFamily: 'Inter'),
              ),
            ],
          ),
        ),
        SizedBox(
          width: isMobile ? 160 : 260,
          child: _SearchBar(controller: _controller, onSubmit: _search, compact: true),
        ),
      ],
    );
  }

  // ─── Section Builders ────────────────────────────────────────────────────────

  Widget _buildProfileSection(FundamentalRatiosResponse data) {
    return _SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data.symbol ?? _submittedSymbol ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDAE2FD),
                        fontFamily: 'Hanken Grotesk',
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (data.sector != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFF38BDF8)),
                        ),
                        child: Text(
                          data.sector!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF38BDF8),
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data.companyName ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFBDC8D1),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹ ${data.currentPrice?.toStringAsFixed(2) ?? "--"}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDAE2FD),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Current Market Price',
                style: TextStyle(fontSize: 12, color: Color(0xFF87929A), fontFamily: 'Inter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValuationSection(bool isMobile, FundamentalRatiosResponse data) {
    final isBank = data.nim != null || data.sector?.toLowerCase() == 'bank';
    
    final metrics = <Widget>[];
    if (isBank) {
      metrics.addAll([
        _MetricCard('P/E Ratio', data.peRatio?.toStringAsFixed(1) ?? '-', 'Sector PE: 8.9', false),
        _MetricCard('P/B Ratio', data.pbRatio?.toStringAsFixed(1) ?? '-', 'Sector PB: 1.3', true),
        _MetricCard('Net Interest Margin (NIM)', data.nim != null ? '${data.nim!.toStringAsFixed(2)}%' : '-', 'Sector: 2.6%', true),
        _MetricCard('Net NPA %', data.netNpa != null ? '${data.netNpa!.toStringAsFixed(2)}%' : '-', 'Sector: 0.4%', false),
        _MetricCard('CASA Ratio %', data.casa != null ? '${data.casa!.toStringAsFixed(1)}%' : '-', 'Sector: 39.0%', true),
      ]);
    } else {
      metrics.addAll([
        _MetricCard('P/E Ratio', data.peRatio?.toStringAsFixed(1) ?? '-', 'Sector PE: 22.1', false),
        _MetricCard('P/B Ratio', data.pbRatio?.toStringAsFixed(1) ?? '-', 'Sector PB: 3.1', true),
        _MetricCard('EV/EBITDA', data.priceToSales?.toStringAsFixed(1) ?? '-', 'Sector: 12.5', false),
        _MetricCard('ROE %', data.roe != null ? '${data.roe!.toStringAsFixed(1)}%' : '-', 'Sector: 15.2%', true),
        _MetricCard('ROCE %', data.roce != null ? '${data.roce!.toStringAsFixed(1)}%' : '-', 'Sector: 18.0%', true),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Valuation & Key Metrics'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isMobile ? 2 : 5,
          shrinkWrap: true,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          physics: const NeverScrollableScrollPhysics(),
          children: metrics,
        ),
      ],
    );
  }

  Widget _buildFinancialsAndBalanceSheet(bool isMobile, FundamentalRatiosResponse data) {
    if (isMobile) {
      return Column(
        children: [
          _buildFinancialPerformance(data),
          const SizedBox(height: 24),
          _buildBalanceSheetSummary(data),
          const SizedBox(height: 24),
          _buildShareholdingSection(data),
        ],
      );
    }
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildFinancialPerformance(data)),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildBalanceSheetSummary(data)),
          ],
        ),
        const SizedBox(height: 24),
        _buildShareholdingSection(data),
      ],
    );
  }

  Widget _buildFinancialPerformance(FundamentalRatiosResponse data) {
    final statements = data.incomeStatement ?? [];
    
    // Fallback if statement list is empty
    if (statements.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Financial Performance'),
          const SizedBox(height: 16),
          _SectionCard(
            child: Container(
              height: 150,
              alignment: Alignment.center,
              child: const Text('No Income Statement data available.', style: TextStyle(color: Color(0xFF87929A))),
            ),
          ),
        ],
      );
    }

    // Extract periods for header (up to 3 years)
    final periods = statements.map((e) => (e['period'] ?? '').toString()).take(3).toList();
    final headerCols = ['Metric', ...periods];

    // Helper to get value dynamically from statement entry lineItems or direct key
    String getValueStr(dynamic entry, String lineKey, String altKey) {
      final lineItems = entry['lineItems'] is Map ? entry['lineItems'] as Map : {};
      final val = lineItems[lineKey] ?? entry[altKey];
      if (val is num) return val.toStringAsFixed(1);
      return '-';
    }

    final rows = <List<String>>[];
    
    final isBank = data.nim != null || data.sector?.toLowerCase() == 'bank';
    if (isBank) {
      // Banking Income Statement Metrics
      rows.add(['Total Revenue', ...statements.map((e) => getValueStr(e, 'Total Revenue', 'totalRevenue')).take(3)]);
      rows.add(['Other Income', ...statements.map((e) => getValueStr(e, 'Other Income', 'otherIncome')).take(3)]);
      rows.add(['Total Expenses', ...statements.map((e) => getValueStr(e, 'Total Expenses', 'totalExpenses')).take(3)]);
      rows.add(['Profit Before Tax', ...statements.map((e) => getValueStr(e, 'Profit Before Tax', 'profitBeforeTax')).take(3)]);
      rows.add(['Profit After Tax (PAT)', ...statements.map((e) => getValueStr(e, 'Profit After Tax', 'profitAfterTax')).take(3)]);
    } else {
      // Corporate Income Statement Metrics
      rows.add(['Revenue / Sales', ...statements.map((e) => getValueStr(e, 'Revenue', 'revenue')).take(3)]);
      rows.add(['Other Income', ...statements.map((e) => getValueStr(e, 'Other Income', 'otherIncome')).take(3)]);
      rows.add(['Total Revenue', ...statements.map((e) => getValueStr(e, 'Total Revenue', 'totalRevenue')).take(3)]);
      rows.add(['Total Expenses', ...statements.map((e) => getValueStr(e, 'Total Expenses', 'totalExpenses')).take(3)]);
      rows.add(['Profit After Tax (PAT)', ...statements.map((e) => getValueStr(e, 'Profit After Tax', 'profitAfterTax')).take(3)]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Financial Performance (Yearly in ₹ Crore)'),
        const SizedBox(height: 16),
        _SectionCard(
          child: Column(
            children: [
              _buildTableRow(headerCols, isHeader: true),
              ...rows.map((row) => _buildTableRow(row)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSheetSummary(FundamentalRatiosResponse data) {
    final bs = data.balanceSheet ?? [];
    if (bs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Balance Sheet Summary'),
          const SizedBox(height: 16),
          _SectionCard(
            child: Container(
              height: 150,
              alignment: Alignment.center,
              child: const Text('No Balance Sheet data available.', style: TextStyle(color: Color(0xFF87929A))),
            ),
          ),
        ],
      );
    }

    final periods = bs.map((e) => (e['period'] ?? '').toString()).take(2).toList();
    final headerCols = ['Balance Sheet Item', ...periods];

    String getValueStr(dynamic entry, String lineKey, String altKey) {
      final lineItems = entry['lineItems'] is Map ? entry['lineItems'] as Map : {};
      final val = lineItems[lineKey] ?? entry[altKey];
      if (val is num) {
        if (val > 10000) return '₹${(val / 10000).toStringAsFixed(1)}L Cr'; // Format larger values
        return '₹${val.toStringAsFixed(1)} Cr';
      }
      return '-';
    }

    final rows = <List<String>>[];
    final isBank = data.nim != null || data.sector?.toLowerCase() == 'bank';
    if (isBank) {
      rows.add(['Total Assets', ...bs.map((e) => getValueStr(e, 'Total Assets', 'totalAssets')).take(2)]);
      rows.add(['Equity Capital', ...bs.map((e) => getValueStr(e, 'Equity Capital', 'equityCapital')).take(2)]);
      rows.add(['Liabilities', ...bs.map((e) => getValueStr(e, 'Liabilities', 'totalLiabilities')).take(2)]);
    } else {
      rows.add(['Total Assets', ...bs.map((e) => getValueStr(e, 'Total Assets', 'totalAssets')).take(2)]);
      rows.add(['Current Assets', ...bs.map((e) => getValueStr(e, 'Current Assets', 'currentAssets')).take(2)]);
      rows.add(['Non-Current Assets', ...bs.map((e) => getValueStr(e, 'Non-Current Assets', 'nonCurrentAssets')).take(2)]);
      rows.add(['Current Liabilities', ...bs.map((e) => getValueStr(e, 'Current Liabilities', 'currentLiabilities')).take(2)]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Balance Sheet Summary'),
        const SizedBox(height: 16),
        _SectionCard(
          child: Column(
            children: [
              _buildTableRow(headerCols, isHeader: true),
              ...rows.map((row) => _buildTableRow(row)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareholdingSection(FundamentalRatiosResponse data) {
    final shList = data.shareholding ?? [];
    if (shList.isEmpty) return const SizedBox.shrink();

    // Get latest quarter
    final latest = shList.first;
    final period = latest['period'] ?? 'Recent';
    
    double val(String key) {
      final v = latest[key];
      return v is num ? v.toDouble() : 0.0;
    }

    final promoter = val('promotersPercent');
    final fii = val('fiiPercent');
    final dii = val('diiPercent');
    final mf = val('mutualFundsPercent');
    final retail = val('retailAndOtherPercent');

    Widget buildBarRow(String label, double pct, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFFBDC8D1), fontSize: 13, fontFamily: 'Inter')),
                Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono')),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100.0,
                backgroundColor: const Color(0xFF1E293B),
                color: color,
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Shareholding Pattern ($period)'),
        const SizedBox(height: 16),
        _SectionCard(
          child: Column(
            children: [
              buildBarRow('Promoters', promoter, const Color(0xFF38BDF8)),
              buildBarRow('Foreign Institutional Investors (FII)', fii, const Color(0xFFF43F5E)),
              buildBarRow('Domestic Institutional Investors (DII)', dii, const Color(0xFF10B981)),
              buildBarRow('Mutual Funds', mf, const Color(0xFFF59E0B)),
              buildBarRow('Retail & Public', retail, const Color(0xFF64748B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeerComparison(FundamentalRatiosResponse data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Peer Comparison'),
        const SizedBox(height: 16),
        _SectionCard(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600),
              child: Column(
                children: [
                  _buildTableRow(['Company', 'Price', 'P/E', 'P/B', 'ROE', 'ROCE'], isHeader: true),
                  if (data.peers == null || data.peers!.isEmpty)
                    _buildTableRow(['-', '-', '-', '-', '-', '-'])
                  else
                    ...data.peers!.map((peer) {
                      return _buildTableRow([
                        peer.symbol ?? peer.companyName ?? '-',
                        peer.currentPrice != null ? '₹${peer.currentPrice!.toStringAsFixed(1)}' : '-',
                        peer.pe?.toStringAsFixed(1) ?? '-',
                        peer.pb?.toStringAsFixed(1) ?? '-',
                        peer.roe != null ? '${peer.roe!.toStringAsFixed(1)}%' : '-',
                        peer.roce != null ? '${peer.roce!.toStringAsFixed(1)}%' : '-',
                      ], highlight: _submittedSymbol == peer.symbol);
                    }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(List<String> columns, {bool isHeader = false, bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isHeader ? const Color(0xFF3E484F) : const Color(0xFF283044),
          ),
        ),
        color: highlight ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.transparent,
      ),
      child: Row(
        children: columns.map((col) {
          final isFirst = col == columns.first;
          return Expanded(
            flex: isFirst ? 2 : 1,
            child: Text(
              col,
              textAlign: isFirst ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                fontFamily: isHeader ? 'Hanken Grotesk' : (isFirst ? 'Inter' : 'JetBrains Mono'),
                fontWeight: isHeader || highlight ? FontWeight.bold : FontWeight.normal,
                color: isHeader
                    ? const Color(0xFF87929A)
                    : (highlight ? const Color(0xFF38BDF8) : const Color(0xFFDAE2FD)),
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Reusable Search Bar Widget ────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool compact;

  const _SearchBar({required this.controller, required this.onSubmit, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171F33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
        boxShadow: compact
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: TextField(
        controller: controller,
        onSubmitted: (_) => onSubmit(),
        textCapitalization: TextCapitalization.characters,
        style: TextStyle(
          color: const Color(0xFFDAE2FD),
          fontFamily: 'JetBrains Mono',
          fontSize: compact ? 13 : 16,
        ),
        decoration: InputDecoration(
          hintText: compact ? 'Search symbol…' : 'Enter symbol, e.g. TCS',
          hintStyle: TextStyle(
            color: const Color(0xFF87929A),
            fontFamily: 'Inter',
            fontSize: compact ? 13 : 15,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8)),
          suffixIcon: compact
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Color(0xFF38BDF8)),
                  onPressed: onSubmit,
                  tooltip: 'Search',
                ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: compact ? 12 : 18,
            horizontal: 8,
          ),
        ),
      ),
    );
  }
}

// ─── Hint Chip ─────────────────────────────────────────────────────────────────

class _HintChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HintChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF171F33),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF3E484F)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFBDC8D1),
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFDAE2FD),
        fontFamily: 'Hanken Grotesk',
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF171F33),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3E484F)),
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String benchmark;
  final bool isPositive;

  const _MetricCard(this.title, this.value, this.benchmark, this.isPositive);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171F33),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3E484F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 14, color: Color(0xFF87929A), fontFamily: 'Inter')),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDAE2FD),
              fontFamily: 'JetBrains Mono',
            ),
          ),
          Row(
            children: [
              Icon(
                isPositive ? Icons.check_circle : Icons.warning,
                size: 12,
                color: isPositive ? const Color(0xFF4DE082) : const Color(0xFFF87171),
              ),
              const SizedBox(width: 4),
              Text(
                benchmark,
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive ? const Color(0xFF4DE082) : const Color(0xFFF87171),
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
