import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_common/am_common.dart';
import 'package:am_trade_ui/am_trade_ui.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_design_system/am_design_system.dart';
import 'features/trade/providers/trade_controller_providers.dart';
import 'features/trade/presentation/cubit/trade_controller_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ConfigService
  await ConfigService.initialize();

  // Initialize ServiceRegistry
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
            data: (tradeCubit) {
              final authCubit = AuthProviders.createAuthCubit()..checkAuthStatus();
              final themeCubit = ThemeCubit(ThemeRepository());
              
              return MultiBlocProvider(
                providers: [
                  BlocProvider<AuthCubit>.value(value: authCubit),
                  BlocProvider<ThemeCubit>.value(value: themeCubit),
                  BlocProvider<TradeControllerCubit>.value(value: tradeCubit),
                  BlocProvider<FeatureFlagCubit>(create: (context) => FeatureFlagCubit()),
                ],
                child: BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, themeState) {
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: themeState.lightTheme,
                      darkTheme: themeState.darkTheme,
                      themeMode: themeState.themeMode,
                      home: BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, authState) {
                          if (authState is AuthInitial || authState is AuthLoading) {
                            return const Scaffold(body: Center(child: CircularProgressIndicator()));
                          }
                          if (authState is Authenticated) {
                            return TradeWebScreen(userId: authState.user.id);
                          }
                          return const LoginPage();
                        },
                      ),
                      onGenerateRoute: (settings) {
                        if (settings.name == '/trade/add') {
                          final args = settings.arguments as Map<String, dynamic>?;
                          return MaterialPageRoute(
                            builder: (context) => MultiBlocProvider(
                              providers: [
                                BlocProvider<TradeControllerCubit>.value(value: tradeCubit),
                                BlocProvider<AuthCubit>.value(value: authCubit),
                                BlocProvider<ThemeCubit>.value(value: themeCubit),
                              ],
                              child: AddTradeWebPage(
                                portfolioId: (args?['portfolioId'] as String?) ?? '',
                                portfolioName: args?['portfolioName'] as String?,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))),
            error: (e, s) => MaterialApp(home: Scaffold(body: Center(child: Text('Error: $e')))),
          );
        },
      ),
    ),
  );
}
