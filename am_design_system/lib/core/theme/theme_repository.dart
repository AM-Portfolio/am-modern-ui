import 'package:shared_preferences/shared_preferences.dart';

/// Repository for persisting theme preferences
class ThemeRepository {
  static const String _themeKey = 'app_theme_mode';
  
  /// Get the saved theme mode
  /// Returns null if no theme has been saved
  Future<String?> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_themeKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Save the theme mode
  Future<bool> saveThemeMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_themeKey, mode);
    } catch (e) {
      return false;
    }
  }
  
  /// Clear the saved theme mode
  Future<bool> clearThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_themeKey);
    } catch (e) {
      return false;
    }
  }
}
