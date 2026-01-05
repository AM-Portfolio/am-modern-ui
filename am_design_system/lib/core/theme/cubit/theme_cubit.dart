import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../theme_repository.dart';

enum AppThemeMode { system, light, dark, white }

class ThemeState {
  final AppThemeMode mode;
  
  const ThemeState(this.mode);

  ThemeMode get themeMode {
    switch (mode) {
      case AppThemeMode.dark:
        return ThemeMode.dark; 
      case AppThemeMode.light:
      case AppThemeMode.white:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  ThemeData get lightTheme {
    if (mode == AppThemeMode.white) {
      return AppTheme.whiteTheme;
    }
    return AppTheme.lightTheme;
  }
  
  ThemeData get darkTheme {
    return AppTheme.darkTheme;
  }
  
  /// Helper to check if current theme is dark
  bool get isDarkMode => mode == AppThemeMode.dark;
  
  /// Helper to check if current theme is light
  bool get isLightMode => mode == AppThemeMode.light || mode == AppThemeMode.white;
  
  ThemeState copyWith({AppThemeMode? mode}) {
    return ThemeState(mode ?? this.mode);
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  final ThemeRepository _repository;
  
  ThemeCubit(this._repository) : super(const ThemeState(AppThemeMode.system)) {
    _loadSavedTheme();
  }

  /// Load theme from persistent storage
  Future<void> _loadSavedTheme() async {
    final savedMode = await _repository.getThemeMode();
    if (savedMode != null) {
      final mode = _stringToThemeMode(savedMode);
      emit(ThemeState(mode));
    }
  }

  /// Set theme and persist it
  Future<void> setTheme(AppThemeMode mode) async {
    emit(ThemeState(mode));
    await _repository.saveThemeMode(_themeModeToString(mode));
  }
  
  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    final newMode = state.isDarkMode ? AppThemeMode.light : AppThemeMode.dark;
    await setTheme(newMode);
  }
  
  /// Convert AppThemeMode to string for storage
  String _themeModeToString(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'system';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.white:
        return 'white';
    }
  }
  
  /// Convert string to AppThemeMode
  AppThemeMode _stringToThemeMode(String mode) {
    switch (mode) {
      case 'system':
        return AppThemeMode.system;
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'white':
        return AppThemeMode.white;
      default:
        return AppThemeMode.system;
    }
  }
}
