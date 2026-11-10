import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../internal/data/datasources/portfolio_remote_data_source.dart';
import '../internal/data/dtos/nps_dto.dart';
import 'portfolio_providers.dart';

final npsLatestProvider = FutureProvider.autoDispose<NpsDocumentMetaDto?>((ref) async {
  final ds = await ref.watch(portfolioRemoteDataSourceProvider.future);
  return ds.getLatestNps();
});

final npsSchemesProvider =
    FutureProvider.autoDispose.family<List<NpsSchemeLineDto>, String>((ref, portfolioId) async {
  final ds = await ref.watch(portfolioRemoteDataSourceProvider.future);
  return ds.getNpsSchemes(portfolioId);
});
