import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'boot_trace_platform.dart' as platform;

/// Startup performance tracing.
///
/// - **Recording** (marks + RUM): always on web builds when [AM_BOOT_RUM] is true (default).
/// - **Verbose console**: `?bootTrace=1` or `--dart-define=AM_BOOT_TRACE=true`.
class BootTrace {
  BootTrace._();

  static final BootTrace instance = BootTrace._();

  static const _bootTraceFromDefine = bool.fromEnvironment('AM_BOOT_TRACE');
  static const _bootRumFromDefine = bool.fromEnvironment(
    'AM_BOOT_RUM',
    defaultValue: true,
  );

  static bool _verbose = false;
  static bool _recording = false;
  static bool _summaryPrinted = false;

  final Stopwatch _sw = Stopwatch();
  final Map<String, int> _marks = {};
  final Map<String, int> _deltas = {};
  final Map<String, Map<String, dynamic>> _meta = {};
  int _lastTotal = 0;

  static bool get enabled => _recording;
  static bool get verbose => _verbose;

  /// Call once at app entry (before [runApp]).
  static void configure({bool? forceEnabled}) {
    if (forceEnabled != null) {
      _verbose = forceEnabled;
      _recording = forceEnabled;
    } else {
      _verbose = _bootTraceFromDefine ||
          Uri.base.queryParameters['bootTrace'] == '1';
      _recording = _verbose ||
          (_bootRumFromDefine && kIsWeb);
    }

    if (!_recording) return;

    instance._sw.start();
    platform.syncWebMarks(instance);
    instance.mark('flutter_main_enter');
  }

  void mark(String name, {Map<String, dynamic>? meta}) {
    if (!_recording) return;

    final elapsed = _sw.elapsedMilliseconds;
    final delta = elapsed - _lastTotal;
    _lastTotal = elapsed;
    _marks[name] = elapsed;
    _deltas[name] = delta;
    if (meta != null && meta.isNotEmpty) {
      _meta[name] = Map<String, dynamic>.from(meta);
    }

    if (_verbose) {
      final metaSuffix =
          meta != null && meta.isNotEmpty ? ' ${jsonEncode(meta)}' : '';
      debugPrint(
        '[BootTrace] +${delta}ms → $name (total ${elapsed}ms)$metaSuffix',
      );
    }

    _emitTelemetry(name, delta, elapsed, meta);
  }

  void _emitTelemetry(
    String name,
    int delta,
    int total,
    Map<String, dynamic>? meta,
  ) {
    try {
      platform.emitTelemetryEvent(name, delta, total, meta);
    } catch (_) {
      // Telemetry not ready yet during early boot.
    }
  }

  Map<String, dynamic> toJson() => {
        'totalMs': _sw.elapsedMilliseconds,
        'marks': Map<String, int>.from(_marks),
        'deltas': Map<String, int>.from(_deltas),
        if (_meta.isNotEmpty) 'meta': _meta,
        if (platform.webMarks.isNotEmpty) 'webMarks': platform.webMarks,
      };

  void printSummary() {
    if (!_recording || _summaryPrinted || !_verbose) return;
    _summaryPrinted = true;

    final buffer = StringBuffer('\n══════ AM Boot Trace Summary ══════\n');
    buffer.writeln(
      '${'Phase'.padRight(28)} ${'Delta'.padLeft(8)} ${'Total'.padLeft(8)}',
    );
    buffer.writeln('─' * 48);

    var slowestName = '';
    var slowestDelta = 0;
    for (final entry in _deltas.entries) {
      if (entry.value > slowestDelta) {
        slowestDelta = entry.value;
        slowestName = entry.key;
      }
    }
    for (final entry in _deltas.entries) {
      final flag = entry.key == slowestName ? ' ⚠' : '';
      buffer.writeln(
        '${entry.key.padRight(28)} '
        '${'${entry.value}ms'.padLeft(8)} '
        '${'${_marks[entry.key] ?? 0}ms'.padLeft(8)}$flag',
      );
    }

    buffer.writeln('─' * 48);
    buffer.writeln('Total boot: ${_sw.elapsedMilliseconds}ms');
    if (slowestName.isNotEmpty) {
      buffer.writeln('Slowest phase: $slowestName (+${slowestDelta}ms)');
    }
    buffer.writeln('════════════════════════════════════');

    debugPrint(buffer.toString());
    platform.publishSummary(toJson());
  }

  /// Schedule verbose summary after the last expected milestone.
  void scheduleSummary({Duration delay = const Duration(milliseconds: 150)}) {
    if (!_verbose) return;
    Future<void>.delayed(delay, printSummary);
  }
}
