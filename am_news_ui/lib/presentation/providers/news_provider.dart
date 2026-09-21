import 'package:am_common/am_common.dart';
import 'package:am_library/am_library.dart';
import 'package:am_news_ui/data/repositories/news_repository.dart';
import 'package:am_news_ui/domain/models/news_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newsRepositoryProvider = FutureProvider<NewsRepository>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  final newsBase = config.api.news?.baseUrl ?? EnvDomains.news;
  return NewsRepository(
    newsClient: ApiClient(baseUrl: newsBase),
    portfolioClient: ApiClient(baseUrl: config.api.portfolio.baseUrl),
    holdingsResource: config.api.portfolio.holdingsResource,
  );
});

/// Dashboard: holdings symbols from portfolio API + insight (affairs + holdings).
final newsInsightProvider = FutureProvider<InsightNews>((ref) async {
  if (!ref.watch(newsUiSurfaceEnabledProvider(NewsUiSurface.dashboard))) {
    return const InsightNews();
  }
  final repo = await ref.watch(newsRepositoryProvider.future);
  final symbols = await repo.holdingsSymbols();
  return repo.insight(symbols);
});

String _symbolsKey(List<String> symbols) {
  final normalized = symbols
      .map((s) => s.trim().toUpperCase())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return normalized.join(',');
}

/// Insight for an explicit symbol list (host supplies symbols).
final newsInsightForSymbolsProvider =
    FutureProvider.family<InsightNews, String>((ref, key) async {
  if (key.isEmpty) return const InsightNews();
  final repo = await ref.watch(newsRepositoryProvider.future);
  final symbols = key.split(',').where((s) => s.isNotEmpty).toList();
  return repo.insight(symbols);
});

/// Helper for hosts: stable family key from symbols.
String newsSymbolsProviderKey(List<String> symbols) => _symbolsKey(symbols);
