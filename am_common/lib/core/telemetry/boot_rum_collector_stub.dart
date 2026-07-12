import 'dart:async';

/// No-op boot RUM on non-web platforms.
class BootRumCollector {
  BootRumCollector._();
  static final BootRumCollector instance = BootRumCollector._();

  void schedulePublish({Duration delay = const Duration(seconds: 6)}) {}
}
