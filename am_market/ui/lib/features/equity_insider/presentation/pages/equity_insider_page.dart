import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/equity_insider_provider.dart';
import 'package:am_market_client/api.dart';

/// Equity Insider Page - Fundamental Analysis
/// Designed based on the Quantum Terminal design system (Dark Mode First).
class EquityInsiderPage extends ConsumerWidget {
  const EquityInsiderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final symbol = 'RELIANCE'; // We can make this dynamic later
    final asyncData = ref.watch(fundamentalAnalysisProvider(symbol));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326), // Quantum Terminal Surface
      body: SafeArea(
        child: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
          error: (err, stack) => Center(
            child: Text('Error loading data: $err', style: const TextStyle(color: Colors.red)),
          ),
          data: (data) {
            if (data == null) {
              return const Center(child: Text('No data found.', style: TextStyle(color: Colors.white)));
            }
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),
                  const SizedBox(height: 24),
                  _buildProfileSection(data),
                  const SizedBox(height: 24),
                  _buildValuationSection(isMobile, data),
                  const SizedBox(height: 24),
                  _buildFinancialsAndBalanceSheet(isMobile, data),
                  const SizedBox(height: 24),
                  _buildPeerComparison(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EQUITY INSIDER',
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFDAE2FD), // on-surface
            fontFamily: 'Hanken Grotesk',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fundamental Analysis & Valuation',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFFBDC8D1), // on-surface-variant
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(FundamentalRatiosResponse data) {
    return _SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    data.symbol ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDAE2FD),
                      fontFamily: 'Hanken Grotesk',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF38BDF8)),
                    ),
                    child: Text(
                      data.sector ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF38BDF8), // Primary
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹ ${data.bookValue?.toStringAsFixed(2) ?? "0.00"}', // placeholder
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDAE2FD),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Icon(Icons.arrow_upward, color: Color(0xFF4DE082), size: 16),
                  Text(
                    ' +1.24%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4DE082), // Success green
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValuationSection(bool isMobile, FundamentalRatiosResponse data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Valuation & Efficiency'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isMobile ? 2 : 5,
          shrinkWrap: true,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricCard('P/E Ratio', data.peRatio?.toStringAsFixed(1) ?? '-', 'Sector: 22.1', false),
            _MetricCard('P/B Ratio', data.pbRatio?.toStringAsFixed(1) ?? '-', 'Sector: 3.1', true),
            _MetricCard('EV/EBITDA', data.priceToSales?.toStringAsFixed(1) ?? '-', 'Sector: 12.5', false),
            _MetricCard('ROE', '${data.roe?.toStringAsFixed(1) ?? '-'}%', 'Sector: 15.2%', true),
            _MetricCard('ROCE', '${data.roce?.toStringAsFixed(1) ?? '-'}%', 'Sector: 18.0%', true),
          ],
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
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildFinancialPerformance(data)),
        const SizedBox(width: 24),
        Expanded(flex: 2, child: _buildBalanceSheetSummary(data)),
      ],
    );
  }

  Widget _buildFinancialPerformance(FundamentalRatiosResponse data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Financial Performance'),
        const SizedBox(height: 16),
        _SectionCard(
          child: Column(
            children: [
              _buildTableRow(['Metric', '2023', '2024', '2025'], isHeader: true),
              _buildTableRow(['EPS', '-', '-', data.eps?.toStringAsFixed(1) ?? '-']),
              _buildTableRow(['Operating Profit', '-', '-', '-']),
              _buildTableRow(['Dividend Yield', '-', '-', '${data.dividendYield?.toStringAsFixed(2) ?? "-"}%']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSheetSummary(FundamentalRatiosResponse data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Balance Sheet'),
        const SizedBox(height: 16),
        _SectionCard(
          child: Column(
            children: [
              _buildTableRow(['Item', 'Mar 2025'], isHeader: true),
              _buildTableRow(['Market Cap', '₹${(data.marketCap! / 1000).toStringAsFixed(1)}K']),
              _buildTableRow(['Debt to Equity', data.debtToEquity?.toStringAsFixed(2) ?? '-']),
              _buildTableRow(['Book Value', data.bookValue?.toStringAsFixed(2) ?? '-']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeerComparison() {
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
                  _buildTableRow(['RELIANCE', '₹2,945', '28.5', '2.8', '18.4%', '21.5%'], highlight: true),
                  _buildTableRow(['ONGC', '₹274', '6.2', '1.1', '14.8%', '16.5%']),
                  _buildTableRow(['BPCL', '₹612', '4.8', '1.5', '31.2%', '29.5%']),
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
                color: isHeader ? const Color(0xFF87929A) : (highlight ? const Color(0xFF38BDF8) : const Color(0xFFDAE2FD)),
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

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
        color: const Color(0xFF171F33), // surface-container
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3E484F)), // outline-variant
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF87929A),
              fontFamily: 'Inter',
            ),
          ),
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
