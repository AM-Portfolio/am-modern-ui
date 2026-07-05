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
  external set rum(String? value);
}

@JS('performance.getEntriesByType')
external JSArray _getEntriesByType(JSString type);

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

bool isReloadNavigation() {
  try {
    final entries = _getEntriesByType('navigation'.toJS).dartify();
    if (entries is! List || entries.isEmpty) return false;
    final nav = entries.first;
    if (nav is! Map) return false;
    return nav['type']?.toString() == 'reload';
  } catch (_) {
    return false;
  }
}

Map<String, dynamic> collectResourceMetrics() {
  var mainDartJsMs = 0;
  var canvaskitMs = 0;
  var totalTransferMs = 0;
  var mainDartJsCached = false;
  var canvaskitCached = false;

  try {
    final entries = _getEntriesByType('resource'.toJS).dartify();
    if (entries is List) {
      for (final raw in entries) {
        if (raw is! Map) continue;
        final name = raw['name']?.toString() ?? '';
        final duration = ((raw['duration'] as num?) ?? 0).toInt();
        final transfer = ((raw['transferSize'] as num?) ?? 0).toInt();
        final encoded = ((raw['encodedBodySize'] as num?) ?? 0).toInt();
        final fromCache = transfer == 0 && encoded > 0;

        totalTransferMs += duration;

        if (name.contains('main.dart.js')) {
          mainDartJsMs = duration;
          mainDartJsCached = fromCache;
        } else if (name.contains('canvaskit') && name.endsWith('.wasm')) {
          canvaskitMs += duration;
          if (fromCache) canvaskitCached = true;
        }
      }
    }
  } catch (_) {}

  return {
    'mainDartJsMs': mainDartJsMs,
    'canvaskitMs': canvaskitMs,
    'totalTransferMs': totalTransferMs,
    'cacheHit': {
      'mainDartJs': mainDartJsCached,
      'canvaskit': canvaskitCached,
    },
  };
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
  } catch (_) {}
}

void publishRumSummary(Map<String, dynamic> json) {
  try {
    final holder = _holder;
    if (holder != null) {
      holder.rum = jsonEncode(json);
    }
  } catch (_) {}
}
