# PLAN — `market-dashboard-r360`

| Field | Value |
|-------|--------|
| Kind | `feature` |
| Slug | `market-dashboard-r360` |
| Lead repo | `am-modern-ui` |
| Other repos | `am-market` (API gaps only; no premium) |
| Target env | `preprod` |
| Branch | `feature/market-dashboard-r360` |
| Delivery rating | `6/10` |
| Design rating | `6/10` |
| Scorecard overall | `6.2/10` |
| Agent satisfied | `no` |

Peer lens: [Research 360 Market Dashboard](https://www.research360.in/market/dashboard) — free blocks only; skip Advisory / Alpha Picks / Basket / IAP / Market Reports.

Execute gate: **Delivery 10 + Design 10 + overall ≥ 9.5 + all dims ≥ 9.0 + Agent satisfied: yes** + user confirm. Do not implement until approved.

## Goal

Redesign Market **Dashboard** presentation so it feels like a live market desk: **chart-first + breadth of movers**, not only Top Gainers/Losers. Reuse kept domain/API (ports, FII/DII activity models, movers/sectors/heatmap/history). No template shell from the rolled-back experiment. No paid Research 360 products.

## Images

- `images/` — empty until user confirms layout; then Stitch/preview gate.

## Prerequisites

| Check | Status | Notes |
|-------|--------|-------|
| MCP / Stitch | pending | UI previews after layout approve |
| Downstream APIs | partial | movers, sectors, heatmap, history, FII/DII exist; 52W / most-active / A-D / recovery / buyers need verify or new |
| Postman | pending | analysis movers/sectors when API changes |

## World-class feature map

### Research 360 free inventory → AM

| R360 block | Treat as | AM today | Slice |
|------------|----------|----------|-------|
| Share Market Today / indices strip | Free | Pinned indices + region | **P0** |
| Multi-index / comparison **chart** | Free | `ComparisonChartView` + history batch | **P0** (hero) |
| Top Gainers / Losers (1H·1D·1W·52W) | Free | `/v1/analysis/movers` + `fetchMoversUnified` | **P0** |
| Sector Analysis | Free | `/v1/analysis/sectors` + `fetchSectorPerformance` | **P0** |
| Market heatmap (constituents) | Free (AM strength) | `/v1/analysis/heatmap` | **P0** |
| FII Cash / DII Cash snapshot | Free | `fetchFii`/`fetchDii` + `FiiDiiActivityPort` | **P0** (chip → FII/DII page) |
| World Indices | Free | `globalIndicesData` | **P0** (region toggle already) |
| Advance/Decline (NSE) | Free | Not a first-class API | **P1** (derive from index-performance or new) |
| 52 Week High / Low | Free | No dedicated movers type | **P1** (API or client from quotes) |
| Most Active (Volume / Turnover) | Free | No dedicated endpoint | **P1** |
| News & Corporate Actions | Free | News module / existing feeds | **P1** (embed or deep-link) |
| Today's Recovery & Fall | Free | No API | **P2** |
| Only Buyers & Sellers | Free | No API | **P2** |
| Ace Investors / Screeners / IPO SME | Free-ish | Thin or missing | **P2** |
| Advisory, Alpha Picks, Basket, IAP, Market Reports | **Premium — out of scope** | — | **never** |

### P0 — this slice (presentation only where data exists)

1. **Hero band**: pinned indices + **comparison chart** (TF chips) — chart is primary, not optional.
2. **Sentiment strip**: FII/DII cash net today + optional A/D placeholder if data ready later.
3. **Movers hub** (not gainers-only): tabbed **Gainers | Losers |** (P1: Active / 52W) with TF **1H / 1D / 1W / 1M** (map 52W when API exists); index picker kept.
4. **Sector performance** row (bars or compact table) for focused index + TF.
5. **Heatmap** lower slot for focused index (reuse analysis heatmap).
6. Wire **domain ports** (`OverviewSectionPort` etc.) to new widgets — no DashboardSectionTemplate revival unless you ask.

### P1 — next

- Advance/Decline from constituents up/down counts.
- Most Active volume/turnover ranking API or sort of index-performance.
- 52W high/low lists.
- News + corporate-actions slot (reuse `am_news_ui` if available).

### P2 — later / never

- Recovery/Fall, Only Buyers/Sellers, Ace Investors, Screeners, IPO grid.
- All Research 360 **subscribed** advisory surfaces.

## First-run / virtual value UX

N/A — market data dashboard; no broker cash / virtual portfolio.

## Latency & consistency

- Chart: history batch; show skeleton; on fail keep last good series + error chip.
- Movers/sectors/heatmap: parallel after index+TF known; stale-while-revalidate OK.
- FII/DII chip: cache last session day; do not block chart.
- Stream/LTP: existing MarketProvider; no invented p99.

## Current system (verified)

- Presentation (HEAD): `user_dashboard_page` = pinned indices → comparison chart → `TopMoversWidgetV2` only.
- Domain kept (unwired UI): `DashboardSectionConfig` / ports / `SectionViewModel`; FII/DII activity port + weekly/yearly aggregates.
- APIs: `fetchMovers`/`fetchMoversUnified`, `fetchSectorPerformance`, `fetchHeatmap`, `fetchHistoryBatch`, `fetchFii`/`fetchDii`.
- Analysis BE: `AnalysisController` movers / sectors / index-performance / heatmap / historical-charts.

## Target journeys

1. Open Market → Dashboard → see indices + live chart in first viewport; change TF → chart + movers refresh.
2. Switch movers tab (Gainers ↔ Losers) and TF (1H/1D/…) without leaving page.
3. Scan sectors + heatmap for same focused index.
4. Tap FII/DII chip → existing Institutional / FII-DII Activity route (data already kept).

## Identity & ownership

- Authenticated app user; market data read-only; no ownership of instruments.

## State & money

- N/A for this feature.

## Isolation

- Presentation in `am_market/ui/.../dashboard/presentation` only.
- Domain ports stay pure; no new template registry unless approved.
- Do not reintroduce MoneyControl Activity page UI until separately designed.

## Corner-case matrix

| Case | Trigger | Expected | Covered by |
|------|---------|----------|------------|
| Empty movers | Holiday / bad index | Empty state copy, no spinner forever | widget test |
| Chart history fail | Network | Error chip; strip still works | unit/smoke |
| TF flip mid-load | Rapid chip tap | Latest TF wins; no mixed series | port/page logic |
| Global index selected | Movers on global | Disable stock movers or show “India indices only” | UI guard |
| Heatmap empty | Cache miss | “Live map unavailable” | existing message |
| FII API fail | Chip | Hide or “—” ; page still usable | chip widget |

## Test plan (when Execute)

- Unit: mover TF mapping; sector list empty; FII chip VM.
- Widget: movers hub tabs; chart present in first scroll region.
- Manual :9000 — Research-style scroll: chart → movers → sectors → heatmap.
- Postman only if new analysis types (most-active / 52W / A-D).

## Architecture notes

- Keep slot mental model: **strip → chart → movers hub → lower (sector + heatmap)**.
- Presentation redo; **keep** API/common models and domain ports.
- Backend work only for P1 gaps (most-active, 52W, A-D).

## Scorecard (first pass)

| Dim | Score | Note |
|-----|-------|------|
| Product | 7 | Clear free-vs-premium cut; P0 data-backed |
| Design | 6 | Layout not sketched / no preview yet |
| Architecture | 7 | Ports + existing APIs |
| Reliability | 6 | Latency notes draft |
| Testability | 6 | Matrix started |
| Security | 9 | Read-only market |
| Delivery | 6 | Plan only |
| **Overall** | **~6.2** | |

Adversarial: Blocker if we ship gainers-only again; Major if premium advisory appears; Major if template shell returns without approval.

## Open decisions (need your call)

1. **First viewport**: chart + strip only, or strip + chart + movers peek?
2. **Movers TFs on P0**: stick to AM `1H/1D/1W/1M` or force R360 `52W` even if API incomplete?
3. **FII/DII**: chip on dashboard vs only sidebar page?
4. Approve P0 scope → then Stitch previews → then Execute.
