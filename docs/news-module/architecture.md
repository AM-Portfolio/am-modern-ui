# news-module architecture

## Context

Modern-ui hosts embed `am_news_ui`. GrowthBook gates surfaces. Backend is existing am-news (`/news/v1/*`).

## Containers

```text
am_app → am_dashboard_ui / am_market_ui / am_portfolio_ui / am_trade_ui
           └──────────────► am_news_ui → am_common (flags + ApiClient)
                                      → Traefik /news → am-news pod
```

## Sequence (symbol page)

1. Host mounts `SymbolNewsSection(symbol, surface: NewsUiSurface.equityInsider)`
2. Provider checks master ∧ surface flag
3. If on: `POST /news/v1/insight` `{symbols:[TCS]}`
4. Render cards; flag off → shrink, no HTTP

## Trust

JWT required on news APIs. Flutter never calls admin feed routes.
