import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/di/network_providers.dart';

import '../data/paper_oms_data_source.dart';
import '../presentation/paper_oms_cubit.dart';

final paperOmsDataSourceProvider =
    FutureProvider<PaperOmsDataSource>((ref) async {
  final client = await ref.watch(omsApiClientProvider.future);
  final config = ConfigService.config.api.oms;
  if (config == null) {
    throw Exception('OMS API configuration is not available');
  }
  return PaperOmsDataSource(apiClient: client, config: config);
});

final paperOmsCubitProvider = FutureProvider.autoDispose<PaperOmsCubit>((ref) async {
  final source = await ref.watch(paperOmsDataSourceProvider.future);
  final cubit = PaperOmsCubit(source);
  await cubit.load();
  ref.onDispose(cubit.close);
  return cubit;
});
