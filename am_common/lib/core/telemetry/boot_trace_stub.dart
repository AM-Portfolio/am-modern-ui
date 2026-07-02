import 'boot_trace.dart';

Map<String, int> get webMarks => const {};

void syncWebMarks(BootTrace trace) {}

void emitTelemetryEvent(
  String name,
  int delta,
  int total,
  Map<String, dynamic>? meta,
) {}

void publishSummary(Map<String, dynamic> json) {}
