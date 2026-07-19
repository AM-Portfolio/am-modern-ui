import 'dart:async';
import 'dart:convert';

import 'package:am_library/am_library.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'boot_trace.dart';
import 'boot_trace_web.dart' as web;

/// Real-user boot metrics — always on web when [AM_BOOT_RUM] is true (default).
class BootRumCollector {
  BootRumCollector._();
  static final BootRumCollector instance = BootRumCollector._();

  static const _envFromDefine = String.fromEnvironment('AM_ENV');
  static const _buildIdFromDefine = String.fromEnvironment(
    'AM_BUILD_ID',
    defaultValue: 'local',
  );

  bool _published = false;

  void schedulePublish({Duration delay = const Duration(seconds: 6)}) {
    if (!BootTrace.enabled) return;
    Future<void>.delayed(delay, _publish);
  }

  void _publish() {
    if (_published) return;
    _published = true;

    final trace = BootTrace.instance.toJson();
    final marks = Map<String, int>.from(
      (trace['marks'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      ),
    );
    final webMarks = Map<String, int>.from(
      (trace['webMarks'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      ),
    );

    final resources = web.collectResourceMetrics();
    final buckets = _classifyBuckets(marks, webMarks, resources);
    final slowest = _slowestPhase(marks, resources);

    final summary = <String, dynamic>{
      'buildId': _buildIdFromDefine,
      'env': _envFromDefine.isNotEmpty ? _envFromDefine : 'unknown',
      'path': Uri.base.path,
      'isReload': web.isReloadNavigation(),
      'buckets': buckets,
      'phases': marks,
      'resources': resources,
      'slowestPhase': slowest,
      'totalMs': trace['totalMs'],
    };

    web.publishRumSummary(summary);

    if (kDebugMode || _envFromDefine == 'preprod') {
      debugPrint('[BootRUM] ${jsonEncode(summary)}');
    }

    _emitSummaryEvent(summary);
    ProductTelemetry.instance.bootRum(summary);
  }

  Map<String, int> _classifyBuckets(
    Map<String, int> marks,
    Map<String, int> webMarks,
    Map<String, dynamic> resources,
  ) {
    final htmlMs = webMarks['html_loaded'] ?? 0;
    final dartReady = webMarks['flutter_dart_ready'] ?? marks['flutter_main_enter'] ?? 0;
    final configDone = marks['config_done'] ?? dartReady;
    final authDone = marks['auth_check_done'] ?? configDone;
    final shellVisible = marks['shell_visible'] ?? authDone;
    final firstData = marks['dashboard_first_data'] ?? shellVisible;

    final networkMs = (resources['totalTransferMs'] as num?)?.toInt() ??
        (resources['mainDartJsMs'] as num? ?? 0).toInt() +
            (resources['canvaskitMs'] as num? ?? 0).toInt() +
            htmlMs;

    return {
      'networkMs': networkMs,
      'engineMs': (dartReady - htmlMs).clamp(0, 600000),
      'appBootMs': (shellVisible - dartReady).clamp(0, 600000),
      'dataMs': (firstData - shellVisible).clamp(0, 600000),
    };
  }

  String _slowestPhase(
    Map<String, int> marks,
    Map<String, dynamic> resources,
  ) {
    final candidates = <String, int>{
      if ((resources['canvaskitMs'] as num? ?? 0) > 0)
        'canvaskit_download': (resources['canvaskitMs'] as num).toInt(),
      if ((resources['mainDartJsMs'] as num? ?? 0) > 0)
        'main_dart_js_download': (resources['mainDartJsMs'] as num).toInt(),
      ...marks.map((k, v) => MapEntry(k, v)),
    };
    if (candidates.isEmpty) return 'unknown';
    return candidates.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  void _emitSummaryEvent(Map<String, dynamic> summary) {
    if (!GetIt.instance.isRegistered<TelemetryService>()) return;
    GetIt.instance<TelemetryService>().record(
      TelemetryEvent(
        type: TelemetryType.wsStatus,
        category: 'Boot',
        label: 'boot_summary',
        duration: Duration(milliseconds: (summary['totalMs'] as num?)?.toInt() ?? 0),
        metadata: summary,
      ),
    );
  }
}
