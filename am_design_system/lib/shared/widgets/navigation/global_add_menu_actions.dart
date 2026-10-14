import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';

import '../../../core/module/module_config.dart';
import 'floating_menu_action.dart';

/// Shared Upload / Add Trade / Asset Class / Basket rows for sidebar + Sync sheet.
List<FloatingMenuAction> buildGlobalAddMenuActions(
  void Function(GlobalAddActionKind kind) onAction,
) {
  return [
    FloatingMenuAction(
      icon: Icons.upload_file_rounded,
      title: 'Upload Portfolio',
      subtitle: 'Import from file or broker',
      iconColor: ModuleColors.portfolio,
      onTap: () => onAction(GlobalAddActionKind.uploadPortfolio),
    ),
    FloatingMenuAction(
      icon: Icons.add_circle_outline_rounded,
      title: 'Add Trade',
      subtitle: 'Buy or sell an asset',
      iconColor: ModuleColors.trade,
      onTap: () => onAction(GlobalAddActionKind.addTrade),
    ),
    FloatingMenuAction(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Add Asset Class',
      subtitle: 'Create a new asset class',
      iconColor: ModuleColors.market,
      onTap: () => onAction(GlobalAddActionKind.addAssetClass),
    ),
    FloatingMenuAction(
      icon: Icons.shopping_basket_outlined,
      title: 'Add Basket',
      subtitle: 'Create a new basket',
      iconColor: ModuleColors.reports,
      onTap: () => onAction(GlobalAddActionKind.addBasket),
    ),
  ];
}
