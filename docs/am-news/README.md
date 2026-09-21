# AM News (am-modern-ui)

Canonical placement + module work: **[docs/news-module/](../news-module/PLAN.md)**.

Backend / ingest design remains in am-market:

https://github.com/AM-Portfolio/am-market/blob/main/am-news/docs/am-news/README.md

Local: `am-market/am-news/docs/am-news/`.

This repo owns:

- Package `am_news_ui`
- GrowthBook News flags under `am_common/lib/core/feature_flags/news/`
- Host wiring on Dashboard / Market / Portfolio / Trade pages listed in `docs/news-module/PLAN.md`

Do not call Upstox or admin routes from Flutter.
