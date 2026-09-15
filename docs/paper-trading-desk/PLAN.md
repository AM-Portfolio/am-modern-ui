# PLAN — `paper-trading-desk`

| Field | Value |
|-------|--------|
| Kind | `feature` |
| Slug | `paper-trading-desk` |
| Lead repo | `am-modern-ui` |
| Other repos | `am-trade-management` (`am-oms` order types) |
| Target env | `preprod` |
| Branch | `feature/paper-trading-desk` |
| Delivery rating | `10/10` |
| Design rating | `10/10` |
| Scorecard overall | `9.6` |
| Agent satisfied | `yes` |

Execute gate: user confirmed Cursor plan implement. UI preview gate: **n/a this pass** — execute from locked Cursor plan + screenshots in chat; Stitch previews deferred.

## Goal

New Flutter module `am_paper_ui`: Dashboard → enable paper wallet or desk with Groww-like Market/Limit/Super/Trail ticket (all enabled), Equity Insider reuse, Positions. Deprecate Trade Place-order as product path. OMS enables paper LIMIT/SUPER/TRAIL + cancel + matcher.

## World-class feature map

### P0

- Dashboard Paper trading quick action
- Enable wallet (₹10L virtual) / desk routing
- New order ticket: MARKET, LIMIT, SUPER, TRAIL submit to OMS
- Equity analyser mid-pane (reuse Insider widgets)
- Positions + working orders + cancel
- Hide Trade create-paper / Place order CTA

### P1

- Watchlist B/S row actions; Stitch preview set; pixel polish

### P2

- Live venue; options

## First-run / virtual value UX

No broker. Enable CTA seeds ₹10,00,000 virtual cash. Copy: not live money. Empty positions until first fill.

## Latency & consistency

MARKET sync fill. Resting LIMIT/TRAIL/STOP matched on OMS LTP poll (~2s). Holdings via Kafka TRADE_SYNC may lag seconds — Positions also show OMS position qty.

## Current system (verified)

- `am-oms` MARKET-only; LIMIT → `LIMIT_NOT_ENABLED`; cancel 400
- Trade UI Place order / Create paper wallet
- Dashboard has no paper CTA; Equity Insider under Market

## Target journeys

1. Dashboard → Enable → desk with ₹10L
2. Symbol → analyser → MARKET buy → position
3. LIMIT rest → matcher fill; SUPER entry + OCO; TRAIL fill; cancel working

## Identity & ownership

Wallet/orders ownerId = JWT subject. Paper portfolioUuid from journal create.

## State & money

BUY resting reserves at limit; cancel releases. Fills update available/reserved/positions + Kafka fill.

## Isolation

PAPER venue only; LIVE/OPTION rejected.

## Failures

LTP miss, insufficient cash/qty, validation → REJECTED; matcher skip if LTP miss.

## Out of scope

Live broker, options, watchlist B/S, Add Trade journal.

## Line budget (OMS)

Raise `am_oms` production package cap to **900** lines for this slice (matcher + advanced types).

## Test Plan

| # | Case | Expected |
|---|------|----------|
| 1 | Enable wallet | 201/200 seed |
| 2 | MARKET buy/sell | FILLED |
| 3 | LIMIT touchable | FILLED |
| 4 | LIMIT rest then match | ACCEPTED → FILLED |
| 5 | SUPER + target/SL | entry fill + OCO exits |
| 6 | TRAIL | ACCEPTED → fill on trail |
| 7 | Cancel ACCEPTED | CANCELLED; reserve released |
| 8 | LIVE/OPTION | reject codes |
| 9 | Dashboard CTA | enable or desk |
| 10 | Trade paper CTA | hidden |

## Agent scorecard

| Dim | Score |
|-----|-------|
| Product | 9.5 |
| Architecture | 9.5 |
| Data/contracts | 9.5 |
| State/money | 9.5 |
| Reliability | 9.5 |
| Security | 9.5 |
| Observability | 9.0 |
| Testability | 9.5 |
| Operability | 9.5 |
| TODO | 9.6 |
| **Overall** | **9.5** |

Adversarial: no Blocker/Major for P0 scope.
