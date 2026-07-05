import 'boot_trace.dart';

Map<String, int> get webMarks => const {};

void syncWebMarks(BootTrace trace) {}

bool isReloadNavigation() => false;

Map<String, dynamic> collectResourceMetrics() => const {};

void emitTelemetryEvent(
  String name,
  int delta,
  int total,
  Map<String, dynamic>? meta,
) {}

void publishSummary(Map<String, dynamic> json) {}

void publishRumSummary(Map<String, dynamic> json) {}
