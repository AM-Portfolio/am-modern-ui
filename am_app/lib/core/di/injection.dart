import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart' as auth_ui;
import 'package:am_dashboard_ui/am_dashboard_ui.dart' as dashboard_ui;
import 'package:am_common/am_common.dart' as common;
import 'package:am_library/am_library.dart';

// Trade Module Imports
import 'package:am_trade_ui/features/trade/internal/data/datasources/trade_controller_remote_data_source.dart' as trade_remote;
import 'package:am_trade_ui/features/trade/internal/data/repositories/trade_controller_repository_impl.dart' as trade_repo_impl;
import 'package:am_trade_ui/features/trade/internal/domain/repositories/trade_controller_repository.dart' as trade_repo;
import 'package:am_trade_ui/features/trade/internal/domain/usecases/add_trade.dart';
import 'package:am_trade_ui/features/trade/internal/domain/usecases/update_trade.dart';
import 'package:am_trade_ui/features/trade/internal/domain/usecases/delete_trade.dart';
import 'package:am_trade_ui/features/trade/internal/domain/usecases/get_trades_by_portfolio.dart';
import 'package:am_trade_ui/features/trade/presentation/cubit/trade_controller_cubit.dart';

final getIt = GetIt.instance;

/// Configure all dependencies for the application
Future<void> configureDependencies() async {
  // 1. Initialize Technical Infrastructure (One Source of Truth)
  ServiceRegistry.initialize(
    analysisBaseUrl: common.ConfigService.config.api.analysis?.baseUrl,
    wsUrl: common.ConfigService.config.api.marketData?.wsUrl,
  );

  // Register Theme Repository (required by ThemeCubit)
  getIt.registerLazySingleton<ThemeRepository>(() => ThemeRepository());

  // Register Theme Cubit with repository
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(getIt<ThemeRepository>()),
  );

  // Register Auth-related dependencies first
  _registerAuthDependencies();

  // Register Dashboard-related dependencies
  _registerDashboardDependencies();

  // Register Portfolio-related dependencies
  _registerPortfolioDependencies();

  // Register Trade-related dependencies
  _registerTradeDependencies();

  // Register Market-related dependencies
  _registerMarketDependencies();

  // Register remaining module dependencies
  _registerUserDependencies();
  _registerAiDependencies();
  _registerDiagnosticDependencies();
  _registerAnalysisDependencies();

  // ────────────────────────────────────────────────────────────────────────

  // Register Auth Cubit after dependencies
  getIt.registerFactory<auth_ui.AuthCubit>(() {
    return auth_ui.AuthCubit(
      emailLoginUseCase: getIt<auth_ui.EmailLoginUseCase>(),
      googleLoginUseCase: getIt<auth_ui.GoogleLoginUseCase>(),
      demoLoginUseCase: getIt<auth_ui.DemoLoginUseCase>(),
      logoutUseCase: getIt<auth_ui.LogoutUseCase>(),
      checkAuthStatusUseCase: getIt<auth_ui.CheckAuthStatusUseCase>(),
      getCurrentUserUseCase: getIt<auth_ui.GetCurrentUserUseCase>(),
      registerUseCase: getIt<auth_ui.RegisterUseCase>(),
    );
  });

  // Register Feature Flag Cubit
  getIt.registerLazySingleton<auth_ui.FeatureFlagCubit>(
    () => auth_ui.FeatureFlagCubit(),
  );

  // Register Stomp Connection Cubit (Manages global WebSocket lifecycle)
  getIt.registerLazySingleton<common.StompConnectionCubit>(
    () => common.StompConnectionCubit(
      stompClient: getIt<common.AmStompClient>(),
    ),
  );
}

void _registerAuthDependencies() {
  // SecureStorageService is handled by ServiceRegistry.initialize()

  getIt.registerLazySingleton<auth_ui.MockDataService>(
    () => auth_ui.MockDataService(),
  );

  getIt.registerLazySingleton<auth_ui.GoogleSignInService>(
    () => auth_ui.GoogleSignInService(),
  );

  getIt.registerLazySingleton<Dio>(() => Dio());

  // ApiClient now from ServiceRegistry
  // ApiClient is handled by ServiceRegistry.initialize()

  // Data sources
  getIt.registerLazySingleton<auth_ui.MockAuthDataSource>(
    () => auth_ui.MockAuthDataSource(getIt<auth_ui.MockDataService>()),
  );

  getIt.registerLazySingleton<auth_ui.AuthRemoteDataSource>(
    () => auth_ui.AuthRemoteDataSource(getIt<Dio>()),
  );

  // Repository
  getIt.registerLazySingleton<auth_ui.AuthRepository>(
    () => auth_ui.AuthRepositoryImpl(
      getIt<auth_ui.MockAuthDataSource>(),
      getIt<auth_ui.AuthRemoteDataSource>(),
      getIt<auth_ui.SecureStorageService>(),
      getIt<auth_ui.GoogleSignInService>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<auth_ui.EmailLoginUseCase>(
    () => auth_ui.EmailLoginUseCase(getIt<auth_ui.AuthRepository>()),
  );
  getIt.registerLazySingleton<auth_ui.GoogleLoginUseCase>(
    () => auth_ui.GoogleLoginUseCase(getIt<auth_ui.AuthRepository>()),
  );
  getIt.registerLazySingleton<auth_ui.DemoLoginUseCase>(
    () => auth_ui.DemoLoginUseCase(getIt<auth_ui.AuthRepository>()),
  );
  getIt.registerLazySingleton<auth_ui.LogoutUseCase>(
    () => auth_ui.LogoutUseCase(getIt<auth_ui.AuthRepository>()),
  );
  getIt.registerLazySingleton<auth_ui.CheckAuthStatusUseCase>(
    () => auth_ui.CheckAuthStatusUseCase(getIt<auth_ui.AuthRepository>()),
  );
  getIt.registerLazySingleton<auth_ui.GetCurrentUserUseCase>(
    () => auth_ui.GetCurrentUserUseCase(getIt<auth_ui.AuthRepository>()),
  );
  getIt.registerLazySingleton<auth_ui.RegisterUseCase>(
    () => auth_ui.RegisterUseCase(getIt<auth_ui.AuthRepository>()),
  );
}

// ── SHARED INFRA — available for re-use when modules are re-enabled ─────────
//
// Call this once before registering Portfolio / Trade / Market deps:
//   _registerSharedInfra();
//
// void _registerSharedInfra() {
//   getIt.registerLazySingleton<common.AmStompClient>(
//       () => ServiceRegistry.stomp);
// }

void _registerDashboardDependencies() {
  // Dashboard uses ApiClient + AmStompClient from ServiceRegistry
  // AmStompClient is handled by ServiceRegistry.initialize()

  getIt.registerLazySingleton<dashboard_ui.DashboardRepository>(() {
    return dashboard_ui.DashboardRepository(
      getIt<common.ApiClient>(),
      getIt<common.AmStompClient>(),
    );
  });
}

void _registerMarketDependencies() {
  // Market UI uses Riverpod providers for its internal dependencies
}
void _registerPortfolioDependencies() {
  // Portfolio UI uses Riverpod providers for its internal dependencies
  // Only shared/common dependencies need to be registered in GetIt
}

// ── TRADE (re-enable with am_trade_ui) ───────────────────────────────────────
void _registerTradeDependencies() {
  // Data sources
  getIt.registerLazySingleton<trade_remote.TradeControllerRemoteDataSource>(
    () => trade_remote.TradeControllerRemoteDataSourceImpl(
      apiClient: getIt<common.ApiClient>(),
    ),
  );

  // Repository
  getIt.registerLazySingleton<trade_repo.TradeControllerRepository>(
    () => trade_repo_impl.TradeControllerRepositoryImpl(
      remoteDataSource: getIt<trade_remote.TradeControllerRemoteDataSource>(),
      stompClient: getIt<common.AmStompClient>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<AddTrade>(
    () => AddTrade(getIt<trade_repo.TradeControllerRepository>()),
  );
  getIt.registerLazySingleton<UpdateTrade>(
    () => UpdateTrade(getIt<trade_repo.TradeControllerRepository>()),
  );
  getIt.registerLazySingleton<DeleteTrade>(
    () => DeleteTrade(getIt<trade_repo.TradeControllerRepository>()),
  );
  getIt.registerLazySingleton<GetTradesByPortfolio>(
    () => GetTradesByPortfolio(getIt<trade_repo.TradeControllerRepository>()),
  );

  // Cubit
  getIt.registerFactory<TradeControllerCubit>(
    () => TradeControllerCubit(
      addTrade: getIt<AddTrade>(),
      updateTrade: getIt<UpdateTrade>(),
      deleteTrade: getIt<DeleteTrade>(),
      getTradesByPortfolio: getIt<GetTradesByPortfolio>(),
    ),
  );
}

void _registerUserDependencies() {
  // User UI registration placeholder
}

void _registerAiDependencies() {
  // AI UI registration placeholder
}

void _registerDiagnosticDependencies() {
  // Diagnostic UI registration placeholder
}

void _registerAnalysisDependencies() {
  // Analysis UI registration placeholder
}
