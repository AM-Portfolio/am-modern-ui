import 'config_service.dart';

/// Demo login visibility and credentials for local prod testing.
///
/// Enabled via `AM_DEMO_LOGIN_ENABLED` in `.env.prod` (manage.py dart-defines).
/// Docker release builds do not set that flag. Even if baked in, demo login only
/// appears when the app runs on localhost.
class DemoLoginConfig {
  DemoLoginConfig._();

  static const _defaultEmail = 'munish.prime@gmail.com';
  static const _defaultPassword = '@M1unish';

  static const _enabledFromEnv = bool.fromEnvironment(
    'AM_DEMO_LOGIN_ENABLED',
    defaultValue: false,
  );
  static const _emailFromEnv = String.fromEnvironment(
    'AM_DEMO_EMAIL',
    defaultValue: '',
  );
  static const _passwordFromEnv = String.fromEnvironment(
    'AM_DEMO_PASSWORD',
    defaultValue: '',
  );

  static String get email =>
      _emailFromEnv.isNotEmpty ? _emailFromEnv : _defaultEmail;

  static String get password =>
      _passwordFromEnv.isNotEmpty ? _passwordFromEnv : _defaultPassword;

  static bool _isLocalHost() {
    final host = Uri.base.host.toLowerCase();
    return host.isEmpty || host == 'localhost' || host == '127.0.0.1';
  }

  /// Show the login-page developer section (demo login at minimum).
  static bool get isDevSectionVisible {
    if (ConfigService.resolvedEnv == 'dev') return true;
    return _enabledFromEnv && _isLocalHost();
  }

  /// Feature-flag panel is dev-only; not shown for local prod testing.
  static bool get isDeveloperPanelVisible =>
      ConfigService.resolvedEnv == 'dev';
}
