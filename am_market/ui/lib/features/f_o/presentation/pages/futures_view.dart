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
            Text('Failed to load Futures contracts from backend API', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(err.toString(), style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No Futures Contracts Found in Backend Database',
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1024;

            if (isDesktop) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Futures Contracts Table + Price Chart
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

                    // Right Column: Selected Contract & Details + Open Interest + Market Depth
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

            // Mobile / Tablet Responsive Layout (Single Column Vertical Stack)
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FuturesContractsTableWidget(contracts: contracts),
                  const SizedBox(height: 16),
                  const FuturesSelectedContractCard(),
                  const SizedBox(height: 16),
                  const FuturesContractDetailsCard(),
                  const SizedBox(height: 16),
                  const FuturesOpenInterestCard(),
                  const SizedBox(height: 16),
                  const FuturesPriceChartWidget(),
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
}
