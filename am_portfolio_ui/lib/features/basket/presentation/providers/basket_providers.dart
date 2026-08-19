import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';

import '../../domain/models/basket_catalog.dart';
import '../../domain/models/basket_opportunity.dart';
import '../../domain/models/tracking_basket.dart';
import '../../domain/repositories/basket_repository.dart';
import '../../data/repositories/basket_repository_impl.dart';
import '../../data/datasources/basket_remote_data_source.dart';
import '../../../portfolio/providers/portfolio_providers.dart';
import '../../domain/services/basket_recommendation_service.dart';

part 'basket_providers.g.dart';

@riverpod
Future<BasketRepository> basketRepository(Ref ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final remoteDataSource = BasketRemoteDataSourceImpl(apiClient: apiClient);
  return BasketRepositoryImpl(remoteDataSource: remoteDataSource);
}

@riverpod
Future<BasketCatalog> basketCatalog(Ref ref) async {
  final repository = await ref.watch(basketRepositoryProvider.future);
  return repository.getCatalog();
}

@riverpod
Future<List<BasketOpportunity>> basketOpportunities(
  Ref ref, {
  required String userId,
  required String portfolioId,
  String? query,
}) async {
  final repository = await ref.watch(basketRepositoryProvider.future);
  return repository.getOpportunities(
    userId: userId,
    portfolioId: portfolioId,
    query: query,
  );
}

@riverpod
Future<BasketOpportunity> basketPreview(
  Ref ref, {
  required String etfIsin,
  required String userId,
  required String portfolioId,
}) async {
  final repository = await ref.watch(basketRepositoryProvider.future);
  return repository.getBasketPreview(
    etfIsin: etfIsin,
    userId: userId,
    portfolioId: portfolioId,
  );
}

@riverpod
Future<BasketOpportunity> applySubstitutes(
  Ref ref, {
  required Map<String, dynamic> request,
}) async {
  final repository = await ref.watch(basketRepositoryProvider.future);
  return repository.applySubstitutes(request);
}

@riverpod
Future<List<TrackingBasket>> myBaskets(
  Ref ref, {
  required String userId,
  required String portfolioId,
}) async {
  final repository = await ref.watch(basketRepositoryProvider.future);
  return repository.getMyBaskets(
    userId: userId,
    portfolioId: portfolioId,
  );
}

@riverpod
Future<void> createBasketPortfolio(
  Ref ref, {
  required Map<String, dynamic> request,
}) async {
  final repository = await ref.watch(basketRepositoryProvider.future);
  return repository.createPortfolio(request);
}

@riverpod
Future<BasketOpportunity> calculateBasketQuantities(
  Ref ref, {
  required Map<String, dynamic> request,
}) async {
  final repository = await ref.watch(basketRepositoryProvider.future);
  return repository.calculateQuantities(request);
}

@riverpod
Future<void> deleteBasket(
  Ref ref, {
  required String basketId,
  required String userId,
}) async {
  final repository = await ref.watch(basketRepositoryProvider.future);
  return repository.deleteBasket(
    basketId: basketId,
    userId: userId,
  );
}

@riverpod
Future<BasketOpportunity> enhancedBasketPreview(
  Ref ref, {
  required String etfIsin,
  required String userId,
  required String portfolioId,
}) async {
  // 1. Fetch raw opportunity
  final opportunity = await ref.watch(
    basketPreviewProvider(
      etfIsin: etfIsin,
      userId: userId,
      portfolioId: portfolioId,
    ).future,
  );
  
  // 2. Fetch current holdings
  final holdings = await ref.watch(portfolioHoldingsProvider(portfolioId).future);
  
  // 3. Enhance opportunity
  final recommendationService = ref.watch(basketRecommendationServiceProvider);
  return recommendationService.enhanceOpportunityWithHoldings(opportunity, holdings.holdings);
}

