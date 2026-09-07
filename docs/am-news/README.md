# AM News (am-modern-ui)

Dashboard news slot lives on `feature/dashboard-news`. Canonical design, MCP context, TODO, and Draw.io are in the am-market hub:

https://github.com/AM-Portfolio/am-market/blob/feature/am-news/am-news/docs/am-news/README.md

Local clone: `am-market/am-news/docs/am-news/`.

This repo owns (after docs review):

- `news-ui-enabled` / `newsUiEnabledProvider` (Dart default true except production flavor false; GrowthBook force ON production/dev/preprod)
- `DashboardWidgetId.news` on `/app/dashboard`
- `EnvDomains.news` = `$apiBase/news`, then `POST /v1/insight`
- Holdings symbols from portfolio holdings, not movers

Do not duplicate PLAN here. Do not call Upstox or admin routes from Flutter.
