import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_common/am_common.dart' as common;
import 'package:am_library/am_library.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/router/auth_refresh_listenable.dart';
import 'core/router/product_telemetry_observer.dart';

/// Main Application Widget
class AMApp extends ConsumerStatefulWidget {
  const AMApp({super.key, this.launchUri});

  /// Browser URL captured at process start (before bootstrap UI mounts).
  final Uri? launchUri;

  @override
  ConsumerState<AMApp> createState() => _AMAppState();
}

class _AMAppState extends ConsumerState<AMApp> {
  late final AuthCubit _authCubit;
  late final AuthRefreshListenable _authRefresh;
  late final GoRouter _router;
  VoidCallback? _detachRouteListener;
  FlutterExceptionHandler? _previousFlutterOnError;
  bool Function(Object, StackTrace)? _previousPlatformOnError;

  @override
  void initState() {
    super.initState();
    _authCubit = getIt<AuthCubit>();
    // Verify/reset deep links own session setup. Running restore in parallel
    // can emit Unauthenticated after confirm and bounce the user to login.
    final launchPath = AppRoutes.normalizePath(
      widget.launchUri?.path.isEmpty == false
          ? widget.launchUri!.path
          : '/',
    );
    final skipSessionRestore = launchPath == AppRoutes.verifyEmail ||
        launchPath == AppRoutes.resetPassword;
    if (!skipSessionRestore) {
      _authCubit.checkAuthStatus();
    }
    _authRefresh = AuthRefreshListenable(_authCubit);
    _router = createAppRouter(
      authCubit: _authCubit,
      refreshListenable: _authRefresh,
      launchUri: widget.launchUri,
    );
    _detachRouteListener = attachProductTelemetryRouteListener(_router);
    CommonLogger.onUserAction = (action, {tag, metadata}) {
      ProductTelemetry.instance.featureAction(
        action,
        tag: tag,
        metadata: metadata,
      );
    };
    _previousFlutterOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      _previousFlutterOnError?.call(details);
      ProductTelemetry.instance.clientError(
        errorType: details.exception.runtimeType.toString(),
      );
    };
    _previousPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      ProductTelemetry.instance.clientError(
        errorType: error.runtimeType.toString(),
      );
      return _previousPlatformOnError?.call(error, stack) ?? false;
    };
  }

  @override
  void dispose() {
    _detachRouteListener?.call();
    CommonLogger.onUserAction = null;
    FlutterError.onError = _previousFlutterOnError;
    PlatformDispatcher.instance.onError = _previousPlatformOnError;
    _authRefresh.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<ThemeCubit>(
          create: (context) => getIt<ThemeCubit>(),
        ),
        BlocProvider<common.StompConnectionCubit>(
          create: (context) => getIt<common.StompConnectionCubit>(),
        ),
        BlocProvider<FeatureFlagCubit>(
          create: (context) => getIt<FeatureFlagCubit>(),
        ),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (prev, curr) =>
            curr is Authenticated ||
            (prev is Authenticated && curr is! Authenticated),
        listener: (context, state) {
          if (state is Authenticated) {
            common.SessionPersistenceService.instance.load(state.user.id);
            ProductTelemetry.instance.sessionStart();
          } else {
            ProductTelemetry.instance.authLogout();
          }
        },
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp.router(
              title: 'AM Investment Platform',
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
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }
}
