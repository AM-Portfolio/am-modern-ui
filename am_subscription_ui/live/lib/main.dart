import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:am_common/am_common.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_subscription_ui/am_subscription_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dynamic environment and configuration
  await ConfigService.initialize();

  // Initialize and register Secure Storage
  final storage = SecureStorageService();
  GetIt.I.registerSingleton<SecureStorageService>(storage);

  // Configure authenticated Dio client targeting subscription service base URL
  String baseUrl = EnvDomains.subscription;
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
  subscriptionDio.interceptors.add(AuthInterceptor(storage));
  
  // Register named Dio client
  GetIt.I.registerSingleton<Dio>(subscriptionDio, instanceName: 'subscriptionDio');

  // Register remote data sources and cubit
  final remoteDataSource = SubscriptionRemoteDataSourceImpl(
    GetIt.I<Dio>(instanceName: 'subscriptionDio'),
  );
  GetIt.I.registerSingleton<SubscriptionRemoteDataSource>(remoteDataSource);

  final subscriptionCubit = SubscriptionCubit(remoteDataSource);
  GetIt.I.registerSingleton<SubscriptionCubit>(subscriptionCubit);

  runApp(
    MultiBlocProvider(
      providers: [
        ...AuthProviders.providers,
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(ThemeRepository()),
        ),
        BlocProvider<SubscriptionCubit>(
          create: (context) => GetIt.I<SubscriptionCubit>(),
        ),
      ],
      child: const SubscriptionExampleApp(),
    ),
  );
}

class SubscriptionExampleApp extends StatelessWidget {
  const SubscriptionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          title: 'Subscription UI Standalone',
          theme: themeState.lightTheme,
          darkTheme: themeState.darkTheme,
          themeMode: themeState.themeMode,
          home: const AuthWrapper(
            child: SubscriptionPricingScreen(),
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
