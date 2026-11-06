import 'dart:convert';

import 'package:am_common/am_common.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'strategy_lab_models.dart';

/// HTTP client for Contabo dig / cluster Strategy Lab (`/strategy-lab`).
class StrategyLabClient {
  StrategyLabClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = _normalize(baseUrl ?? _resolveBaseUrl());

  static const _labFromDefine = String.fromEnvironment('AM_STRATEGY_LAB_BASE_URL');

  static String _resolveBaseUrl() {
    if (_labFromDefine.trim().isNotEmpty) return _labFromDefine.trim();
    return EnvDomains.strategyLab;
  }

  final http.Client _http;
  final String _baseUrl;

  static const _templateAssets = [
    'packages/am_paper_ui/assets/config/strategies/ZONE_SCALE.json',
    'packages/am_paper_ui/assets/config/strategies/LINE_LEVEL.json',
    'packages/am_paper_ui/assets/config/strategies/SUPER_BRACKET.json',
    'packages/am_paper_ui/assets/config/strategies/ORB.json',
    'packages/am_paper_ui/assets/config/strategies/VWAP_BOUNCE.json',
    'packages/am_paper_ui/assets/config/strategies/EMA_PULLBACK.json',
    'packages/am_paper_ui/assets/config/strategies/CPR_PIVOT.json',
    'packages/am_paper_ui/assets/config/strategies/MOMENTUM_GAP.json',
  ];

  static String _normalize(String url) {
    final t = url.trim();
    if (t.endsWith('/')) return t.substring(0, t.length - 1);
    return t;
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    try {
      final token = await SecureStorageService().getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
    return headers;
  }

  Future<dynamic> _get(String path) async {
    final res = await _http.get(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await _http.post(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final detail = body is Map ? (body['detail'] ?? body) : body;
    throw StrategyLabException(
      statusCode: res.statusCode,
      message: detail?.toString() ?? 'Strategy Lab HTTP ${res.statusCode}',
    );
  }

  Future<List<StrategyLabTemplate>> loadCatalogTemplates() async {
    final out = <StrategyLabTemplate>[];
    for (final asset in _templateAssets) {
      try {
        final raw = await rootBundle.loadString(asset);
        final json = jsonDecode(raw) as Map<String, dynamic>;
        out.add(StrategyLabTemplate.fromJson(json));
      } catch (_) {
        // Asset may be missing in some host packages — skip.
      }
    }
    if (out.isEmpty) {
      // Fallback when package asset path resolution differs.
      for (final name in const [
        'ZONE_SCALE',
        'LINE_LEVEL',
        'SUPER_BRACKET',
        'ORB',
      ]) {
        try {
          final raw = await rootBundle.loadString(
            'assets/config/strategies/$name.json',
          );
          out.add(
            StrategyLabTemplate.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            ),
          );
        } catch (_) {}
      }
    }
    return out;
  }

  Future<List<StrategyLabDoc>> listStrategies() async {
    final raw = await _get('/v1/strategies');
    final list = raw is List ? raw : const [];
    return list
        .whereType<Map>()
        .map((e) => StrategyLabDoc.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<StrategyLabDoc> upsertStrategy(Map<String, dynamic> body) async {
    final raw = await _post('/v1/strategies', body);
    return StrategyLabDoc.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  Future<BacktestJob> startBacktest({
    required String strategyId,
    required String symbol,
    required String from,
    required String to,
    String timeframe = '1d',
  }) async {
    final raw = await _post(
      '/v1/strategies/${Uri.encodeComponent(strategyId)}/backtests',
      {
        'symbol': symbol.trim().toUpperCase(),
        'from': from,
        'to': to,
        'timeframe': timeframe,
      },
    );
    return BacktestJob.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<BacktestJob> getJob(String jobId) async {
    final raw = await _get('/v1/backtests/${Uri.encodeComponent(jobId)}');
    return BacktestJob.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<BacktestReport> getReport(String jobId) async {
    final raw =
        await _get('/v1/backtests/${Uri.encodeComponent(jobId)}/report');
    return BacktestReport.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  /// Upsert → start → poll until DONE/FAILED → fetch report when DONE.
  Future<({BacktestJob job, BacktestReport? report})> runBacktestAndWait({
    required Map<String, dynamic> upsertBody,
    required String symbol,
    required String from,
    required String to,
    String timeframe = '1d',
    Duration pollEvery = const Duration(milliseconds: 400),
    int maxPolls = 90,
  }) async {
    await upsertStrategy(upsertBody);
    final sid = (upsertBody['strategyId'] ?? '').toString();
    var job = await startBacktest(
      strategyId: sid,
      symbol: symbol,
      from: from,
      to: to,
      timeframe: timeframe,
    );
    for (var i = 0; i < maxPolls && !job.isTerminal; i++) {
      await Future<void>.delayed(pollEvery);
      job = await getJob(job.jobId);
    }
    if (job.status == 'DONE') {
      final report = await getReport(job.jobId);
      return (job: job, report: report);
    }
    return (job: job, report: null);
  }
}

class StrategyLabException implements Exception {
  StrategyLabException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'StrategyLabException($statusCode): $message';
}
