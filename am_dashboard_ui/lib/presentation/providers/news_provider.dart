import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/data/repositories/news_repository.dart';
import 'package:am_dashboard_ui/domain/models/news_models.dart';
import 'package:am_library/am_library.dart';
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

final newsInsightProvider = FutureProvider<InsightNews>((ref) async {
  if (!ref.watch(newsUiEnabledProvider)) {
    return const InsightNews();
  }
  final repo = await ref.watch(newsRepositoryProvider.future);
  final symbols = await repo.holdingsSymbols();
  return repo.insight(symbols);
});
