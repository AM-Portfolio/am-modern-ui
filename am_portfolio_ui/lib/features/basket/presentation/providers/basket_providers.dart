import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';

import '../../domain/models/basket_catalog.dart';
import '../../domain/models/basket_opportunity.dart';
import '../../domain/models/tracking_basket.dart';
import '../../domain/models/basket_detail.dart';
import '../../domain/models/basket_draft.dart';
import '../../domain/repositories/basket_repository.dart';
import '../../data/repositories/basket_repository_impl.dart';
import '../../data/datasources/basket_remote_data_source.dart';
import '../../../portfolio/providers/portfolio_providers.dart';

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

@Riverpod(keepAlive: true)
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
  BasketOpportunity? seededOpportunity,
}) async {
  if (seededOpportunity != null && seededOpportunity.etfIsin == etfIsin) {
    try {
      final holdings =
          await ref.watch(portfolioHoldingsProvider(portfolioId).future);
      final fingerprint = BasketOpportunity.fingerprintFromHoldings(
        holdings.holdings.map((h) => MapEntry(h.symbol, h.quantity)),
      );
      if (seededOpportunity.isSeedValidForPreview(fingerprint)) {
        return seededOpportunity;
      }
    } catch (_) {
      // Holdings unavailable — fall through to POST /preview.
    }
  }
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
Future<String> createBasketPortfolio(
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
Future<BasketOpportunity> calculateBasketQuantitiesFinalPreview(
  Ref ref, {
  required Map<String, dynamic> request,
}) async {
  final repository = await ref.watch(basketRepositoryProvider.future);
  return repository.calculateQuantitiesFinalPreview(request);
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
Future<BasketDetail> basketDetail(
  Ref ref, {
  required String basketId,
  required String userId,
}) async {
  final repository = await ref.watch(basketRepositoryProvider.future);
  return repository.getBasketDetail(
    basketId: basketId,
    userId: userId,
  );
}

/// Draft list for My Baskets (not codegen — avoids build_runner for this slice).
final basketDraftsProvider = FutureProvider.autoDispose
    .family<BasketDraftListResult, ({String userId, String portfolioId})>(
  (ref, args) async {
    final repository = await ref.watch(basketRepositoryProvider.future);
    return repository.listDrafts(
      userId: args.userId,
      portfolioId: args.portfolioId.isEmpty ? null : args.portfolioId,
    );
  },
);
