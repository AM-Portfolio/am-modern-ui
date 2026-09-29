import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/asset_class/holding_form_state.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/asset_class/add_asset_class_workspace.dart'; // For StepBadge
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/asset_class/components/asset_type_card.dart';

class AssetTypeSelector extends ConsumerWidget {
  const AssetTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedType = ref.watch(addAssetClassTypeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 600;
            
            final bondsCard = AssetTypeCard(
              id: 'bonds',
              title: 'Bond',
              subtitle: 'Government, corporate, or other fixed income securities',
              icon: Icons.account_balance,
              iconColor: ModuleColors.portfolio,
              isSelected: selectedType == 'bonds',
              onTap: () {
                ref.read(addAssetClassTypeProvider.notifier).setType('bonds');
                ref.read(addAssetClassHoldingsProvider.notifier).reset();
              },
            );

            final commodityCard = AssetTypeCard(
              id: 'commodities',
              title: 'Commodity',
              subtitle: 'Gold, silver, oil, or other commodities',
              icon: Icons.category,
              iconColor: IntelligenceColors.chartPalette[0],
              isSelected: selectedType == 'commodities',
              onTap: () {
                ref.read(addAssetClassTypeProvider.notifier).setType('commodities');
                ref.read(addAssetClassHoldingsProvider.notifier).reset();
              },
            );

            final cashCard = AssetTypeCard(
              id: 'cash',
              title: 'Cash',
              subtitle: 'Cash or cash equivalents',
              icon: Icons.money,
              iconColor: theme.colorScheme.onSurfaceVariant,
              isSelected: selectedType == 'cash',
              onTap: () {
                ref.read(addAssetClassTypeProvider.notifier).setType('cash');
                ref.read(addAssetClassHoldingsProvider.notifier).reset();
              },
            );

            if (isDesktop) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: bondsCard),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: commodityCard),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: cashCard),
                  ],
                ),
              );
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                bondsCard,
                const SizedBox(height: AppSpacing.md),
                commodityCard,
                const SizedBox(height: AppSpacing.md),
                cashCard,
              ],
            );
          },
        ),
      ],
    );
  }
}
