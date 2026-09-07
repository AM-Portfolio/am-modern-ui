import '../../domain/models/basket_catalog.dart';
import '../../domain/models/basket_opportunity.dart';
import '../../domain/models/tracking_basket.dart';
import '../../domain/models/basket_detail.dart';
import '../../domain/models/basket_draft.dart';
import '../../domain/repositories/basket_repository.dart';
import '../datasources/basket_remote_data_source.dart';

class BasketRepositoryImpl implements BasketRepository {
  final BasketRemoteDataSource remoteDataSource;

  BasketRepositoryImpl({required this.remoteDataSource});

  @override
  Future<BasketCatalog> getCatalog() {
    return remoteDataSource.getCatalog();
  }

  @override
  Future<List<BasketOpportunity>> getOpportunities({
    required String userId,
    required String portfolioId,
    String? query,
  }) async {
    return remoteDataSource.getOpportunities(
      userId: userId,
      portfolioId: portfolioId,
      query: query,
    );
  }

  @override
  Future<BasketOpportunity> getBasketPreview({
    required String etfIsin,
    required String userId,
    required String portfolioId,
  }) async {
    return remoteDataSource.getPreview(
      etfIsin: etfIsin,
      userId: userId,
      portfolioId: portfolioId,
    );
  }

  @override
  Future<List<TrackingBasket>> getMyBaskets({
    required String userId,
    required String portfolioId,
  }) async {
    final rawList = await remoteDataSource.getMyBaskets(
      userId: userId,
      portfolioId: portfolioId,
    );
    return rawList
        .map((e) => TrackingBasket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> createPortfolio(Map<String, dynamic> request) async {
    final response = await remoteDataSource.createPortfolio(request);
    return response['portfolioId'] as String;
  }

  @override
  Future<BasketOpportunity> calculateQuantities(
      Map<String, dynamic> request) async {
    final response = await remoteDataSource.calculateQuantities(request);
    return BasketOpportunity.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<BasketOpportunity> calculateQuantitiesFinalPreview(
      Map<String, dynamic> request) async {
    final response =
        await remoteDataSource.calculateQuantitiesFinalPreview(request);
    return BasketOpportunity.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<BasketOpportunity> applySubstitutes(
      Map<String, dynamic> request) async {
    final response = await remoteDataSource.applySubstitutes(request);
    return BasketOpportunity.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBasket({
    required String basketId,
    required String userId,
  }) {
    return remoteDataSource.deleteBasket(basketId: basketId, userId: userId);
  }

  @override
  Future<BasketDetail> getBasketDetail({
    required String basketId,
    required String userId,
  }) async {
    final response = await remoteDataSource.getBasketDetail(
      basketId: basketId,
      userId: userId,
    );
    return BasketDetail.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<BasketDraftListResult> listDrafts({
    required String userId,
    String? portfolioId,
  }) async {
    final response = await remoteDataSource.listDrafts(
      userId: userId,
      portfolioId: portfolioId,
    );
    return BasketDraftListResult.fromJson(response);
  }

  @override
  Future<BasketDraftDetail> getDraft({
    required String draftId,
    required String userId,
  }) async {
    final response = await remoteDataSource.getDraft(
      draftId: draftId,
      userId: userId,
    );
    return BasketDraftDetail.fromJson(response);
  }

  @override
  Future<BasketDraftDetail> upsertDraft(Map<String, dynamic> request) async {
    final response = await remoteDataSource.upsertDraft(request);
    return BasketDraftDetail.fromJson(response);
  }

  @override
  Future<void> deleteDraft({
    required String draftId,
    required String userId,
  }) {
    return remoteDataSource.deleteDraft(draftId: draftId, userId: userId);
  }
}
