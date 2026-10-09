/// Re-audit inventory for Global Search (Phase 3 + Market mobile polish).
///
/// Discovery that must go through Global Search (page bars removed):
/// - Baskets explorer (was EtfSearchBar)
/// - Equity Insider empty + hero change-symbol capsule
/// - F&O empty landing + header search icon
/// - Heatmap TextField + GO
/// - Watchlists list "Search watchlists…"
/// - IPO toolbar search box
///
/// Kept specialized / filter-only (not redundant discovery):
/// - SubstituteSelector (basket customize)
/// - Portfolio What-If / Stress / X-Ray / holdings SmartSearchAnchor
/// - Holdings / Watchlist detail / Trade portfolio / Journal / Template filters
/// - Trade InstrumentCard
/// - Heatmap quick index chips (not a discovery TextField)
/// - News / Profile (no search today)
class SearchInventory {
  SearchInventory._();

  static const removedDiscoverySurfaces = <String>[
    'basket_explorer.EtfSearchBar',
    'basket_explorer.SearchEtfsCta',
    'equity_insider_empty_view.SmartSearchAnchor',
    'equity_insider_empty_view.GlobalSearchButton',
    'equity_insider_page.searchOverlay',
    'equity_insider_hero.ChangeStockCapsule',
    'fo_empty_landing_view.SmartSearchAnchor',
    'fo_empty_landing_view.GlobalSearchButton',
    'fo_header_card.searchIcon',
    'heatmap_explorer.TextFieldGo',
    'watchlists_page.SearchWatchlists',
    'ipo_filter_toolbar.SearchBox',
    'global_bottom_navigation.searchIcon',
    'am_command_palette.showMobileTop.fromAppShell',
  ];

  static const keptSpecializedSurfaces = <String>[
    'SubstituteSelector',
    'portfolio_intelligence.SmartSearchAnchor',
    'local_list_filters',
    'watchlist_detail.SearchStocksFilter',
    'trade.InstrumentCard',
    'heatmap_index_chips',
  ];
}
