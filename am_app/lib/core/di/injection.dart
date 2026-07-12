import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart' as auth_ui;
import 'package:am_dashboard_ui/am_dashboard_ui.dart' as dashboard_ui;
import 'package:am_common/am_common.dart' as common;
import 'package:am_library/am_library.dart';
import 'package:am_subscription_ui/am_subscription_ui.dart' as subscription_ui;

final getIt = GetIt.instance;
bool _featureDependenciesConfigured = false;

/// Core dependencies required before first paint (auth, theme, dashboard, router).
Future<void> configureCoreDependencies() async {
  ServiceRegistry.initialize(
    analysisBaseUrl: common.EnvDomains.analysis,
    wsUrl: common.EnvDomains.wsStream,
  );

  getIt.registerLazySingleton<ThemeRepository>(() => ThemeRepository());

  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(getIt<ThemeRepository>()),
  );

  _registerAuthDependencies();
  _registerDashboardDependencies();

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

  getIt.registerLazySingleton<auth_ui.FeatureFlagCubit>(
    () => auth_ui.FeatureFlagCubit(),
  );

  getIt.registerLazySingleton<common.StompConnectionCubit>(
    () => common.StompConnectionCubit(
      stompClient: getIt<common.AmStompClient>(),
    ),
  );

  common.BootTrace.instance.mark('di_core_done');
}

/// Feature DI — lightweight services needed by deferred modules when they load.
Future<void> configureFeatureDependencies() async {
  if (_featureDependenciesConfigured) return;
  _featureDependenciesConfigured = true;
  _registerSubscriptionDependencies();
  common.BootTrace.instance.mark('di_feature_done');
}

/// Backward-compatible entry — registers everything (used by standalone modules).
Future<void> configureDependencies() async {
  await configureCoreDependencies();
  await configureFeatureDependencies();
}

void _registerAuthDependencies() {
  getIt.registerLazySingleton<auth_ui.MockDataService>(
    () => auth_ui.MockDataService(),
  );

  getIt.registerLazySingleton<auth_ui.GoogleSignInService>(
    () => auth_ui.GoogleSignInService(),
  );

  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return dio;
  });

  getIt.registerLazySingleton<auth_ui.MockAuthDataSource>(
    () => auth_ui.MockAuthDataSource(getIt<auth_ui.MockDataService>()),
  );

  getIt.registerLazySingleton<auth_ui.AuthRemoteDataSource>(
    () => auth_ui.AuthRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<auth_ui.IdentityAuthRemoteDataSource>(
    () => auth_ui.IdentityAuthRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<auth_ui.AuthRepository>(
    () => auth_ui.AuthRepositoryImpl(
      getIt<auth_ui.MockAuthDataSource>(),
      getIt<auth_ui.AuthRemoteDataSource>(),
      getIt<auth_ui.IdentityAuthRemoteDataSource>(),
      getIt<auth_ui.SecureStorageService>(),
      getIt<auth_ui.GoogleSignInService>(),
    ),
  );

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

void _registerDashboardDependencies() {
  getIt.registerLazySingleton<dashboard_ui.DashboardRepository>(() {
    return dashboard_ui.DashboardRepository(
      getIt<common.ApiClient>(),
      getIt<common.AmStompClient>(),
    );
  });
}

void _registerSubscriptionDependencies() {
  String baseUrl = common.EnvDomains.subscription;
  if (baseUrl.endsWith('/subscriptions')) {
    baseUrl = baseUrl.substring(0, baseUrl.length - '/subscriptions'.length);
  } else if (baseUrl.endsWith('/subscriptions/')) {
    baseUrl = baseUrl.substring(0, baseUrl.length - '/subscriptions/'.length);
  }

  final subscriptionDio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  subscriptionDio.interceptors.add(
    auth_ui.AuthInterceptor(getIt<auth_ui.SecureStorageService>()),
  );
  getIt.registerSingleton<Dio>(
    subscriptionDio,
    instanceName: 'subscriptionDio',
  );

  getIt.registerLazySingleton<subscription_ui.SubscriptionRemoteDataSource>(
    () => subscription_ui.SubscriptionRemoteDataSourceImpl(
      getIt<Dio>(instanceName: 'subscriptionDio'),
    ),
  );

  getIt.registerLazySingleton<subscription_ui.SubscriptionCubit>(
    () => subscription_ui.SubscriptionCubit(
      getIt<subscription_ui.SubscriptionRemoteDataSource>(),
    ),
  );
}
