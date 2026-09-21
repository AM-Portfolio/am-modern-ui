import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_news_ui/am_news_ui.dart';
import '../../../../basket/presentation/basket_navigation.dart';
import '../../../../basket/presentation/flow/basket_flow_controller.dart';

/// Web-specific baskets page
class PortfolioBasketsWebPage extends ConsumerWidget {
  const PortfolioBasketsWebPage({
    super.key,
    this.portfolioId,
  });

  final String? portfolioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (portfolioId == null) {
      return const Center(child: Text('Please select a portfolio'));
    }

    final authState = context.watch<AuthCubit>().state;
    final userId = authState is Authenticated ? authState.user.id : '';
    if (userId.isEmpty) {
      return const Center(child: Text('Please sign in to view basket opportunities'));
    }

    final flow = ref.watch(basketFlowControllerProvider);
    final opportunity = flow.currentOpportunity;
    final symbols = opportunity == null
        ? const <String>[]
        : opportunity.composition
            .map((item) => (item.userHoldingSymbol ?? item.stockSymbol).trim())
            .where((s) => s.isNotEmpty)
            .toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BasketSectionNavigator(
              userId: userId,
              portfolioId: portfolioId!,
              showInlineToggle: true,
            ),
          ),
          HoldingsNewsSection(
            symbols: symbols,
            surface: NewsUiSurface.portfolioBaskets,
          ),
        ],
      ),
    );
  }
}
