enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment _current = Environment.development;
  static final List<Function(Environment)> _listeners = [];

  static Environment get current => _current;

  static void setCurrent(Environment env) {
    _current = env;
    _notifyListeners(env);
  }

  static void addListener(Function(Environment) listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function(Environment) listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners(Environment env) {
    for (final listener in _listeners) {
      listener(env);
    }
  }
}
