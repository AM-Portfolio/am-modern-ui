# TODO — `browser-zoom`

Pack: `docs/browser-zoom/`. Update this file in place. Resume from the first unchecked item.

## Plan loop (no impl until Agent satisfied + user confirm)

- [x] Find existing pack / Postman collection (patch, do not duplicate)
- [x] Branch on **lead** (`feature/browser-zoom`)
- [x] World-class feature map (P0/P1/P2)
- [x] First-run / virtual value UX (N/A)
- [x] Latency & consistency (N/A)
- [x] Corner-case matrix mapped to tests
- [x] Review roles filled
- [x] PLAN.md (no images/)
- [x] `architecture.drawio` via **am-architecture-drawio**
- [x] UI preview gate evaluated; **n/a — user asked no images**
- [x] Design sections filled; Open questions empty
- [x] Delivery 10/10 and Design 10/10
- [x] Scorecard overall ≥ 9.5 and all dims ≥ 9.0
- [x] Adversarial review: 0 Blocker / 0 Major
- [x] **Agent satisfied: yes**
- [x] Test Plan rows executable
- [x] **User reviewed** PLAN + architecture + TODO (no UI previews) and confirmed Execute

## Per service (unit-test loop)

### Service: `am-modern-ui` (existing)

- [x] Implement `BrowserZoomHost` + MediaQuery override (web)
- [x] Native browser Ctrl+/− / Ctrl+wheel (address-bar %); layoutWidthOf so desktop chrome does not collapse; no in-app zoom chip
- [x] Unit tests listed in PLAN written in this slice
- [x] `am test` / design-system tests **verified** (21 zoom/layout tests passed)
- [x] Loop while unit tests not verified (cap ~3, then pause)

## Deploy (fast — after impl)

- [x] Slot = **local** with prod config (`AM_ENV=prod`). No Helm.
- [ ] n/a — no `am deploy`
- [x] **Prod VPS:** not this slice

## Feature-test loop (Postman first)

- [x] **Analyze** — none; UI-only, no Postman
- [x] Local prod boot: `npm run run:app:9000:prod` → `http://localhost:9000` HTTP 200 (AM Investment Platform)
- [ ] Interactive Test Plan rows 1–7 in Chrome (zoom / maximize / chart wheel) — run on the live local server
- [x] Unit/widget tests passed (21)
- [x] Cap ~3 cycles per failure, then pause

## Report

- [ ] **Only after tests verified:** write `REPORT.md`

## Deploy (slow — after user satisfied)

- [x] Skipped — user asked local + prod config only

## PR

- [ ] PR only if the user asked
- [ ] `/review` then `/pr-ready`
