import 'dart:convert';
import 'dart:js_interop';

import 'package:am_library/am_library.dart';
import 'package:get_it/get_it.dart';

import 'boot_trace.dart';

@JS('window.__AM_BOOT_TRACE__')
external _BootTraceHolder? get _holder;

extension type _BootTraceHolder._(JSObject _) implements JSObject {
  external JSObject? get marks;
  external set summary(String? value);
}

Map<String, int> get webMarks {
  try {
    final holder = _holder;
    final marksObj = holder?.marks;
    if (marksObj == null) return const {};
    final dartified = marksObj.dartify();
    if (dartified is! Map) return const {};
    return dartified.map(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    );
  } catch (_) {
    return const {};
  }
}

void syncWebMarks(BootTrace trace) {
  for (final entry in webMarks.entries) {
    if (entry.key == 'html_loaded' || entry.key == 'flutter_dart_ready') {
      trace.mark('web_${entry.key}', meta: {'elapsedMs': entry.value});
    }
  }
}

void emitTelemetryEvent(
  String name,
  int delta,
  int total,
  Map<String, dynamic>? meta,
) {
  if (!GetIt.instance.isRegistered<TelemetryService>()) return;
  GetIt.instance<TelemetryService>().record(
    TelemetryEvent(
      type: TelemetryType.wsStatus,
      category: 'Boot',
      label: name,
      duration: Duration(milliseconds: delta),
      metadata: {
        'totalMs': total,
        if (meta != null) ...meta,
      },
    ),
  );
}

void publishSummary(Map<String, dynamic> json) {
  try {
    final holder = _holder;
    if (holder != null) {
      holder.summary = jsonEncode(json);
    }
  } catch (_) {
    // Ignore if JS object is unavailable.
  }
}
