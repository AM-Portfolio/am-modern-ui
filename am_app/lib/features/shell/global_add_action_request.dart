import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:am_common/am_common.dart';

import '../../core/router/app_routes.dart';
import '../../core/router/share_url_builder.dart';

/// Queues [kind] on [GlobalAddActionsBus] and navigates when the current
/// route cannot host that action (same rules as GlobalSidebar Sync).
void requestGlobalAddAction(
  BuildContext context, {
  required GlobalAddActionKind kind,
  required String currentLocation,
  VoidCallback? onUploadOnDashboard,
}) {
  final loc = currentLocation;
  final onPortfolio = loc.startsWith(AppRoutes.portfolio);
  final onTrade = loc.startsWith(AppRoutes.trade);
  final onDashboard = loc == AppRoutes.dashboard ||
      loc.startsWith('${AppRoutes.dashboard}/');
  final bus = GlobalAddActionsBus.instance;
  final portfolioId = context.selectedPortfolioId;
  final id = (portfolioId != null &&
          portfolioId.isNotEmpty &&
          portfolioId != 'all')
      ? portfolioId
      : (ShareUrlBuilder.portfolioIdFromLocation(loc) ?? 'all');

  if (kind == GlobalAddActionKind.uploadPortfolio &&
      onDashboard &&
      onUploadOnDashboard != null) {
    onUploadOnDashboard();
    return;
  }

  bus.request(kind);

  if (kind == GlobalAddActionKind.addTrade && onTrade) {
    return;
  }
  if (onPortfolio) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (bus.pending == kind) bus.request(kind);
    });
    return;
  }

  if (kind == GlobalAddActionKind.addTrade) {
    context.go(AppRoutes.tradePath(id, 'portfolios'));
    return;
  }
  final tab =
      kind == GlobalAddActionKind.addBasket ? 'baskets' : 'overview';
  context.go(AppRoutes.portfolioPath(id, tab));
}
