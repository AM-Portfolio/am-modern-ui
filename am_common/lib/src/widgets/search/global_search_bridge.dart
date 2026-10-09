/// AppShell registers [open] so feature modules can open Global Search
/// without importing am_app.
class GlobalSearchBridge {
  GlobalSearchBridge._();

  static void Function()? open;

  static bool tryOpen() {
    final fn = open;
    if (fn == null) return false;
    fn();
    return true;
  }
}
