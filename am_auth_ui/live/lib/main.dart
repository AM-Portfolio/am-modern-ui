import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:get_it/get_it.dart';

void main() {
  // Initialize DI
  final storage = SecureStorageService();
  GetIt.I.registerSingleton<SecureStorageService>(storage);

  runApp(
    MultiBlocProvider(
      providers: [
        ...AuthProviders.providers,
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(ThemeRepository()),
        ),
      ],
      child: const AuthExampleApp(),
    ),
  );
}

class AuthExampleApp extends StatelessWidget {
  const AuthExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth UI Example',
      theme: AppTheme.darkTheme,
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
