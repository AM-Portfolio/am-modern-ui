import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:am_common/am_common.dart';

import '../../core/router/app_routes.dart';
import '../../core/router/share_url_builder.dart';

bool _isConcretePortfolioId(String? id) =>
    id != null && id.isNotEmpty && id != 'all';

/// Navigates Global Add actions to dedicated URLs (Upload / Trade / Asset Class)
/// or portfolio baskets. Does not open in-portfolio Overview/Holdings overlays.
void requestGlobalAddAction(
  BuildContext context, {
  required GlobalAddActionKind kind,
  required String currentLocation,
  // ignore: avoid_unused_constructor_parameters — call-site compat; upload → doc-intel
  VoidCallback? onUploadOnDashboard,
}) {
  final loc = currentLocation;
  final bus = GlobalAddActionsBus.instance;
  final resolved = _resolveConcretePortfolio(context, loc);
  final id = resolved?.id ?? 'all';
  final name = resolved?.name ?? '';

  switch (kind) {
    case GlobalAddActionKind.uploadPortfolio:
      // Dedicated Doc Intel page (dashboard callback is the same destination).
      context.go(AppRoutes.docIntelPath('mailbox'));
      return;

    case GlobalAddActionKind.addTrade:
      if (!_requireConcretePortfolio(context, id)) return;
      _ensureScopeSelection(context, id, name);
      bus.request(kind);
      context.go(AppRoutes.tradePath(id, 'add-trade'));
      return;

    case GlobalAddActionKind.addAssetClass:
      if (!_requireConcretePortfolio(context, id)) return;
      _ensureScopeSelection(context, id, name);
      context.go(AppRoutes.portfolioPath(id, 'add-asset-class'));
      return;

    case GlobalAddActionKind.addBasket:
      bus.request(kind);
      final basketId = _isConcretePortfolioId(id) ? id : 'all';
      if (_isConcretePortfolioId(basketId)) {
        _ensureScopeSelection(context, basketId, name);
      }
      context.go(AppRoutes.portfolioPath(basketId, 'baskets'));
      return;
  }
}

({String id, String? name})? _resolveConcretePortfolio(
  BuildContext context,
  String location,
) {
  final scopeId = context.selectedPortfolioId;
  if (_isConcretePortfolioId(scopeId)) {
    return (id: scopeId!, name: context.selectedPortfolioName);
  }

  final fromUrl = ShareUrlBuilder.portfolioIdFromLocation(location);
  if (_isConcretePortfolioId(fromUrl)) {
    return (id: fromUrl!, name: context.selectedPortfolioName);
  }

  final session = SessionPersistenceService.instance.cached;
  if (_isConcretePortfolioId(session?.portfolioId)) {
    return (id: session!.portfolioId!, name: session.portfolioName);
  }

  final last = PortfolioDataRefresh.instance.lastPortfolioId;
  if (_isConcretePortfolioId(last)) {
    return (id: last!, name: null);
  }

  return null;
}

void _ensureScopeSelection(BuildContext context, String id, String? name) {
  final current = context.selectedPortfolioId;
  if (current == id) return;
  context.selectPortfolio(id, name ?? '');
}

bool _requireConcretePortfolio(BuildContext context, String id) {
  if (_isConcretePortfolioId(id)) return true;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Select or create a portfolio first'),
    ),
  );
  return false;
}
