import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/network/auth_interceptor.dart';
import '../core/services/app_lock_service.dart';
import '../core/services/secure_storage_service.dart';
import '../core/services/security_alert_service.dart';
import '../core/services/step_up_service.dart';
import '../core/services/token_refresh_service.dart';
import '../features/authentication/data/datasources/auth_remote_datasource.dart';
import '../features/authentication/data/datasources/device_link_remote_datasource.dart';
import '../features/authentication/data/datasources/identity_auth_remote_datasource.dart';
import '../features/authentication/data/datasources/login_sessions_remote_datasource.dart';
import '../features/authentication/data/datasources/mock_auth_datasource.dart';
import '../features/authentication/data/repositories/auth_repository_impl.dart';
import '../features/authentication/data/services/device_link_poll_service.dart';
import '../features/authentication/data/services/google_signin_service.dart';
import '../features/authentication/data/services/mock_data_service.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';
import '../features/authentication/domain/usecases/check_auth_status_usecase.dart';
import '../features/authentication/domain/usecases/demo_login_usecase.dart';
import '../features/authentication/domain/usecases/email_login_usecase.dart';
import '../features/authentication/domain/usecases/get_current_user_usecase.dart';
import '../features/authentication/domain/usecases/google_login_usecase.dart';
import '../features/authentication/domain/usecases/logout_usecase.dart';
import '../features/authentication/domain/usecases/register_usecase.dart';
import '../features/authentication/presentation/cubit/auth_cubit.dart';

class AuthProviders {
  static SecureStorageService? _secureStorageService;
  static MockDataService? _mockDataService;
  static Dio? _dio;
  static Dio? _plainDio;
  static Dio? _cookieDio;
  static TokenRefreshService? _tokenRefreshService;
  static AppLockService? _appLockService;
  static DeviceLinkRemoteDataSource? _deviceLinkRemoteDataSource;
  static DeviceLinkPollService? _deviceLinkPollService;
  static LoginSessionsRemoteDataSource? _loginSessionsRemoteDataSource;
  static SecurityAlertService? _securityAlertService;
  static StepUpService? _stepUpService;
  static MockAuthDataSource? _mockAuthDataSource;
  static AuthRemoteDataSource? _authRemoteDataSource;
  static IdentityAuthRemoteDataSource? _identityAuthRemoteDataSource;
  static AuthRepository? _authRepository;

  static SecureStorageService get secureStorageService {
    _secureStorageService ??= SecureStorageService();
    return _secureStorageService!;
  }

  static MockDataService get mockDataService {
    _mockDataService ??= MockDataService();
    return _mockDataService!;
  }

  static Dio _createDio({bool withCredentials = false}) {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        extra: withCredentials ? const {'withCredentials': true} : null,
      ),
    );
  }

  static Dio get _refreshDio {
    _plainDio ??= _createDio();
    return _plainDio!;
  }

  static Dio get cookieDio {
    _cookieDio ??= _createDio(withCredentials: true);
    return _cookieDio!;
  }

  static TokenRefreshService get tokenRefreshService {
    _tokenRefreshService ??= TokenRefreshService(
      storageService: secureStorageService,
      refreshApi: (refreshToken) => IdentityAuthRemoteDataSource(_refreshDio)
          .refreshToken(refreshToken),
    )..configureProactiveRefresh();
    return _tokenRefreshService!;
  }

  static AppLockService get appLockService {
    _appLockService ??= AppLockService(
      storageService: secureStorageService,
      tokenRefreshService: tokenRefreshService,
    );
    return _appLockService!;
  }

  static DeviceLinkRemoteDataSource get deviceLinkRemoteDataSource {
    _deviceLinkRemoteDataSource ??=
        DeviceLinkRemoteDataSource(cookieDio);
    return _deviceLinkRemoteDataSource!;
  }

  static DeviceLinkPollService get deviceLinkPollService {
    _deviceLinkPollService ??=
        DeviceLinkPollService(deviceLinkRemoteDataSource);
    return _deviceLinkPollService!;
  }

  static LoginSessionsRemoteDataSource get loginSessionsRemoteDataSource {
    _loginSessionsRemoteDataSource ??= LoginSessionsRemoteDataSource(
      dio,
      storage: secureStorageService,
      cookieDio: cookieDio,
    );
    return _loginSessionsRemoteDataSource!;
  }

  static SecurityAlertService get securityAlertService {
    _securityAlertService ??=
        SecurityAlertService(dataSource: loginSessionsRemoteDataSource);
    return _securityAlertService!;
  }

  static StepUpService get stepUpService {
    _stepUpService ??= StepUpService(dio);
    return _stepUpService!;
  }

  static Dio get dio {
    if (_dio != null) {
      return _dio!;
    }

    _dio = _createDio();
    attachAuthInterceptor(_dio!);
    return _dio!;
  }

  static void attachAuthInterceptor(Dio dio) {
    dio.interceptors.add(
      AuthInterceptor(
        secureStorageService,
        tokenRefreshService: tokenRefreshService,
        dio: dio,
      ),
    );
  }

  static MockAuthDataSource get mockAuthDataSource {
    _mockAuthDataSource ??= MockAuthDataSource(mockDataService);
    return _mockAuthDataSource!;
  }

  static AuthRemoteDataSource get authRemoteDataSource {
    _authRemoteDataSource ??= AuthRemoteDataSource(dio);
    return _authRemoteDataSource!;
  }

  static IdentityAuthRemoteDataSource get identityAuthRemoteDataSource {
    _identityAuthRemoteDataSource ??= IdentityAuthRemoteDataSource(dio);
    return _identityAuthRemoteDataSource!;
  }

  static AuthRepository get authRepository {
    _authRepository ??= AuthRepositoryImpl(
      mockAuthDataSource,
      authRemoteDataSource,
      identityAuthRemoteDataSource,
      secureStorageService,
      GoogleSignInService(),
    );
    return _authRepository!;
  }

  static EmailLoginUseCase get emailLoginUseCase =>
      EmailLoginUseCase(authRepository);

  static GoogleLoginUseCase get googleLoginUseCase =>
      GoogleLoginUseCase(authRepository);

  static DemoLoginUseCase get demoLoginUseCase =>
      DemoLoginUseCase(authRepository);

  static LogoutUseCase get logoutUseCase => LogoutUseCase(authRepository);

  static CheckAuthStatusUseCase get checkAuthStatusUseCase =>
      CheckAuthStatusUseCase(authRepository);

  static GetCurrentUserUseCase get getCurrentUserUseCase =>
      GetCurrentUserUseCase(authRepository);

  static RegisterUseCase get registerUseCase => RegisterUseCase(authRepository);

  static AuthCubit createAuthCubit() => AuthCubit(
    emailLoginUseCase: emailLoginUseCase,
    googleLoginUseCase: googleLoginUseCase,
    demoLoginUseCase: demoLoginUseCase,
    logoutUseCase: logoutUseCase,
    checkAuthStatusUseCase: checkAuthStatusUseCase,
    getCurrentUserUseCase: getCurrentUserUseCase,
    registerUseCase: registerUseCase,
    authRepository: authRepository,
  );

  static List<BlocProvider> get providers => [
    BlocProvider<AuthCubit>(
      create: (context) => createAuthCubit()..checkAuthStatus(),
    ),
  ];
}
