part of 'app_shell.dart';

/// Global sidebar "+ Sync" quick actions → [GlobalAddActionsBus].
mixin ShellGlobalAdd on State<AppShell> {
  // Satisfied by [ShellNav] on the same State.
  String get _currentLocation;

  List<FloatingMenuAction> _globalAddActions(BuildContext context) {
    return [
      FloatingMenuAction(
        icon: Icons.upload_file_rounded,
        title: 'Upload Portfolio',
        subtitle: 'Import from file or broker',
        iconColor: ModuleColors.portfolio,
        onTap: () => _requestGlobalAdd(
          context,
          common.GlobalAddActionKind.uploadPortfolio,
        ),
      ),
      FloatingMenuAction(
        icon: Icons.add_circle_outline_rounded,
        title: 'Add Trade',
        subtitle: 'Buy or sell an asset',
        iconColor: ModuleColors.trade,
        onTap: () => _requestGlobalAdd(
          context,
          common.GlobalAddActionKind.addTrade,
        ),
      ),
      FloatingMenuAction(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Add Asset Class',
        subtitle: 'Create a new asset class',
        iconColor: ModuleColors.market,
        onTap: () => _requestGlobalAdd(
          context,
          common.GlobalAddActionKind.addAssetClass,
        ),
      ),
      FloatingMenuAction(
        icon: Icons.shopping_basket_outlined,
        title: 'Add Basket',
        subtitle: 'Create a new basket',
        iconColor: ModuleColors.reports,
        onTap: () => _requestGlobalAdd(
          context,
          common.GlobalAddActionKind.addBasket,
        ),
      ),
    ];
  }

  void _requestGlobalAdd(
    BuildContext context,
    common.GlobalAddActionKind kind,
  ) {
    final loc = _currentLocation;
    final onPortfolio = loc.startsWith(AppRoutes.portfolio);
    final onTrade = loc.startsWith(AppRoutes.trade);
    final bus = common.GlobalAddActionsBus.instance;
    final portfolioId = context.selectedPortfolioId;
    final id = (portfolioId != null &&
            portfolioId.isNotEmpty &&
            portfolioId != 'all')
        ? portfolioId
        : (ShareUrlBuilder.portfolioIdFromLocation(loc) ?? 'all');

    // Queue first so a just-mounted Portfolio/Trade screen can consume it.
    bus.request(kind);

    if (kind == common.GlobalAddActionKind.addTrade && onTrade) {
      return;
    }
    if (onPortfolio) {
      // Re-notify next frame in case the listener missed the sync notify
      // (e.g. mid-rebuild while switching tabs).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (bus.pending == kind) bus.request(kind);
      });
      return;
    }

    if (kind == common.GlobalAddActionKind.addTrade) {
      context.go(AppRoutes.tradePath(id, 'portfolios'));
      return;
    }
    final tab =
        kind == common.GlobalAddActionKind.addBasket ? 'baskets' : 'overview';
    context.go(AppRoutes.portfolioPath(id, tab));
  }
}
