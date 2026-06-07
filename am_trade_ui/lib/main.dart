import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_common/am_common.dart';
import 'package:am_trade_ui/am_trade_ui.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'features/trade/providers/trade_controller_providers.dart';
import 'features/trade/presentation/cubit/trade_controller_cubit.dart';
import 'features/trade/presentation/trade_responsive_layout.dart';
import 'features/trade/presentation/mobile/pages/add_trade_mobile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ConfigService
  await ConfigService.initialize();

  // Initialize ServiceRegistry
  ServiceRegistry.initialize(
    analysisBaseUrl: ConfigService.config.api.analysis!.baseUrl,
    wsUrl: EnvDomains.wsStream,
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
                      localizationsDelegates: const [
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                        FlutterQuillLocalizations.delegate,
                      ],
                      supportedLocales: const [
                        Locale('en', 'US'),
                      ],
                      home: const AuthWrapper(
                        child: TradeResponsiveLayout(),
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
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 1100) {
                                    return AddTradeMobilePage(
                                      portfolioId: (args?['portfolioId'] as String?) ?? '',
                                      portfolioName: args?['portfolioName'] as String?,
                                    );
                                  }
                                  return AddTradeWebPage(
                                    portfolioId: (args?['portfolioId'] as String?) ?? '',
                                    portfolioName: args?['portfolioName'] as String?,
                                  );
                                },
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
