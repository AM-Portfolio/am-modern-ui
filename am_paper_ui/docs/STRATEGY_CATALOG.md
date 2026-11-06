# Strategy Catalog (paper chart + Strategy Lab)

**Status:** Draft for review — SoT for what we will set up. No implementation claims until templates/algos are coded against these `strategyId`s.

**Audience:** Day traders, swing traders, and longer-horizon investors using AM paper chart overlays, backtests, baskets, and algos.

**How to use this doc**

1. Read the building blocks once.
2. Review each strategy section (persona → rules → worked example → product mapping).
3. Mark edits in review comments; engineers implement JSON templates + runners only for approved ids.

**Related product concepts**

| Concept | Meaning |
|---------|---------|
| **OrderRule** | One leg: `MARKET` / `LIMIT` / `STOP` / `SUPER` / `TRAIL` + qty/price/SL/target |
| **Line overlay** | Single price level on chart → one child OMS order |
| **Zone overlay** | Price box with **N layers** (user-set, not fixed at 3); each layer = OrderRule + `sizePct`; Σ `sizePct` = 100 |
| **Basket** | Multi-symbol (or multi-leg) set of OrderRules placed together |
| **Algo** | Time/condition runner that *emits* OrderRules (`ZONE_SCALE`, `TWAP`, `ORB`, …) |
| **Strategy** | Named, versioned package of rules + optional overlays/algos (this catalog) |
| **Report** | Calendar / timeframe PnL from fills (live paper or backtest) |

---

## Index of strategy ids

### A — Execution / structure

| Id | Name | Persona |
|----|------|---------|
| `ZONE_SCALE` | N-layer zone scale-in / scale-out | All |
| `LINE_LEVEL` | Single LIMIT / STOP / SUPER line | All |
| `TWAP` | Time-weighted average price execution | Execution / desk |
| `VWAP_EXEC` | VWAP / POV-style participation | Execution / desk |
| `ICEBERG` | Iceberg / display-qty refresh | Execution / desk |
| `SUPER_BRACKET` | Bracket: entry + target + SL | Day / swing |
| `BASKET_MULTI` | Multi-leg basket place | Investor / desk |
| `TRIGGER_CHAIN` | If fill A then place B | All |

### B — Realtime / day trader (indicator + price action)

| Id | Name | Persona | Popularity |
|----|------|---------|------------|
| `ORB` | Opening Range Breakout | Day | **Top-tier** global + India |
| `VWAP_BOUNCE` | VWAP bounce / reclaim / fade | Day | **Top-tier** (~institutional + retail) |
| `MOMENTUM_GAP` | Momentum / Gap-and-Go | Day | **Top-tier** US retail; also NSE gaps |
| `GAP_FILL` | Gap fill (mean reversion open) | Day | Very common NSE + US |
| `CPR_PIVOT` | CPR / floor pivots (TC/BC/R1/S1) | Day | **Top-tier India** Nifty/BN |
| `EMA_PULLBACK` | 9/20 EMA pullback | Day / scalp | Very common |
| `MA_CROSS_CONT` | MA crossover + pullback continuation | Day / swing | Very common |
| `BREAKOUT_VOL` | Breakout + volume confirmation | Day | Very common |
| `SUPERTREND` | SuperTrend ATR trail | Day / swing | Very common India retail |
| `SCALP_VWAP_EMA` | Tight scalp (1–5m VWAP/EMA) | Scalp (high risk) | Common but costly |

### C — Swing / investor

| Id | Name | Persona | Popularity |
|----|------|---------|------------|
| `MA_50_200_TREND` | 50/200 regime + 20/50 pullback | Swing / investor | **Top-tier** |
| `BB_MEAN_REV` | Bollinger mean reversion / squeeze | Swing / day | **Top-tier** (MA+BB often #1 combo) |
| `RSI_MACD_MA` | RSI + MACD + MA triple confluence | Swing | Very common |
| `MACD_MA_FILTER` | MACD signal cross + MA filter | Swing | Very common |
| `RSI2_MEAN_REV` | Connors-style RSI(2) mean reversion | Swing / quant | Famous systematic |
| `SR_RSI_MACD` | Support/resistance + RSI/MACD | Day / swing | Very common |
| `FIB_CONFLUENCE` | Fib 38.2 / 61.8 + MA / S/R | Swing | Common |
| `NR7_BREAKOUT` | Narrow Range 7 breakout | Swing / day | Classic India / volatility |
| `DCA_SCALE_BASKET` | Investor DCA / %-drop scale-in | Investor | Common investor habit |

---

## Popularity ranking (what traders actually use most)

Compiled from global day-trading roundups, institutional VWAP usage, India intraday practice (Nifty/BankNifty), and retail indicator surveys (MA / Bollinger / MACD / RSI dominate). **Not** a claim of profitability — only **adoption / mindshare**.

### Tier S — set these up first (almost every desk / YouTube / India F&O classroom)

| Rank | Id | Why it is everywhere |
|------|-----|----------------------|
| 1 | `VWAP_BOUNCE` + `VWAP_EXEC` | Institutions benchmark to VWAP; polls cite ~70%+ algo use of VWAP family; retail copies bounce/reclaim |
| 2 | `ORB` | Flagship morning framework US + NSE 9:15–9:30 |
| 3 | `MOMENTUM_GAP` | “Gap-and-go” / catalyst momentum — often listed as *the* retail day-trade style |
| 4 | `EMA_PULLBACK` / MAs | Moving averages are the #1 indicator in many retail surveys; 9/20 and 20/50 are the workhorse |
| 5 | `CPR_PIVOT` | India-specific staple for Nifty/BankNifty pre-market map (narrow vs wide CPR) |
| 6 | `SUPER_BRACKET` + `LINE_LEVEL` + `ZONE_SCALE` | How orders are *placed* on modern chart UIs (Kite/TV-like) |

### Tier A — very common; include in v1 catalog

| Id | Why |
|----|-----|
| `GAP_FILL` | Opposite of gap-and-go; very common NSE gap literature |
| `BREAKOUT_VOL` | Classic S/R / consolidation break with volume |
| `MA_50_200_TREND` | Golden/death cross language everyone knows |
| `BB_MEAN_REV` | Bollinger often #2 after MAs; squeeze + band fade |
| `SUPERTREND` | Extremely common on Indian retail platforms |
| `RSI_MACD_MA` / `MACD_MA_FILTER` | Oscillator + trend filter staples |
| `TWAP` / `ICEBERG` / `BASKET_MULTI` | Desk execution language |

### Tier B — well-known; ship after Tier S/A

| Id | Why |
|----|-----|
| `FIB_CONFLUENCE` | Popular but subjective; needs confluence rules |
| `NR7_BREAKOUT` | Classic volatility contraction → expansion |
| `RSI2_MEAN_REV` | Famous Connors-style systematic mean reversion |
| `DCA_SCALE_BASKET` | Investor behaviour more than “strategy brand” |
| `SCALP_VWAP_EMA` | Common but fee-sensitive — keep as advanced |
| `TRIGGER_CHAIN` | Structure helper, not a named market playbook |

### Already covered vs newly added this revision

| Already in first draft | **Added after popularity review** |
|------------------------|-----------------------------------|
| ORB, VWAP, EMA, MA cross, breakout+vol, MA50/200, RSI/MACD, Fib, DCA, TWAP… | `MOMENTUM_GAP`, `GAP_FILL`, `CPR_PIVOT`, `SUPERTREND`, `BB_MEAN_REV`, `RSI2_MEAN_REV`, `NR7_BREAKOUT` |

---

## Shared conventions

### Risk (every discretionary strategy)

- Decide **rupees at risk** first (e.g. 0.5–1% of paper wallet), then size:  
  `qty = riskRupees / |entry − stop|` (per share/point).
- Prefer **≥ 1.5R–2R** reward vs risk before taking the trade.
- One primary setup per symbol per session unless the catalog entry says otherwise.
- Skip major event windows (RBI, budget, big results) unless the strategy is explicitly event-oriented.

### N-layer zone math (used by `ZONE_SCALE`, parts of `DCA_SCALE_BASKET`)

User picks **N** (min 2, max from config, e.g. 10). Each layer `i` has:

```text
sizePct[i] > 0
sum(sizePct) == 100
qty[i] = floor(totalQty * sizePct[i] / 100)   # last layer absorbs remainder
price[i] = price along the zone box (buy: higher → lower as layers deepen)
```

Default **template** (not a hard limit): N=3 → 25% / 25% / 50%. UI must allow add/remove layers and a “redistribute evenly” helper.

### Product mapping fields (every entry below)

| Doc field | Product |
|-----------|---------|
| Entry condition | Indicator trigger and/or chart geometry |
| Size plan | qty / layer `sizePct` / TWAP slices |
| Order types | OrderRule per leg/layer |
| Manage | Drag line, edit chip, algo stop |
| Measure | Calendar + TF report metrics |

### Research notes (sources informing rules)

Staples used across live trader / institutional practice (not endorsements of profitability):

- **ORB** — NSE 9:15–9:30 range; first close outside; SL opposite side or mid; 1.5R–2R or time exit (~15:00–15:15). Common on Nifty/BankNifty.
- **VWAP** — institutional fair-value: trend pullback (“bounce”), reclaim + retest, band fade only on flat/range days (±2σ); execution algos often VWAP-scheduled.
- **Momentum / Gap-and-Go** — gap + catalyst + relative volume; continue with gap; often #1 retail day style in US lists.
- **Gap fill** — fade small gaps back to prior close; VWAP confirm; time stop midday.
- **CPR / pivots** — India floor-trader map from prior H/L/C; narrow CPR → breakout day, wide → range.
- **9/20 EMA** — trend filter + shallow pullback; enter on confirmation candle / break of rejection high; stop under pullback low.
- **SuperTrend** — ATR trailing stop as bias + exit; very common on Indian retail charts.
- **50/200** — golden/death cross as **regime filter**; entries often on faster MA pullbacks, not the cross alone.
- **Bollinger** — mean reversion (close back inside band) and squeeze breakout; often paired with MAs in surveys.
- **RSI + MACD + MA** — confluence: MA for trend, RSI for pullback zone, MACD for momentum turn; RSI(2)+200MA = Connors-style.
- **NR7** — narrowest range in 7 sessions → next-day breakout expansion.
- **TWAP / VWAP-exec / POV / Iceberg** — institutional parent→child execution to reduce impact and hide size.
- **Fib** — 38.2 / 50 / 61.8 as zones only when overlapped with MA and/or prior S/R + candle confirmation.

---

# A — Execution / structure

## 1. `ZONE_SCALE` — N-layer zone scale-in / scale-out

### Persona / timeframe

All personas. Intraday (5m–15m) for day scale-in; daily for investor scale-in. Chart geometry first; indicators optional as filters.

### Intent

Split one thesis into **N** price layers so average entry improves if price walks into the zone (buy: dips fill deeper layers; sell: rallies fill higher layers).

### Rules

1. User draws a **buy or sell zone** (price high / low of box) and sets **N ≥ 2**.
2. Configure each layer: `sizePct`, `orderType` (`LIMIT` default; optional `STOP` / `SUPER` per layer).
3. Validate Σ `sizePct` = 100.
4. On place: emit **N** child OMS orders (no parent OMS schema required).
5. Scale-out variant: after position is open, place N sell (or cover) layers into strength / weakness.

### Worked example (buy scale-in, N=4)

- Symbol: `RELIANCE`, thesis “buy dip into 1,400–1,420 support band”
- Total qty: **100** shares  
- Layers (user-defined, not 3-only):

| Layer | sizePct | qty | LIMIT price | OrderRule |
|-------|---------|-----|-------------|-----------|
| L1 | 20 | 20 | 1,420 | LIMIT BUY |
| L2 | 20 | 20 | 1,413 | LIMIT BUY |
| L3 | 30 | 30 | 1,407 | LIMIT BUY |
| L4 | 30 | 30 | 1,400 | SUPER BUY (target 1,450, SL 1,385) |

If only L1–L2 fill: filled 40 @ avg ~1,416.5. If all fill: 100 @ weighted avg.

### Product mapping

| Field | Mapping |
|-------|---------|
| Entry | Zone box geometry + layer prices |
| Size | Per-layer `sizePct` |
| Orders | N × `POST /v1/orders` |
| Manage | Hover cancel per child; edit layer %; cancel-all zone |
| Measure | Fills by layer; avg entry; calendar PnL by strategyId |

### Algo form

`AlgoDefinition.type = ZONE_SCALE` can also place layers as LTP walks into the box (conditional), not only all-at-once resting limits.

### Report angles

- Fill rate by layer (how often L3/L4 fill)
- Avg entry vs mid-zone
- PnL when “all layers filled” vs “partial”

---

## 2. `LINE_LEVEL` — Single LIMIT / STOP / SUPER line

### Persona / timeframe

All. Any chart TF.

### Intent

Classic TradingView / Kite-style: arm B or S, click price → short solid line → one working order.

### Rules

1. Arm side (BUY/SELL) with default OrderRule from config.
2. Click (or drag) price → place one child order.
3. Hover sticky chip → cancel; drag line → amend price (cancel+replace or amend if OMS supports).

### Worked example

- Arm BUY, OrderRule = `SUPER`, qty 50, target +1.5%, SL −0.8%  
- Click 24,850 on Nifty fut chart → SUPER working at 24,850.

### Product mapping

Line overlay → 1 OrderRule → 1 OMS order. Building block for everything else.

---

## 3. `TWAP` — Time-weighted average price

### Persona / timeframe

Execution / desk. Parent order over a clock window (e.g. 10:00–14:00).

### Intent

Split total qty into **equal time slices** so execution tracks the simple time average — used when volume profile is unreliable or a steady pace is preferred (institutional staple alongside VWAP).

### Rules

1. Inputs: `totalQty`, `side`, `start`, `end`, `sliceCount` (or `intervalMinutes`), optional limit band.
2. Each tick of the schedule: emit one child OrderRule for `qty/sliceCount` (last slice absorbs remainder).
3. Optional: randomize ±jitter on slice size/time (paper can start without jitter).
4. Stop algo → cancel remaining working children.

### Worked example

- BUY 10,000 shares INFY, window 60 minutes, 12 slices → ~833 shares every 5 minutes as LIMIT near mid / MARKET (config).

### Product mapping

Algo runner only (not a static chart zone). Reports: arrival vs TWAP benchmark (paper approx), slice fill times.

---

## 4. `VWAP_EXEC` — VWAP / POV participation

### Persona / timeframe

Execution. Liquid names.

### Intent

- **VWAP schedule:** weight child sizes by expected intraday volume curve (heavier open/close).  
- **POV (percent of volume):** participate at e.g. 5–10% of *live* tape volume (adapts when volume spikes).

Paper approx: use historical volume profile for VWAP schedule; for POV use bar volume × participation rate.

### Rules (VWAP schedule)

1. Load expected volume weights for session buckets.
2. Allocate `totalQty * weight[bucket]` per bucket; emit children inside each bucket.
3. Optional max participation cap.

### Rules (POV)

1. Each bar (or rolling window): `sliceQty = min(remaining, floor(barVolume * participationPct))`.
2. Emit LIMIT/MARKET child; continue until parent filled or window ends.

### Worked example (POV)

- SELL 5,000 TCS, participation 8%, 5m bars.  
- Bar volume 40,000 → child ≤ 3,200; next bar volume 10,000 → child ≤ 800; stop when remaining = 0.

### Product mapping

Algo. Reports: slippage vs session VWAP; % of volume used.

---

## 5. `ICEBERG` — Display qty refresh

### Persona / timeframe

Execution when hiding size matters (paper: simulate book display).

### Intent

Show only a small **displayQty**; when that slice fills, refresh the next display slice until `totalQty` is done — classic iceberg / iceberg+ (randomized display).

### Rules

1. Inputs: `totalQty`, `displayQty` (e.g. 5–10% of parent), side, limit price.
2. Place child with qty = `displayQty`.
3. On full fill of display slice → place next slice; repeat.
4. Cancel parent → cancel working display child and stop refresh.

### Worked example

- BUY 2,000 @ 950 LIMIT, displayQty 200 → 10 sequential 200-lot children as each fills.

### Product mapping

Algo + TRIGGER-like refresh on fill. Report: time-to-complete, average price.

---

## 6. `SUPER_BRACKET` — Entry + target + SL

### Persona / timeframe

Day and swing. Uses OMS `SUPER` (already supported).

### Intent

One decision: entry with attached profit target and stop — bracket family used everywhere from prop desks to retail MIS.

### Rules

1. Entry OrderRule type `SUPER` with `targetPrice` / `stopPrice` (or % offsets).
2. Optional: scale-out targets (later: multiple targets ≈ zone scale-out).

### Worked example

- BUY SUPER qty 100 @ 500; target 515 (+3%); SL 490 (−2%). Risk ₹1,000; reward ₹1,500 → 1.5R.

### Product mapping

Single line or first layer of a zone with type SUPER. Report: win rate of brackets; avg R-multiple.

---

## 7. `BASKET_MULTI` — Multi-leg basket

### Persona / timeframe

Investor / desk. Place several symbols (or hedges) together.

### Intent

One “ticket” expands to multiple child orders — **OMS trading basket**, not the portfolio “investment basket” customize UI.

### Rules

1. BasketDefinition = list of legs `{ symbol, side, OrderRule, qty }`.
2. Place → validate → `createOrder` per leg; store child ids on basket.
3. Cancel-all → cancel every working child.

### Worked example

| Leg | Symbol | Side | Qty | Rule |
|-----|--------|------|-----|------|
| 1 | RELIANCE | BUY | 20 | LIMIT 1,410 |
| 2 | TCS | BUY | 10 | LIMIT 3,900 |
| 3 | INFY | BUY | 30 | MARKET |

### Product mapping

`POST /v1/baskets/{id}/place`. Can nest with ZONE_SCALE per leg later. Report: basket-level PnL and per-leg contribution.

---

## 8. `TRIGGER_CHAIN` — If fill A then place B

### Persona / timeframe

All. Scale-in confirmation, hedge after fill, or OCO-style sequences.

### Intent

Do not place B until A fills (fully or partially per config).

### Rules

1. Define primary OrderRule A and contingent Rule B (and optional C…).
2. On fill event for A (qty threshold): emit B.
3. Optional: cancel B if A cancels unfilled.

### Worked example

- A: BUY LIMIT 100 @ 100  
- On full fill → B: SELL SUPER target 105 / SL 97 (bracket after entry)

### Product mapping

Algo / Strategy Lab on fill stream (`am-oms-fills` or backtest fills). Report: chain completion rate; PnL of A-only vs A+B.

---

# B — Realtime / day trader

## 9. `ORB` — Opening Range Breakout

### Persona / timeframe

Intraday. Chart TF **5m** (range often marked from first **15m** = 9:15–9:30 IST on NSE). Also common on US RTH open (first 15–30m).

### Indicators / levels

- Opening range high (ORH), opening range low (ORL)
- Optional filters: VWAP side, volume vs average, ATR width filter

### Rules (long; short mirrored)

1. **Setup:** After range window ends, mark ORH/ORL.  
2. **Skip day if** range width > k × ATR(14) daily (e.g. k=0.6–1.5 — config) or too narrow (noise).  
3. **Entry:** First **5m close** above ORH between range-end and cutoff (e.g. 11:00 or 13:00). Wick-only does not count. One trade per symbol per day.  
4. **Stop:** ORL (wider) or range midpoint (tighter).  
5. **Target:** 1.5R–2R, or trail under VWAP; **time exit** by ~15:00–15:15.  
6. **Invalidation:** Close back inside range → exit (optional strict mode).

### Worked example (Nifty fut-style)

| Field | Value |
|-------|-------|
| ORH / ORL | 25,156.50 / 25,092.00 (range 64.5 pts) |
| Entry | 5m close above ORH → 25,156.50 |
| Stop | ORL 25,092 (64.5 pts risk) |
| Target 2R | 25,285.50 |
| Account risk | ₹5,000 (1% of ₹5L) |
| Lot risk | 64.5 × 65 ≈ ₹4,193 → **1 lot** |

### Product mapping

| Field | Mapping |
|-------|---------|
| Entry | Algo watches 5m bars; or user draws ORH/ORL lines and arms STOP/LIMIT |
| Size | Risk-based qty |
| Orders | MARKET/LIMIT on break; SUPER with target/SL |
| Manage | Cancel if no break by cutoff |
| Measure | Win rate by weekday; avg entry time; skip-day count |

### Suggested defaults (config)

`rangeMinutes: 15`, `entryTf: 5m`, `entryCutoff: "11:00"`, `targetR: 2`, `stopMode: "opposite"|"mid"`, `maxRangeAtrMult: 0.6`

---

## 10. `VWAP_BOUNCE` — VWAP bounce / reclaim / fade

### Persona / timeframe

Day trader. 1m–5m execution; session VWAP.

### Three setups (pick via `variant`)

#### A) Bounce (trend pullback) — most common

1. Price holds **one side of VWAP** for ~10+ bars; VWAP sloping with trend.  
2. Pullback **to VWAP** (touch / within small band); does **not** slice far through.  
3. Entry: close back away from VWAP, or stop through high/low of touch bar.  
4. Stop: beyond pullback structure (~0.5 ATR buffer).  
5. Target: prior extreme, ±1σ band, or 1R/2R. Cap attempts (e.g. first 1–2 pullbacks of a run).

#### B) Reclaim (control flip)

1. Long stretch below (above) VWAP.  
2. **Decisive close** through VWAP (not a wick). Prefer above-average volume.  
3. First **retest** holds from the new side → enter.  
4. Stop beyond retest extreme; target prior range / bands.

#### C) Band fade (range day only)

1. VWAP **flat**; rotational day.  
2. Tag **±2σ** band; reversal close back inside.  
3. Enter toward VWAP; stop beyond extreme; target VWAP.  
4. **Do not fade** if price walks ±3σ / clear trend / news day.

### Worked example (bounce long)

- 5m chart, rising VWAP; 40 minutes held above.  
- Pullback tags VWAP 812.40; rejection close 813.10.  
- Buy stop 813.40; stop 811.20; target prior high 818.00 (~2R).

### Product mapping

Algo needs session VWAP (+ optional σ bands) from OHLCV. Chart can show VWAP line; entries as LINE/SUPER. Report: bounce vs reclaim vs fade expectancy separately.

---

## 11. `EMA_PULLBACK` — 9/20 EMA pullback

### Persona / timeframe

Day / scalp. **3m–5m** common; also 15m swing-intraday.

### Indicators

- EMA 9, EMA 20 (ribbon)
- Optional: volume pickup on confirmation; HTF 50 EMA bias

### Rules (long; short mirrored)

1. **Trend:** EMA9 > EMA20 and both rising (not flat/chop).  
2. **Pullback:** Price dips into 9–20 zone; **shallow** — strong close below EMA20 = invalid (stand aside).  
3. **Entry:** After rejection candle, enter on break of rejection high **with volume pickup** (or next bar open after bullish confirmation close).  
4. **Stop:** Below pullback micro swing low.  
5. **Exit:** Fixed 2R, or candle close back below EMA9, whichever first.

### Worked example (scalp)

| Step | Level (₹) |
|------|-----------|
| Trend | EMA9 > EMA20 rising on 3m |
| Pullback zone | 497–499; rejection at 498 |
| Entry | Break 500 with volume |
| Stop | 497 (risk ₹3) |
| Size | ₹5,000 risk → ~1,666 shares |
| Target 2R | 506 |

### Product mapping

Indicator algo → emit LIMIT/STOP/SUPER. Optional: place a small **2-layer zone** between EMA9 and EMA20 for scale-in (`ZONE_SCALE` nested). Report: trades skipped for deep pullbacks; avg R.

---

## 12. `MA_CROSS_CONT` — MA crossover + pullback continuation

### Persona / timeframe

Day (9/20 or 20/50 on 15m) and swing (20/50 on 1H–4H).

### Intent

**Do not** buy the raw cross alone (lag + whipsaw). Use cross as **bias**; enter on **pullback** in the new direction.

### Rules (long)

1. Fast MA crosses above slow MA (e.g. 20 above 50) → bias = long.  
2. Wait for pullback toward fast MA (or midline of cross).  
3. Confirmation candle in trend direction.  
4. Optional filters: RSI(14) > 50; MACD hist ≥ 0; ADX(14) > 20–25.  
5. Stop under swing low; target ≥ 1.5R or opposite swing.

### Worked example

- 15m: 20 EMA crosses above 50 EMA at 1,200.  
- Pullback to 20 EMA at 1,195; bullish engulfing.  
- Buy 1,198; stop 1,188; target 1,218 (2R).

### Product mapping

Algo state machine: `bias` → `waitPullback` → `armed` → place. Report: cross-only fakeouts avoided count.

---

## 13. `BREAKOUT_VOL` — Breakout + volume

### Persona / timeframe

Day. 5m–15m. Consolidation / S/R / prior day high-low.

### Rules (long)

1. Identify range or level (prior day high, consolidation box).  
2. Breakout candle **closes** beyond level.  
3. Volume ≥ `k ×` average volume (e.g. k=1.5) on break candle.  
4. Optional retest entry (tighter stop).  
5. Stop inside range / below break candle low; target = range height projected (1R–2R).

### Worked example

- Consolidation 450–460 for 2 hours; avg vol 1L/5m.  
- Close 461.5 on 2.2L volume → long; stop 457; target 470 (range 10 → ~1R from entry).

### Product mapping

Needs **volume on bars**. Zone can mark consolidation; break triggers MARKET/STOP. Report: false break rate when volume filter off vs on.

---

## 14. `SCALP_VWAP_EMA` — Tight scalp (1–5m)

### Persona / timeframe

Scalper only. **High trade count, high cost sensitivity.** Document risk clearly.

### Rules (sketch)

1. Bias: price vs VWAP + EMA9 slope on 1m/3m.  
2. Enter tiny pullbacks; stop very tight (few ticks / 0.1–0.2%).  
3. Target 1R–1.5R or opposite micro structure.  
4. Max trades/day and max daily loss kill-switch required.

### Worked example

- Long above VWAP; tag EMA9; buy 100.05; stop 99.95; target 100.20.

### Product mapping

Same as EMA/VWAP algos with stricter risk caps. Report: expectancy **after** fees; without fees the strategy looks falsely good.

**Warning:** Most retail accounts lose on pure scalp without fee-aware sizing — paper must show costs.

---

# C — Swing / investor

## 15. `MA_50_200_TREND` — 50/200 regime + pullback

### Persona / timeframe

Swing / investor. Daily or weekly for regime; entry on daily/4H.

### Indicators

- SMA/EMA 50, 200 (golden cross / death cross = **regime**, not the only entry)
- Entry MA: 20 or 50 pullback

### Rules (long)

1. Regime: 50 above 200 (golden-cross regime) → only longs. Death-cross regime → only shorts / stand aside.  
2. Entry: pullback to rising 20 or 50 MA with confirmation candle.  
3. Stop: below swing low or below 50 MA by buffer.  
4. Exit: close below 50; or trailing under 20; or target prior major high.

### Worked example

- Daily: 50 > 200 since weeks; price pulls to 50 MA at ₹2,040.  
- Hammer close ₹2,055; buy next open ₹2,060; stop ₹1,980; hold for swing toward ₹2,200.

### Product mapping

Slow algo on daily bars; or manual LINE/SUPER at MA touch. Investor may combine with `DCA_SCALE_BASKET`. Report: regime filter impact on max drawdown.

---

## 16. `RSI_MACD_MA` — Triple confluence

### Persona / timeframe

Swing. 1H–daily.

### Indicators

- MA 50 (trend)
- RSI(14) pullback zone (e.g. 40–50 in uptrend; not >70 chase)
- MACD (12,26,9) line/signal cross or hist flip

### Rules (long)

1. Price above rising 50 MA.  
2. RSI dips into 40–50 (or toward 30–40 for deeper value) then turns up.  
3. MACD hist turns positive or MACD crosses above signal.  
4. Enter on confluence bar close / next open.  
5. Stop below recent swing; target 2R or prior resistance.

### Worked example

- Price 1,120 > 50 MA 1,080; RSI from 62 → 44 then 48; MACD hist −0.2 → +0.1.  
- Buy 1,125; stop 1,090; target 1,195.

### Product mapping

Indicator algo with three boolean gates. Report: trades with 2-of-3 vs 3-of-3 confluence.

---

## 17. `MACD_MA_FILTER` — MACD cross + MA filter

### Persona / timeframe

Swing. 4H–daily.

### Rules (long)

1. Price above 50 MA (filter).  
2. MACD line crosses above signal.  
3. Optional: hist was negative and expanding then contracting into cross.  
4. Stop below swing; exit on opposite MACD cross or MA break.

### Worked example

- Above 50 MA; MACD cross up at 455; buy; stop 440; exit on MACD cross down at 480.

### Product mapping

Simpler sibling of `RSI_MACD_MA`. Good first indicator algo to implement after ORB/VWAP.

---

## 18. `SR_RSI_MACD` — Support/resistance + RSI/MACD

### Persona / timeframe

Day (intraday S/R) and swing (daily levels).

### Rules

**Bounce long at support**

1. Clear horizontal support (prior swing / demand).  
2. RSI oversold or rising from <40; MACD not making aggressive new lows (or bullish cross).  
3. Reversal candle at level.  
4. Stop below support; target next resistance / mid-range.

**Breakout**

1. Close beyond resistance with volume (`BREAKOUT_VOL` rules).  
2. RSI > 50; MACD positive — momentum agrees.

### Worked example (bounce)

- Support 780 tested thrice; RSI 36 → 42; hammer; buy 784; stop 772; target 810.

### Product mapping

User-drawn S/R lines + indicator filters; or detected pivots later. Zone at support for scale-in (`ZONE_SCALE`).

---

## 19. `FIB_CONFLUENCE` — Fib + MA / S/R

### Persona / timeframe

Swing. 1H–daily. Fib alone is weak — **confluence required**.

### Rules (long)

1. Clear impulse leg: swing low → swing high; draw retracement.  
2. Focus levels: **38.2%**, **50%**, **61.8%**.  
3. Require overlap with rising 20/50 MA and/or prior S/R within a small tolerance.  
4. Wait for rejection / engulfing at the zone — do not buy the touch blindly.  
5. Stop beyond 61.8% (if entry at 38.2) or beyond swing extreme + ATR buffer.  
6. Targets: prior high; extensions 1.272 / 1.618 optional.

### Worked example

- Impulse 1,000 → 1,200; 61.8% = 1,076.  
- 50 MA at 1,080; prior support 1,075 → confluence zone 1,074–1,082.  
- Bullish engulfing 1,085; buy; stop 1,050; target 1,200.

### Product mapping

Chart Fib tool (future) or manual levels as LINE/ZONE; algo checks MA distance. Report: win rate by Fib level (38.2 vs 61.8).

---

## 20. `DCA_SCALE_BASKET` — Investor DCA / %-drop scale-in

### Persona / timeframe

Investor. Daily/weekly decisions; weeks–months hold.

### Intent

Build size across **time** and/or **%-drop** layers — often across a basket of names. Combines `BASKET_MULTI` + `ZONE_SCALE` ideas without requiring intraday staring.

### Rules

1. Universe: 1..M symbols (basket).  
2. Capital allocation per symbol (equal or weight).  
3. Layers by **calendar** (e.g. buy 25% each Monday for 4 weeks) and/or by **%-drop from reference** (ATH / last buy): e.g. −3%, −6%, −10%.  
4. Each layer = LIMIT or MARKET OrderRule.  
5. Optional: pause DCA if regime death-cross on index (`MA_50_200_TREND` filter).

### Worked example (single name, %-drop, N=4)

| Layer | Trigger | sizePct | Action |
|-------|---------|---------|--------|
| L1 | Now | 25 | MARKET BUY |
| L2 | −3% from L1 fill | 25 | LIMIT |
| L3 | −6% | 25 | LIMIT |
| L4 | −10% | 25 | LIMIT |

Basket variant: same schedule on RELIANCE / TCS / INFY with 1/3 capital each.

### Product mapping

Algo schedule + basket place. Report: capital deployed vs idle; average cost vs first fill; calendar PnL monthly.

---

# D — Added after popularity review (detailed)

## 21. `MOMENTUM_GAP` — Momentum / Gap-and-Go

### Persona / timeframe

Day. Pre-market scan → first 30–90 minutes. **Tier S** in US retail lists; also used on NSE when stocks gap on news/results.

### Intent

Trade **continuation** of a large gap driven by a catalyst and unusual volume — not fade the open.

### Rules (long; short mirrored)

1. **Gap:** open ≥ ~2–4% above prior close (config).  
2. **Relative volume:** pre-market or early session vol ≥ 2–3× average.  
3. **Catalyst:** earnings, news, sector move (manual tag in paper; optional later).  
4. **Bias:** price holding **above VWAP** for longs.  
5. **Entry:** break of pre-market high / first pullback hold above VWAP / ORB of first 5–15m in gap direction.  
6. **Stop:** below VWAP or below opening range low / pre-market low.  
7. **Exit:** 1R–2R, trail under VWAP, or time exit after morning drive fades.  
8. **Skip:** gap with no volume / no catalyst; fading into strong gap (that is `GAP_FILL`).

### Worked example

- Stock prior close ₹500; opens ₹520 (+4%); pre-mkt vol 3×; holds above VWAP ₹518.  
- Buy break of ₹522; stop ₹516; target ₹534 (2R).

### Product mapping

Scanner + VWAP filter + LINE/SUPER or small ZONE at pullback. Report: expectancy by gap % bucket; morning vs afternoon.

---

## 22. `GAP_FILL` — Gap fill (open mean reversion)

### Persona / timeframe

Day. Opposite thesis to `MOMENTUM_GAP`. Common in NSE gap studies and US “gap fade”.

### Rules

1. Gap size in band (e.g. 0.3–1.5% — too large often *breakaway*, not fill).  
2. Wait ~15 minutes after open (let auction settle).  
3. **Gap up → short** toward prior close; **gap down → long** toward prior close.  
4. Confirm with VWAP: gap-up fill prefers price **below** VWAP; gap-down fill **above** VWAP.  
5. Target = prior close; stop beyond session extreme so far; **time stop** ~13:00 if unfilled.

### Worked example

- Prior close 24,800; open 24,920 (+0.48%); after 15m trading below VWAP.  
- Short 24,900; target 24,800; stop 24,960.

### Product mapping

Algo needs prior close + session open + VWAP. Mutually exclusive mode flag vs `MOMENTUM_GAP` for same symbol/day.

---

## 23. `CPR_PIVOT` — Central Pivot Range / floor pivots

### Persona / timeframe

Day — **India Nifty/BankNifty staple**. Pre-market map from **previous session** H/L/C.

### Levels

```text
Pivot P = (H + L + C) / 3
BC = (H + L) / 2
TC = 2*P − BC
R1 = 2*P − L ; S1 = 2*P − H
(+ R2/S2, PDH/PDL as extras)
Width = (TC − BC) / P   → narrow / normal / wide
```

### Rules

1. Before open: mark TC, P, BC, S1/S2, R1/R2, PDH/PDL; note **narrow vs wide** CPR.  
2. **Narrow CPR** → prefer **breakout** continuation (close above TC / below BC with volume).  
3. **Wide CPR** → prefer **range** fades at TC/BC / R1/S1.  
4. Enter only on **completed 5m close** beyond level (not wick alone).  
5. Stop: close back through trigger level; target next pivot / measured move.

### Worked example

- Narrow CPR; 5m close above TC 52,100 on BankNifty; buy; stop below BC; target R1.

### Product mapping

Daily level overlay on intraday chart + algo triggers. Report: narrow vs wide day expectancy separately.

---

## 24. `SUPERTREND` — SuperTrend ATR trail

### Persona / timeframe

Day and swing. Extremely common on Indian retail platforms (TradingView/broker charts).

### Indicators

SuperTrend(ATR period, multiplier) — e.g. (10, 3) daily; BankNifty 5m often wider mult ~2.5–3.

### Rules (long)

1. SuperTrend flips **bullish** (line moves below price) → bias long.  
2. Entry: on flip close, or pullback to SuperTrend line then bounce.  
3. Stop / trail: SuperTrend line itself (or ATR buffer).  
4. Exit: opposite flip.  
5. Optional filter: only with price above VWAP (intraday) or above 50 MA (swing).

### Worked example

- 15m SuperTrend flips green at 1,250; buy; trail under line; exit when flips red at 1,310.

### Product mapping

Indicator algo emitting SUPER/TRAIL-style management. Report: flip frequency vs profit factor by TF.

---

## 25. `BB_MEAN_REV` — Bollinger mean reversion / squeeze

### Persona / timeframe

Swing and range-day intraday. Bollinger often ranks just behind MAs in retail indicator surveys; MA+BB is a top combo.

### Indicators

Bollinger(20, 2); optional Keltner for squeeze; RSI filter.

### Rules — mean reversion

1. Prefer **range / flat MA** context (not strong trend).  
2. Close **outside** lower band → next close **back inside** → long (mirror for short).  
3. Target = middle band (20 SMA); stop beyond extreme + buffer.  
4. Optional: RSI < 30 on the outside bar.

### Rules — squeeze breakout

1. Bands inside Keltner (low vol) after prior trend.  
2. Close outside upper band → long breakout; stop other side of squeeze; target measured expansion.

### Worked example (mean rev)

- Close 98 below lower BB; next day close 101 back inside; buy; stop 96; target mid BB 108.

### Product mapping

Indicator algo; squeeze needs Keltner. Report: mean-rev vs squeeze as separate variants.

---

## 26. `RSI2_MEAN_REV` — Connors-style RSI(2)

### Persona / timeframe

Swing / systematic. Famous quant-retail hybrid (Connors RSI2).

### Rules (long-only classic sketch)

1. Price above **200-day SMA** (bull regime).  
2. RSI(2) crosses **below 10** (very oversold short-term).  
3. Buy next open / close.  
4. Exit when close **above 5-day SMA** (or RSI(2) > 70).  
5. Hard stop optional (ATR) — original often MA-based exit only; we **require** a stop for paper safety.

### Worked example

- Above 200 SMA; RSI(2) = 8; buy 450; exit when close > 5 SMA at 462; stop 435.

### Product mapping

Simple daily algo — good early Strategy Lab candidate. Report: trades/year; hold days; regime filter on/off.

---

## 27. `NR7_BREAKOUT` — Narrow Range 7

### Persona / timeframe

Swing / positional day-after. Classic India AmiBroker-era + global volatility contraction.

### Rules

1. Day T is **NR7**: (High−Low) is the **narrowest** of the last 7 sessions.  
2. Day T+1: trade **breakout** of NR7 high (long) or low (short), prefer with volume.  
3. Variants: require gap in breakout direction; or wait for close beyond NR7 range.  
4. Stop: opposite side of NR7 range (or fixed %). Target: 2R–4R or trail.

### Worked example

- NR7 high/low 1,000 / 985. Next day breaks 1,000 on volume; buy; stop 985; target 1,030 (~2R).

### Product mapping

Daily bar scan → next day STOP/LIMIT orders. Report: Nifty vs single-stock hit rate.

---

## Implementation order (after doc approval)

Suggested build sequence by **popularity × engineering fit**:

1. **Chart core:** `LINE_LEVEL`, `SUPER_BRACKET`, `ZONE_SCALE`  
2. **Tier S day:** `ORB`, `VWAP_BOUNCE`, `MOMENTUM_GAP`, `EMA_PULLBACK`, `CPR_PIVOT`  
3. **Tier A day/swing:** `GAP_FILL`, `BREAKOUT_VOL`, `SUPERTREND`, `BB_MEAN_REV`, `MA_50_200_TREND`  
4. **Execution:** `TWAP`, `VWAP_EXEC`, `ICEBERG`, `TRIGGER_CHAIN`, `BASKET_MULTI`  
5. **Oscillator / classic:** `MACD_MA_FILTER`, `RSI_MACD_MA`, `MA_CROSS_CONT`, `RSI2_MEAN_REV`, `NR7_BREAKOUT`  
6. **Later / advanced:** `FIB_CONFLUENCE`, `SR_RSI_MACD`, `DCA_SCALE_BASKET`, `SCALP_VWAP_EMA`

JSON templates (after review): `am_paper_ui/assets/config/strategies/<strategyId>.json`

---

## Review checklist (for you)

- [ ] Agree with **Tier S** priority (VWAP, ORB, Momentum/Gap, EMA, CPR, chart core)?  
- [ ] Drop any Tier B id from v1?  
- [ ] Cap on zone layers OK at **max 10**? Min **2**?  
- [ ] Default ORB window **15m** and cutoff **11:00 IST** OK for India-first?  
- [ ] `MOMENTUM_GAP` vs `GAP_FILL`: keep as **two ids** (recommended) or one id with mode?  
- [ ] `SCALP_VWAP_EMA` stay advanced?  
- [ ] Investor DCA: calendar, %-drop, or **both** under one id?  
- [ ] Anything else famous you want (e.g. ICT/SMC order blocks — usually too discretionary for v1 algos)?

---

## Change log

| Date | Note |
|------|------|
| 2026-11-06 | Initial draft — 20 strategies |
| 2026-11-06 | Popularity review: Tier S/A/B ranking; added `MOMENTUM_GAP`, `GAP_FILL`, `CPR_PIVOT`, `SUPERTREND`, `BB_MEAN_REV`, `RSI2_MEAN_REV`, `NR7_BREAKOUT` (27 total) |
