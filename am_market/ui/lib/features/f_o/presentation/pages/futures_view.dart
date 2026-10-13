import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/futures_contract_details_card.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/futures_contracts_table_widget.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/futures_market_depth_metrics_card.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/futures_open_interest_card.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/futures_price_chart_widget.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/futures_selected_contract_card.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FuturesView extends ConsumerWidget {
  const FuturesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;
    final futuresAsync = ref.watch(futuresContractsProvider);

    return futuresAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: ModuleColors.market),
      ),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: marketTheme.negative, size: 36),
            const SizedBox(height: 12),
            Text(
              'Failed to load Futures contracts from backend API',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              err.toString(),
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      data: (contracts) {
        if (contracts.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.5),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colors.statusWarning,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Futures Contracts Found in Backend Database',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The backend API (/v1/instruments/search) returned 0 futures instruments. Run instrument sync on the backend.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        _ensureDefaultSelection(ref, contracts);

        return LayoutBuilder(
          builder: (context, constraints) {
            // Desktop split only at AmBreakpoints.desktop (≥1100); preserves prior wide layout.
            final isDesktop = constraints.maxWidth >= AmBreakpoints.tablet;
            final isMobile = constraints.maxWidth < AmBreakpoints.mobile;
            final pad = isMobile ? 12.0 : 16.0;

            if (isDesktop) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(pad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FuturesContractsTableWidget(contracts: contracts),
                          const SizedBox(height: 16),
                          const FuturesPriceChartWidget(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: FuturesSelectedContractCard()),
                              SizedBox(width: 12),
                              Expanded(child: FuturesContractDetailsCard()),
                            ],
                          ),
                          SizedBox(height: 16),
                          FuturesOpenInterestCard(),
                          SizedBox(height: 16),
                          FuturesMarketDepthMetricsCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Mobile / tablet: mockup first screen then charts below fold.
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FuturesContractsTableWidget(contracts: contracts),
                  const SizedBox(height: 12),
                  const FuturesContractDetailsCard(mobileInformationLayout: true),
                  const SizedBox(height: 16),
                  const FuturesPriceChartWidget(),
                  const SizedBox(height: 16),
                  const FuturesOpenInterestCard(),
                  const SizedBox(height: 16),
                  const FuturesMarketDepthMetricsCard(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void _ensureDefaultSelection(WidgetRef ref, List<dynamic> contracts) {
    final selected = ref.read(selectedFutureContractProvider);
    if (selected != null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    Map<String, dynamic>? pick;
    for (final c in contracts) {
      if (c is! Map) continue;
      final map = Map<String, dynamic>.from(c);
      final rawExp = map['expiry'];
      if (rawExp is num && rawExp > 0 && rawExp.toInt() < nowMs - 86400000) {
        continue;
      }
      pick = map;
      break;
    }
    if (pick == null && contracts.isNotEmpty && contracts.first is Map) {
      pick = Map<String, dynamic>.from(contracts.first as Map);
    }
    if (pick == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(selectedFutureContractProvider) != null) return;
      final tradingSymbol = (pick!['trading_symbol'] ??
              pick['tradingSymbol'] ??
              pick['name'] ??
              'FUT')
          .toString();
      final rawExpiry = pick['expiry'];
      ref.read(selectedFutureContractProvider.notifier).state = {
        ...pick,
        'trading_symbol': tradingSymbol,
        if (rawExpiry is num) 'expiry_ms': rawExpiry.toInt(),
      };
    });
  }
}
