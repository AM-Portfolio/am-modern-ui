# New-user MF run log — dig — 2026-11-24

**Env:** dig / Contabo (`https://am-dev.asrax.in`)  
**Account:** `kumargyan89@gmail.com` (password redacted in this log)  
**Agent:** Cursor browser + computer-use automation  
**Rule:** every UI action and observed result is appended below in order — including tiny clicks.

---

## Session start

| # | Time (IST) | Action | Result |
|---|------------|--------|--------|
| 0 | ~14:24 | Created this run-log file | OK |

---

## 1 — Open dig

| # | Time (IST) | Action | Result |
|---|------------|--------|--------|
| 1 | ~14:25 | Listed browser tabs | Tab 0: `http://localhost:9000/login` ("AM Investment") already open |
| 2 | ~14:25 | Opened **new** tab, navigated to `https://am-dev.asrax.in` | HTTP load OK; title "AM Investment Platform" |
| 3 | ~14:25 | Observed splash | Dark navy; ASRAX logo + spinning ring; text "Loading AM Investment Platform…" / "Preparing your workspace" |
| 4 | ~14:25 | Locked browser tab `431625` for automation | Lock OK |
| 5 | ~14:25 | Waited ~4s then snapshot | Redirected to `https://am-dev.asrax.in/login`; title "AM Investment" |
| 6 | ~14:25 | Observed login UI | Left: "Welcome back"; Right card: Email & Google (selected), Scan QR, OTP; empty Email + Password; Remember Me checked; Sign In purple; Continue with Google; Create Account link; moon theme toggle top-right |
| 7 | ~14:26 | Click ref `e2` "Enable accessibility" | **FAILED** — click intercepted by `<flutter-view>` (964×529). Login still visible; a11y button not reachable via DOM click |

---

## 2 — Login form fill (Flutter canvas)

| # | Time (IST) | Action | Result |
|---|------------|--------|--------|
| 8 | ~14:26 | CDP: inspect DOM inputs / flutter-view size | viewport 964×529; **0** native `<input>`s; flutter-view present; a11y placeholder 1×1 offscreen |
| 9 | ~14:26 | CDP click `flt-semantics-placeholder` ("Enable accessibility") | **OK** — Flutter semantics host activated (`after: true`) |
| 10 | ~14:26 | Snapshot after a11y enable | Interactive refs now: Email & Google, Scan QR, OTP, **Email address** `e5`, **Password** `e6`, show-password `e7`, Remember Me checkbox `e8` (checked), Forgot Password, Sign In `e10`, Continue with Google, Create Account, Developer Options, theme toggle |
| 11 | ~14:27 | Fill Email `e5` = `kumargyan89@gmail.com` | **OK** — a11y value set; screenshot shows email in field (label slightly overlaps) |
| 12 | ~14:27 | Fill Password `e6` via `browser_fill` | Tool reported filled, but screenshot still looked empty (Flutter TextEditingController may ignore programmatic fill) |
| 13 | ~14:27 | Click Password `e6` | Focused; name became "Password Enter your password"; placeholder visible |
| 14 | ~14:27 | Type password slowly (char-by-char) into `e6` | **OK** — screenshot shows masked dots + purple caret at end |
| 15 | ~14:28 | Click Sign In `e10` | Fields disabled/readonly; UI shows **Signing in…** + spinner on primary button |
| 16 | ~14:28 | Wait ~5s | Auth completes |
| 17 | ~14:28 | Observed post-login | URL → `https://am-dev.asrax.in/app/dashboard`; title AM Investment |
| 18 | ~14:28 | Dashboard UI | Header "Dashboard" / "Portfolio overview…"; Paper Trading selected (vs Advanced); All Portfolios; empty metric cards (new/empty portfolio); NIFTY 50 chart area; Gainers/Losers controls in a11y tree |

---

## 3 — Enter Mutual Funds

| # | Time (IST) | Action | Result |
|---|------------|--------|--------|
| 19 | ~14:29 | CDP search a11y labels for Mutual Funds / nav | Almost no nav labels; only portfolio/family-related a11y |
| 20 | ~14:29 | Navigate to `https://am-dev.asrax.in/app/mutual-funds` | Full reload → "Restoring your session…" |
| 21 | ~14:29 | Wait + re-enable Flutter a11y via CDP placeholder click | OK |
| 22 | ~14:29 | Observed MF URL | **404 UI**: "Page not found: /app/mutual-funds" + purple **Go to dashboard** |
| 23 | ~14:30 | Click Go to dashboard `e4` | Still on 404 briefly (click focused but route stuck) |
| 24 | ~14:30 | Hard navigate `https://am-dev.asrax.in/app/dashboard` | Session restore splash again |
| 25 | ~14:30 | Dig `AM_BUILD_ID` from boot HTML | **`44280255663`** (hosted dig shell) |
| 26 | ~14:31 | Dashboard restored after wait + a11y | Metrics: Total Portfolio Value ₹690,524 (−0.64% Today); Invested ₹634,072; Return +₹56,451 (+8.90%); Active Portfolios 1; Demo Account badge; Paper Trading on; user a11y "Gyaneshwar Kumar" |
| 27 | ~14:31 | Click left edge (~24,120) hunting sidebar | No nav change; still Dashboard content — **no Mutual Funds control visible** in a11y tree |
| 28 | ~14:31 | Note | Dig shell build lacks `/app/mutual-funds` routes (404, not feature-flag redirect to dashboard). Local `localhost:9000` is `AM_BUILD_ID=local` via `npm run run:app:dev` — likely has MF module. Will try local UI → dig BFF next. |

---

## 4 — Local UI (has MF) against dig

| # | Time (IST) | Action | Result |
|---|------------|--------|--------|
| 29 | ~14:32 | Unlock dig tab; lock `localhost:9000` (AM_BUILD_ID=`local`, dart-defines → `am-dev.asrax.in`) | OK |
| 30 | ~14:32 | Navigate `http://localhost:9000/login` | Blank dark briefly, then login after wait; a11y already on |
| 31 | ~14:33 | `browser_fill` email | a11y value set |
| 32 | ~14:33 | Click + slow-type password | Masked dots OK |
| 33 | ~14:33 | Click Sign In | **Email is required** (red) — Flutter canvas empty despite a11y/DOM value |
| 34 | ~14:33 | Retry clear+type email via a11y | WARNING value did not change; still red "Email is required" |
| 35 | ~14:34 | CDP: find `flt-text-editing-host` + inputs | DOM inputs **already** hold email+password; Flutter paint/validation unsynced |
| 36 | ~14:34 | CDP native value setter + input/change events | DOM ok; screenshot still empty email |
| 37 | ~14:34 | Unlock Cursor browser; switch to **desktop Chrome** (embedded browser not on primary monitor) | OK |

---

## 5 — Chrome desktop → dig login + MF hunt

| # | Time (IST) | Action | Result |
|---|------------|--------|--------|
| 38 | ~14:35 | `Start-Process chrome https://am-dev.asrax.in/login` | Chrome opens dig login |
| 39 | ~14:36 | Wait 3s; screenshot | Welcome back + Email & Google form empty |
| 40 | ~14:36–14:37 | Zoom/click email area; type credentials via computer-use | Email `kumargyan89@gmail.com` + password visible in fields |
| 41 | ~14:38 | Click Sign In (~950,480) after approval | **Success** → `am-dev.asrax.in/app/dashboard` |
| 42 | ~14:38 | Observed Chrome dashboard + **left icon rail** | Logo; search; **Dashboard** (active); **Portfolio**; **Trade**; **Market**; purple **+**; palette; profile **G**. Metrics same as before (₹690,524 …). **No Mutual Funds icon** |
| 43 | ~14:39 | Address-bar navigate to `https://am-dev.asrax.in/app/mutual-funds` | Session restore → **404** "Page not found: /app/mutual-funds" + Go to dashboard |

---

## 6 — Switch to localhost:9000 (per user)

| # | Time (IST) | Action | Result |
|---|------------|--------|--------|
| 44 | ~14:39 | User: use localhost | Noted |
| 45 | ~14:39 | `Start-Process chrome http://localhost:9000/login` | Loading splash ASRAX |
| 46 | ~14:40 | Wait → login | Email autofilled `kumargyan89@gmail.com`; password empty; Remember Me checked |
| 47 | ~14:40 | Click password field area | Landed on **dashboard** `localhost:9000/app/dashboard` (session/autofill signed in) |
| 48 | ~14:40 | Observed local sidebar | Logo; search; Dashboard (active); Portfolio; **Mutual** (building/pillars icon — Mutual Funds); Trade; purple +; palette; profile G. Chart NIFTY 50; Health Score "Could not load" + Retry |
| 49 | ~14:42 | Click **Mutual** in left rail | URL → `localhost:9000/app/mutual-funds`; deferred load then **Explore funds** |
| 50 | ~14:42 | Observed MF shell | Secondary nav: BROWSE Explore (selected teal) / Holdings / History; ACCOUNT Onboarding / Systematic / STP·SWP; header "MUTUAL FUNDS · Invest · SIP · onboarding" |
| 51 | ~14:42 | Explore UI | Search placeholder; AMC chips HDFC…360 ONE; Growth/IDCW/All options; Asset Class All/Equity/Hybrid/Debt/Index; Buyable; returns 1Y; banner "Some EOD NAV dates… stale"; "Period returns not available yet." |
| 52 | ~14:42 | Top picks card 1 | **360 ONE BALANCED HYBRID FUND** Equity·Flexi Cap·Regular Growth; NAV ₹13.16 EOD; Min invest/SIP ₹1000; AUM ₹12.5K; ER 0.85%; ISIN INF579M01AV5; buttons SIP + **Invest** |
| 53 | ~14:42 | Top picks card 2 (partial) | Same fund Regular IDCW Payout peer |

---

## 7 — Onboarding (new-user path)

| # | Time (IST) | Action | Result |
|---|------------|--------|--------|
| 54 | ~14:42 | Click ACCOUNT → Onboarding (first attempts) | Missed / collapsed ACCOUNT section once |
| 55 | ~14:43 | Address bar → `http://localhost:9000/app/mutual-funds/onboarding` + Enter | Brief Explore flash then onboarding loads |
| 56 | ~14:44 | Observed Investor onboarding | Dig soft mode copy; stepper: **1 KYC check** (active orange) → eKYC → UCC+FATCA → Bank; fields PAN + Mobile (optional) empty; **Check KYC** greyed/disabled |
| 57 | ~14:46 | Click PAN field (after Mobile mis-focus / Shift+Tab false starts) | PAN focused (purple underline + caret) |
| 58 | ~14:47 | Type PAN `GYAPK8901K` | Value visible in PAN; **Check KYC** enabled (purple) |
| 59 | ~14:47 | Click **Check KYC** (retry after first miss → Mobile focus) | Spinner on button |
| 60 | ~14:48 | Wait ~3s | KYC step ✓ complete; advance to **2 eKYC**; copy "Starts NSE eKYC for PAN GYAPK8901K."; **Start eKYC** + **Skip**; UCC+FATCA / Bank still pending |
| 61 | ~14:48–14:50 | Multiple **Skip** click attempts (Flutter hit-target miss) | Still on eKYC |
| 62 | ~14:50 | Click **Start eKYC** (larger hit target) | Spinner; then advance to **3 UCC + FATCA** (eKYC soft advance despite dig fail) |
| 63 | ~14:51 | Observed UCC+FATCA form | Client code optional; Investor name; DOB*; Email; Bank; IFSC; Country/citizenship default **IN**; FATCA attestation checkbox; **Submit UCC (FATCA auto)** disabled until attested; footer **"An unexpected error occurred."** (from eKYC) |
| 64 | ~15:04 | Type DOB `15/08/1992` (field focused after zoom/click) | DOB shows value |
| 65 | ~15:04–15:23 | Investor name / Email / bank fill attempts | Flutter canvas focus flaky; Client code left blank (auto-gen); name/email/bank often empty |
| 66 | ~15:25–15:29 | Repeated FATCA attestation checkbox clicks (zoom + full-canvas + Tab) | Checkbox mostly stayed **unchecked**; Submit stayed disabled; one Tab cycle briefly looked checked then reverted |
| 67 | ~15:29 | Pivot: leave wizard; try **Explore → Invest** | Dig profile already UCC/FATCA/bank from 2026-11-23 API (`GYAPK8901K` / `GYAAN891`); trade gates use BFF flags not wizard draft |

---
