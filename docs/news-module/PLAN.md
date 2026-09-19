# News module (`am_news_ui`)

**Kind:** feature  
**Slug:** `news-module`  
**Lead:** am-modern-ui  
**Companion docs:** am-market `am-news/docs/am-news`  
**Branches:** `feature/news-module` (UI) · `feature/news-surfaces` (am-market docs)

## Intent

Shared Flutter package `am_news_ui` with News sections on Dashboard, Market, Portfolio, and Trade pages. Visibility via GrowthBook (`news-ui-*`) under `am_common/feature_flags/news/` — not dumped into `FeatureFlagKeys`.

## Inventory (implement all)

| Module | Page | Route | Scope |
|--------|------|-------|--------|
| am_dashboard_ui | Home | `/app/dashboard` | Current affairs + holdings |
| am_market_ui | Equity Insider | `/app/market/equity-insider` | Open symbol only |
| am_market_ui | Watch List | `/app/market/watch-list` | Selected symbols |
| am_market_ui | Market Analysis | `/app/market/market-analysis` | Chart-selected symbol |
| am_market_ui | Paper | `/app/market/paper` | Focused symbol |
| am_portfolio_ui | Overview | `/app/portfolio/{id}/overview` | Portfolio symbols |
| am_portfolio_ui | Holdings | `/app/portfolio/{id}/holdings` | Book / focused symbol |
| am_portfolio_ui | Baskets | `/app/portfolio/{id}/baskets` | Basket symbols |
| am_trade_ui | Holdings / Trades / Unified / Journal | `/app/trade/{id}/…` | Book or selected symbol |

No standalone News nav. No news on Analysis/Heatmap/Calendar/F&O/explorers/Admin.

## Flags

Master `news-ui-enabled` AND per-surface key. Code: `NewsFeatureFlagKeys`, `NewsUiSurface`, `newsUiSurfaceEnabledProvider`.

## API

Unchanged: `GET /v1/current-affairs`, `POST /v1/insight` behind `/news`.

## Test plan

Unit: scopes + flags. Manual preprod: each inventory page; master off hides all.
