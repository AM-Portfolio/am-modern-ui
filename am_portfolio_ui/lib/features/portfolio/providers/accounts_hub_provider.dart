import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../internal/data/dtos/accounts_hub_dto.dart';
import 'portfolio_providers.dart';

final accountsHubProvider =
    FutureProvider.autoDispose<AccountsHubDto>((ref) async {
  final ds = await ref.watch(portfolioRemoteDataSourceProvider.future);
  return ds.getAccountsHub();
});
