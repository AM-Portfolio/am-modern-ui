import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../internal/data/datasources/portfolio_remote_data_source.dart';
import '../internal/data/dtos/cas_dto.dart';
import 'portfolio_providers.dart';

final casLatestProvider = FutureProvider.autoDispose<CasDocumentMetaDto?>((ref) async {
  final ds = await ref.watch(portfolioRemoteDataSourceProvider.future);
  return ds.getLatestCas();
});

final casAccountsProvider =
    FutureProvider.autoDispose<List<DematAccountDto>>((ref) async {
  final ds = await ref.watch(portfolioRemoteDataSourceProvider.future);
  return ds.getCasAccounts();
});

final casFoliosProvider =
    FutureProvider.autoDispose.family<List<CasMfFolioDto>, String>((ref, portfolioId) async {
  final ds = await ref.watch(portfolioRemoteDataSourceProvider.future);
  return ds.getCasFolios(portfolioId);
});
