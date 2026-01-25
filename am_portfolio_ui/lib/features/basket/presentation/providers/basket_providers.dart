import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';

import '../../domain/models/basket_opportunity.dart';
import '../../domain/repositories/basket_repository.dart';
import '../../data/repositories/basket_repository_impl.dart';
import '../../data/datasources/basket_remote_data_source.dart';

part 'basket_providers.g.dart';

@riverpod
Future<BasketRepository> basketRepository(Ref ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final remoteDataSource = BasketRemoteDataSourceImpl(apiClient: apiClient);
  return BasketRepositoryImpl(remoteDataSource: remoteDataSource);
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
