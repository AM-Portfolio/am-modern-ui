import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_common/am_common.dart';
import 'package:am_trade_ui/am_trade_ui.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'features/trade/providers/trade_controller_providers.dart';
import 'features/trade/presentation/cubit/trade_controller_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ConfigService (sets the port to 8082 and disables mocks)
  await ConfigService.initialize();

  // Initialize ServiceRegistry for core infrastructure (ApiClient, Telemetry, etc.)
  ServiceRegistry.initialize(
    analysisBaseUrl: ConfigService.config.api.analysis!.baseUrl,
    wsUrl: ConfigService.config.api.marketData!.wsUrl,
  );
  
  runApp(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final cubitAsync = ref.watch(tradeControllerCubitProvider);

          return cubitAsync.when(
            data: (cubit) => BlocProvider<TradeControllerCubit>(
              create: (context) => cubit,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                home: TradeWebScreen(userId: 'user_gyaan'),
                onGenerateRoute: (settings) {
                  if (settings.name == '/trade/add') {
                    final args = settings.arguments as Map<String, dynamic>?;
                    return MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: cubit,
                        child: AddTradeWebPage(
                          portfolioId: args?['portfolioId'] as String? ?? '1001',
                          portfolioName: args?['portfolioName'] as String?,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            loading: () => const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))),
            error: (e, s) => MaterialApp(home: Scaffold(body: Center(child: Text('Error: $e')))),
          );
        },
      ),
    ),
  );
}

