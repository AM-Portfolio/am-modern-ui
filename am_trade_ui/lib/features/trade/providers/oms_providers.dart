import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/di/network_providers.dart';

import '../internal/data/datasources/oms_remote_data_source.dart';
import '../presentation/cubit/oms_cubit.dart';

final omsRemoteDataSourceProvider =
    FutureProvider<OmsRemoteDataSource>((ref) async {
  final client = await ref.watch(omsApiClientProvider.future);
  final config = ConfigService.config.api.oms;
  if (config == null) {
    throw Exception('OMS API configuration is not available');
  }
  return OmsRemoteDataSourceImpl(apiClient: client, config: config);
});

final omsCubitProvider = FutureProvider.autoDispose<OmsCubit>((ref) async {
  final source = await ref.watch(omsRemoteDataSourceProvider.future);
  final cubit = OmsCubit(source);
  await cubit.load();
  ref.onDispose(cubit.close);
  return cubit;
});
