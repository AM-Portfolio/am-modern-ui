import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart' as auth_ui;
import 'package:am_common/am_common.dart' as common;

final getIt = GetIt.instance;

/// Configure all dependencies for the application
Future<void> configureDependencies() async {
  debugPrint('🔧 configuring dependencies... START');
  // Register Theme Repository (required by ThemeCubit)
  getIt.registerLazySingleton<ThemeRepository>(() => ThemeRepository());
  
  // Register Theme Cubit with repository
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(getIt<ThemeRepository>()),
  );
  
  // Register Auth-related dependencies first
  try {
    debugPrint('🔧 Registering Auth dependencies...');
    _registerAuthDependencies();
  } catch (e) {
    debugPrint('❌ Error registering Auth dependencies: $e');
  }
  
  // Register Portfolio-related dependencies
  try {
    debugPrint('🔧 Registering Portfolio dependencies...');
    _registerPortfolioDependencies();
    debugPrint('✅ Portfolio dependencies registered available: ${getIt.isRegistered<common.AmStompClient>()}');
  } catch (e) {
    debugPrint('❌ Error registering Portfolio dependencies: $e');
  }
  
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
  debugPrint('🔧 configuring dependencies... END');
}

void _registerAuthDependencies() {
  // Services - Auth UI version for auth-related code
  getIt.registerLazySingleton<auth_ui.SecureStorageService>(
    () => auth_ui.SecureStorageService(),
  );
  
  // Also register common version for Portfolio/other modules
  getIt.registerLazySingleton<common.SecureStorageService>(
    () => common.SecureStorageService(),
  );
  
  getIt.registerLazySingleton<auth_ui.MockDataService>(
    () => auth_ui.MockDataService(),
  );
  
  getIt.registerLazySingleton<auth_ui.GoogleSignInService>(
    () => auth_ui.GoogleSignInService(),
  );
  
  getIt.registerLazySingleton<Dio>(() => Dio());
  
  // Data sources
  getIt.registerLazySingleton<auth_ui.MockAuthDataSource>(
    () => auth_ui.MockAuthDataSource(getIt<auth_ui.MockDataService>()),
  );
  
  getIt.registerLazySingleton<auth_ui.AuthRemoteDataSource>(
    () => auth_ui.AuthRemoteDataSource(getIt<Dio>()),
  );

  
  // Repository - takes 4 params: MockAuthDataSource, AuthRemoteDataSource, SecureStorageService, GoogleSignInService
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

void _registerPortfolioDependencies() {
  // Register WebSocket client (AmStompClient) required by Portfolio module
  getIt.registerLazySingleton<common.AmStompClient>(() {
    final client = common.AmStompClient();
    // Configure WebSocket endpoint - using raw WebSocket endpoint (no SockJS)
    client.configure(url: 'ws://localhost:8091/ws-gateway-raw');
    return client;
  });
  
  // Note: Portfolio UI uses Riverpod providers for its internal dependencies
  // Only shared/common dependencies need to be registered in GetIt
}
