import 'package:am_common/am_common.dart';
import 'package:am_news_ui/domain/models/news_models.dart';
import 'package:am_library/am_library.dart';

class NewsRepository {
  NewsRepository({
    required ApiClient newsClient,
    required ApiClient portfolioClient,
    required this.holdingsResource,
    this.timeout = const Duration(milliseconds: 15000),
  })  : _newsClient = newsClient,
        _portfolioClient = portfolioClient;

  final ApiClient _newsClient;
  final ApiClient _portfolioClient;
  final String holdingsResource;
  final Duration timeout;

  static const insightPath = '/v1/insight';
  static const adminFeedPath = '/v1/admin/feed/start';

  Future<List<String>> holdingsSymbols({int cap = 80}) async {
    try {
      final raw = await _portfolioClient.get(
        holdingsResource,
        timeout: timeout,
        parser: (data) {
          if (data is Map) return Map<String, dynamic>.from(data);
          return <String, dynamic>{};
        },
      );
      final equity = raw['equityHoldings'];
      if (equity is! List) return const [];
      final seen = <String>{};
      final out = <String>[];
      for (final row in equity) {
        if (row is! Map) continue;
        final symbol = (row['symbol'] as String? ?? '').trim().toUpperCase();
        if (symbol.isEmpty || seen.contains(symbol)) continue;
        seen.add(symbol);
        out.add(symbol);
        if (out.length >= cap) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<InsightNews> insight(List<String> symbols) async {
    final data = await _newsClient.post(
      insightPath,
      body: {'symbols': symbols},
      timeout: timeout,
      parser: (raw) {
        if (raw is! Map) return <String, dynamic>{};
        final map = Map<String, dynamic>.from(raw);
        final nested = map['data'];
        if (nested is Map &&
            (nested.containsKey('current_affairs') ||
                nested.containsKey('holdings') ||
                nested.containsKey('currentAffairs'))) {
          return Map<String, dynamic>.from(nested);
        }
        return map;
      },
    );
    return InsightNews.fromJson(data);
  }
}
