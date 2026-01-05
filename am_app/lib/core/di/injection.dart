import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';

final getIt = GetIt.instance;

/// Configure all dependencies for the application
Future<void> configureDependencies() async {
  // Register Theme Repository (required by ThemeCubit)
  getIt.registerLazySingleton<ThemeRepository>(() => ThemeRepository());
  
  // Register Theme Cubit with repository
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(getIt<ThemeRepository>()),
  );
  
  // Register Feature Flag Cubit
  getIt.registerLazySingleton<FeatureFlagCubit>(
    () => FeatureFlagCubit(),
  );
  
  // Register Auth-related dependencies first
  _registerAuthDependencies();
  
  // Register Auth Cubit after dependencies
  getIt.registerFactory<AuthCubit>(() {
    return AuthCubit(
      emailLoginUseCase: getIt<EmailLoginUseCase>(),
      googleLoginUseCase: getIt<GoogleLoginUseCase>(),
      demoLoginUseCase: getIt<DemoLoginUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      checkAuthStatusUseCase: getIt<CheckAuthStatusUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
    );
  });
}

void _registerAuthDependencies() {
  // Services
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );
  
  getIt.registerLazySingleton<MockDataService>(
    () => MockDataService(),
  );
  
  getIt.registerLazySingleton<GoogleSignInService>(
    () => GoogleSignInService(),
  );
  
  getIt.registerLazySingleton<Dio>(() => Dio());
  
  // Data sources
  getIt.registerLazySingleton<MockAuthDataSource>(
    () => MockAuthDataSource(getIt<MockDataService>()),
  );
  
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt<Dio>()),
  );

  
  // Repository - takes 4 params: MockAuthDataSource, AuthRemoteDataSource, SecureStorageService, GoogleSignInService
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<MockAuthDataSource>(),
      getIt<AuthRemoteDataSource>(),
      getIt<SecureStorageService>(),
      getIt<GoogleSignInService>(),
    ),
  );
  
  // Use cases
  getIt.registerLazySingleton<EmailLoginUseCase>(
    () => EmailLoginUseCase(getIt<AuthRepository>()),
  );
  
  getIt.registerLazySingleton<GoogleLoginUseCase>(
    () => GoogleLoginUseCase(getIt<AuthRepository>()),
  );
  
  getIt.registerLazySingleton<DemoLoginUseCase>(
    () => DemoLoginUseCase(getIt<AuthRepository>()),
  );
  
  getIt.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(getIt<AuthRepository>()),
  );
  
  getIt.registerLazySingleton<CheckAuthStatusUseCase>(
    () => CheckAuthStatusUseCase(getIt<AuthRepository>()),
  );
  
  getIt.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );
  
  getIt.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(getIt<AuthRepository>()),
  );
}
