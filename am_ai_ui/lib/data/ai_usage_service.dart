import 'package:dio/dio.dart';
import 'package:am_common/am_common.dart' as common;

/// Token usage snapshot for the AI chat header chip.
class AiTokenUsage {
  final int used;
  final int limit;
  final int remaining;

  const AiTokenUsage({
    required this.used,
    required this.limit,
    required this.remaining,
  });

  static const empty = AiTokenUsage(used: 0, limit: 0, remaining: 0);

  bool get hasLimit => limit > 0;

  double get fractionUsed {
    if (!hasLimit) return 0;
    return (used / limit).clamp(0.0, 1.0);
  }

  /// Whole-number fill percent for the circular usage control.
  int get percentFull => (fractionUsed * 100).round();

  String get percentLabel => hasLimit ? '$percentFull%' : '—';

  String get chipLabel {
    if (!hasLimit) return '— tokens';
    return '${_fmt(used)} / ${_fmt(limit)} tokens';
  }

  /// Compact line for the usage popover (e.g. `42k / 100k Tokens`).
  String get detailTokensLabel {
    if (!hasLimit) return '— Tokens';
    return '${_fmt(used)} / ${_fmt(limit)} Tokens';
  }

  /// Same as [detailTokensLabel] with leading tilde on used count (Cursor-style).
  String get detailTokensLabelTilde {
    if (!hasLimit) return '— Tokens';
    return '~${_fmt(used)} / ${_fmt(limit)} Tokens';
  }

  String get remainingLabel {
    if (!hasLimit) return '— remaining';
    return '${_fmt(remaining)} remaining';
  }

  /// Public formatter for UI breakdown rows.
  static String formatCount(int n) => _fmt(n);

  static String _fmt(int n) {
    if (n >= 1000000) {
      final v = n / 1000000;
      return v == v.roundToDouble() ? '${v.toInt()}M' : '${v.toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      final v = n / 1000;
      return v == v.roundToDouble() ? '${v.toInt()}k' : '${v.toStringAsFixed(1)}k';
    }
    return '$n';
  }
}

/// Reads `ai_chat_tokens` from `GET /subscriptions/me` (prod via EnvDomains).
class AiUsageService {
  /// Same host root as [am_subscription_ui] Dio — strip `/subscriptions` suffix
  /// so paths like `/subscriptions/me` resolve correctly.
  static String get baseUrl {
    var domain = common.EnvDomains.subscription.trim();
    if (domain.endsWith('/subscriptions/')) {
      domain = domain.substring(0, domain.length - '/subscriptions/'.length);
    } else if (domain.endsWith('/subscriptions')) {
      domain = domain.substring(0, domain.length - '/subscriptions'.length);
    }
    return domain.endsWith('/') ? domain : '$domain/';
  }

  final Dio _dio;

  AiUsageService(this._dio);

  Future<AiTokenUsage> fetchAiChatTokens() async {
    final response = await _dio.get('/subscriptions/me');
    final body = response.data;
    Map<String, dynamic> data;
    if (body is Map && body['data'] is Map) {
      data = Map<String, dynamic>.from(body['data'] as Map);
    } else if (body is Map) {
      data = Map<String, dynamic>.from(body);
    } else {
      return AiTokenUsage.empty;
    }

    final usage = data['usage'];
    if (usage is List) {
      for (final item in usage) {
        if (item is! Map) continue;
        final code = (item['metric_code'] ?? item['metricCode'] ?? '').toString();
        if (code != 'ai_chat_tokens') continue;
        final used = (item['used'] as num?)?.toInt() ?? 0;
        final limit = (item['limit'] as num?)?.toInt() ?? 0;
        final remaining = (item['remaining'] as num?)?.toInt() ?? (limit - used);
        return AiTokenUsage(used: used, limit: limit, remaining: remaining);
      }
    }

    final limits = data['limits'];
    if (limits is Map) {
      final limit = (limits['ai_chat_tokens'] as num?)?.toInt() ??
          (limits['aiChatTokens'] as num?)?.toInt() ??
          0;
      if (limit > 0) {
        return AiTokenUsage(used: 0, limit: limit, remaining: limit);
      }
    }
    return AiTokenUsage.empty;
  }
}
