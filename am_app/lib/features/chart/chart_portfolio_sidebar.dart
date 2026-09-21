import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected portfolio for chart terminal (sidebar → bottom Holdings table).
class ChartSelectedPortfolio {
  const ChartSelectedPortfolio({
    required this.id,
    required this.name,
    this.isPaper = false,
  });

  final String id;
  final String name;
  final bool isPaper;
}

class ChartSelectedPortfolioNotifier
    extends Notifier<ChartSelectedPortfolio?> {
  @override
  ChartSelectedPortfolio? build() => null;

  void select(ChartSelectedPortfolio? value) => state = value;
}

final chartSelectedPortfolioProvider = NotifierProvider<
    ChartSelectedPortfolioNotifier, ChartSelectedPortfolio?>(
  ChartSelectedPortfolioNotifier.new,
);

/// Portfolio tab: list of portfolio / basket names. Tap to select (holdings
/// load in the chart bottom Holdings tag — not inline here).
class ChartPortfolioSidebar extends ConsumerStatefulWidget {
  const ChartPortfolioSidebar({
    super.key,
    required this.paperEnabled,
    this.onPortfolioSelected,
  });

  final bool paperEnabled;
  final ValueChanged<ChartSelectedPortfolio>? onPortfolioSelected;

  @override
  ConsumerState<ChartPortfolioSidebar> createState() =>
      _ChartPortfolioSidebarState();
}

class _ChartPortfolioSidebarState extends ConsumerState<ChartPortfolioSidebar> {
  List<PortfolioItem>? _portfolios;
  Object? _listError;
  bool _listLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolios();
  }

  Future<void> _loadPortfolios() async {
    setState(() {
      _listLoading = true;
      _listError = null;
    });
    try {
      final client = await ref.read(portfolioApiClientProvider.future);
      final items = await client.get<List<PortfolioItem>>(
        '/v1/portfolios/list',
        parser: _parsePortfolioList,
      );
      if (!mounted) return;
      setState(() {
        _portfolios = items;
        _listLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _listError = e;
        _listLoading = false;
      });
    }
  }

  static List<PortfolioItem> _parsePortfolioList(dynamic data) {
    final List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is Map && data['portfolios'] is List) {
      raw = data['portfolios'] as List;
    } else {
      return const [];
    }

    final out = <PortfolioItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final kind = (map['kind'] as String?)?.toUpperCase() ?? '';
      if (kind == 'DELETED') continue;
      final id = (map['portfolioId'] as String?) ?? (map['id'] as String?) ?? '';
      final name = (map['portfolioName'] as String?) ??
          (map['name'] as String?) ??
          '';
      if (id.isEmpty || name.isEmpty) continue;
      final isBasket = kind == 'BASKET' || map['isBasket'] == true;
      final isDummy = kind == 'DUMMY' ||
          kind == 'DEMO' ||
          map['isDummy'] == true ||
          map['dummy'] == true;
      out.add(
        PortfolioItem(
          portfolioId: id,
          portfolioName: name,
          isBasket: isBasket,
          isDummy: isDummy,
        ),
      );
    }
    return out;
  }

  void _select(ChartSelectedPortfolio sel) {
    ref.read(chartSelectedPortfolioProvider.notifier).select(sel);
    widget.onPortfolioSelected?.call(sel);
  }

  @override
  Widget build(BuildContext context) {
    if (_listLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_listError != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Portfolios unavailable',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: _loadPortfolios,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final portfolios = _portfolios ?? const <PortfolioItem>[];
    final selected = ref.watch(chartSelectedPortfolioProvider);
    final theme = Theme.of(context);

    final rows = <ChartSelectedPortfolio>[
      for (final p in portfolios)
        ChartSelectedPortfolio(
          id: p.portfolioId,
          name: p.isBasket ? '${p.portfolioName} (Basket)' : p.portfolioName,
        ),
      if (widget.paperEnabled)
        const ChartSelectedPortfolio(
          id: 'paper',
          name: 'Paper',
          isPaper: true,
        ),
    ];

    if (rows.isEmpty) {
      return Center(
        child: Text(
          'No portfolios yet',
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Text(
            'Select a portfolio',
            style: TextStyle(fontSize: 11, color: theme.hintColor),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: rows.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.45),
            ),
            itemBuilder: (context, i) {
              final row = rows[i];
              final isSel = selected?.id == row.id;
              return InkWell(
                onTap: () => _select(row),
                child: Container(
                  color: isSel
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.name,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight:
                                isSel ? FontWeight.w700 : FontWeight.w600,
                            color: isSel ? theme.colorScheme.primary : null,
                          ),
                        ),
                      ),
                      Icon(
                        isSel
                            ? Icons.check_circle
                            : Icons.chevron_right,
                        size: 18,
                        color: isSel
                            ? theme.colorScheme.primary
                            : theme.hintColor,
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
}
