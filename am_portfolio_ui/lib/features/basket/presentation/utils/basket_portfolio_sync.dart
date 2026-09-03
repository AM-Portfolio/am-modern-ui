import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_common/am_common.dart';

import '../../../portfolio/presentation/cubit/portfolio_cubit.dart';

/// Keeps portfolio dropdown in sync after basket create/delete.
abstract final class BasketPortfolioSync {
  BasketPortfolioSync._();

  static Future<void> afterBasketMutation(
    BuildContext context, {
    String? deletedBasketId,
  }) async {
    try {
      final cubit = context.read<PortfolioCubit>();
      await cubit.refreshPortfoliosList();
    } catch (_) {
      // PortfolioCubit may not be in tree on standalone routes — fail open.
    }

    if (deletedBasketId != null && deletedBasketId.isNotEmpty) {
      try {
        final selected = context.selectedPortfolioId;
        if (selected == deletedBasketId) {
          context.selectPortfolio('all', 'All Portfolios');
        }
      } catch (_) {
        // Selection scope not available — fail open.
      }
    }
  }
}
