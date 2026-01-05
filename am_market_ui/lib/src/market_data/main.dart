import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/core/theme/theme_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/market_provider.dart';
import 'providers/mode_provider.dart';
import 'services/api_service.dart';
import 'services/market_data_sdk_service.dart';
import 'market_module.dart'; // Import the market module
// import 'data/repositories/market_data_repository_impl.dart'; // Disabled until mappers are fixed
import 'screens/home_page.dart';
import 'screens/admin/historical_sync_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CommonLogger.configure(minLevel: LogLevel.debug);
  await ConfigService.initialize(environment: 'dev'); // Or 'production'
  
  // Register dependencies
  final getIt = GetIt.instance;
  if (!getIt.isRegistered<SecureStorageService>()) {
    getIt.registerSingleton<SecureStorageService>(AuthProviders.secureStorageService);
  }

  runApp(const MarketDataApp());
}

class MarketDataApp extends StatelessWidget {
  const MarketDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        ...AuthProviders.providers,
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(ThemeRepository())),
      ],
      child: MultiProvider(
        providers: [
          Provider(create: (_) => ApiService()),
          ChangeNotifierProvider(create: (_) => ModeProvider()),
          ChangeNotifierProvider(create: (_) => MarketProvider()),
          // TODO: Enable repository once mappers are fixed
          // ChangeNotifierProvider(
          //   create: (context) {
          //     final sdkService = MarketDataSdkService();
          //     final repository = MarketDataRepositoryImpl(sdkService);
          //     return MarketProvider(repository: repository);
          //   },
          // ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'Market Data Dashboard',
              theme: themeState.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeState.themeMode,
              // Use traditional HomePage for now (stable)
              // Module files exist and will be used in Phase 3 for am-investment-ui integration
              home: AuthWrapper(
                loginTitle: 'AM Market Data',
                child: const HomePage(),
              ),
              routes: {
                '/admin': (context) => const HistoricalSyncPage(),
              },
            );
          },
        ),
      ),
    );
  }
}
