import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../module/module_config.dart';
import '../app_theme.dart';
import '../theme_repository.dart';

enum AppThemeMode {
  system,
  light,
  dark,
  white,
  skyBlue,
  imperialGold,
  cyberNeon,
}

class ThemeState {
  final AppThemeMode mode;

  const ThemeState(this.mode);

  ThemeMode get themeMode {
    switch (mode) {
      case AppThemeMode.dark:
      case AppThemeMode.imperialGold:
      case AppThemeMode.cyberNeon:
        return ThemeMode.dark;
      case AppThemeMode.light:
      case AppThemeMode.white:
      case AppThemeMode.skyBlue:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  ThemeData get lightTheme {
    if (mode == AppThemeMode.white) {
      return AppTheme.whiteTheme;
    }
    if (mode == AppThemeMode.skyBlue) {
      return AppTheme.skyBlueTheme;
    }
    return AppTheme.lightTheme;
  }

  ThemeData get darkTheme {
    switch (mode) {
      case AppThemeMode.imperialGold:
        return AppTheme.imperialGoldTheme;
      case AppThemeMode.cyberNeon:
        return AppTheme.cyberNeonTheme;
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      default:
        return AppTheme.darkTheme;
    }
  }

  bool get isDarkMode =>
      mode == AppThemeMode.dark ||
      mode == AppThemeMode.imperialGold ||
      mode == AppThemeMode.cyberNeon;

  bool get isLightMode =>
      mode == AppThemeMode.light ||
      mode == AppThemeMode.white ||
      mode == AppThemeMode.skyBlue;

  /// Default AM look keeps distinct module colors; brand themes sync all accents.
  bool get keepsMulticolorModules {
    switch (mode) {
      case AppThemeMode.system:
      case AppThemeMode.light:
      case AppThemeMode.dark:
      case AppThemeMode.white:
        return true;
      case AppThemeMode.skyBlue:
      case AppThemeMode.imperialGold:
      case AppThemeMode.cyberNeon:
        return false;
    }
  }

  Color get brandAccent {
    switch (mode) {
      case AppThemeMode.skyBlue:
        return const Color(0xFF0288D1);
      case AppThemeMode.imperialGold:
        return const Color(0xFFC9A84C); // gin golden
      case AppThemeMode.cyberNeon:
        return const Color(0xFFE879F9);
      case AppThemeMode.dark:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6C5DD3);
    }
  }

  ThemeState copyWith({AppThemeMode? mode}) {
    return ThemeState(mode ?? this.mode);
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  final ThemeRepository _repository;

  ThemeCubit(this._repository) : super(const ThemeState(AppThemeMode.system)) {
    _syncModuleAccents(state);
    _loadSavedTheme();
  }

  void _syncModuleAccents(ThemeState themeState) {
    ModuleColors.applyBrandSync(
      multicolor: themeState.keepsMulticolorModules,
      brand: themeState.brandAccent,
    );
  }

  Future<void> _loadSavedTheme() async {
    final savedMode = await _repository.getThemeMode();
    if (savedMode != null) {
      final mode = _stringToThemeMode(savedMode);
      final next = ThemeState(mode);
      _syncModuleAccents(next);
      emit(next);
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final next = ThemeState(mode);
    _syncModuleAccents(next);
    emit(next);
    await _repository.saveThemeMode(_themeModeToString(mode));
  }

  Future<void> toggleTheme() async {
    final newMode = state.isDarkMode ? AppThemeMode.light : AppThemeMode.dark;
    await setTheme(newMode);
  }

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
      case AppThemeMode.skyBlue:
        return 'skyBlue';
      case AppThemeMode.imperialGold:
        return 'imperialGold';
      case AppThemeMode.cyberNeon:
        return 'cyberNeon';
    }
  }

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
      case 'skyBlue':
        return AppThemeMode.skyBlue;
      case 'imperialGold':
        return AppThemeMode.imperialGold;
      case 'cyberNeon':
        return AppThemeMode.cyberNeon;
      default:
        return AppThemeMode.system;
    }
  }
}
