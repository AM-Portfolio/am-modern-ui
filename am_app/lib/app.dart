import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_common/am_common.dart' as common;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/router/auth_refresh_listenable.dart';

/// Main Application Widget
class AMApp extends ConsumerStatefulWidget {
  const AMApp({super.key});

  @override
  ConsumerState<AMApp> createState() => _AMAppState();
}

class _AMAppState extends ConsumerState<AMApp> {
  late final AuthCubit _authCubit;
  late final AuthRefreshListenable _authRefresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = getIt<AuthCubit>()..checkAuthStatus();
    _authRefresh = AuthRefreshListenable(_authCubit);
    _router = createAppRouter(
      authCubit: _authCubit,
      refreshListenable: _authRefresh,
    );
  }

  @override
  void dispose() {
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
        listenWhen: (prev, curr) => curr is Authenticated,
        listener: (context, state) {
          if (state is Authenticated) {
            common.SessionPersistenceService.instance.load(state.user.id);
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
