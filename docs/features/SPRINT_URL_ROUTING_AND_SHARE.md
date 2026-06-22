# Feature Spec: URL Routing & Share Link

**Module:** `am_app` / `am_portfolio_ui` / `am_trade_ui` / `am_market` / `am_design_system`
**Sprint:** Next Sprint
**Status:** Implemented (enterprise path URLs with portfolio ID)
**Author:** AM Platform Team

---

## 1. Overview

The current app uses purely index-based `setState` navigation. No URL changes as the user moves between modules or module sub-pages. This spec covers:

1. **Migrate to `go_router`** — every screen and sub-page gets a proper URL.
2. **Module sidebar sub-page routing** — Portfolio, Trade, and Market sidebar tabs each produce a distinct URL.
3. **Share Link / Copy Link** — a `ShareLinkButton` widget that copies the current deep-link URL to clipboard.
4. **Redirect after login** — shared links preserve destination, redirect to the correct page after authentication.
5. **Fix mobile global navigation** — global bottom nav currently hidden for most modules on mobile.

---

## 2. Problems Being Solved

| Problem | Current Behaviour | Expected Behaviour |
|---|---|---|
| No URL change on navigation | URL stays at `/` for every screen | Each screen has its own path |
| Module sub-pages not addressable | Portfolio Holdings has no URL | `/app/portfolio/{portfolioId}/holdings` works |
| Can't share a deep link | Sharing the browser URL lands on login, loses destination | Shared URL restores portfolio + tab after login |
| Mobile global nav disappears | Only visible for Dashboard & Lab | Always visible on mobile |
| Browser back button broken | Back goes to OS, not previous module | Back navigates correctly through history |

---

## 3. URL Route Map

```
/login                          → LoginPage
/register                       → RegisterPage
/forgot-password                → ForgotPasswordPage
/reset-password                 → ResetPasswordPage

/app/dashboard                  → DashboardPage
/app/portfolio                  → redirect → /app/portfolio/overview (legacy tab-only)
/app/portfolio/:portfolioId/:tab → PortfolioWebScreen (canonical share URL)
/app/portfolio/:tab             → legacy tab-only; upgrades to 3-segment after portfolio load
/app/trade                      → redirect → /app/trade/portfolios
/app/trade/portfolios           → TradePortfolioDiscovery (no portfolio ID)
/app/trade/:portfolioId/:tab    → TradeWebScreen (canonical share URL)
/app/trade/:tab                 → legacy tab-only; upgrades to 3-segment after portfolio load
/app/market                     → redirect → /app/market/all-indices
/app/market/:tab                → MarketPage
/app/ai-chat                    → AiChatScreen
/app/lab                        → DiagnosticDashboardPage
/app/analysis                   → AnalysisDashboard
/app/doc-intel                  → DocIntelligenceScreen
/app/profile                    → ProfileSettingsPage
/app/subscription               → SubscriptionPricingScreen
```

### 3.1 Portfolio Tabs (`/app/portfolio/:tab`)

| `:tab` slug | Page |
|---|---|
| `overview` | PortfolioOverviewWebPage |
| `holdings` | PortfolioHoldingsWebPage |
| `analysis` | PortfolioAnalysisWebPage |
| `heatmap` | PortfolioHeatmapWebPage |
| `baskets` | PortfolioBasketsWebPage |

### 3.2 Trade Tabs (`/app/trade/:tab`)

| `:tab` slug | TradeViewType | Page |
|---|---|---|
| `portfolios` | portfolios | TradePortfolioDiscoveryTemplate |
| `holdings` | holdings | TradeHoldingsDashboardWebPage |
| `calendar` | calendar | TradeCalendarAnalyticsWebPage |
| `analysis` | analysis | TradeMetricsPage |
| `report` | report | TradeReportPage |
| `trades` | trades | TradeListWebPage |
| `journal` | journal | JournalWebPage |
| `market-analysis` | marketAnalysis | MarketAnalysis |
| `unified` | unified | TradeUnifiedViewPage |

### 3.3 Market Tabs (`/app/market/:tab`)

| `:tab` slug | MarketSidebar title |
|---|---|
| `all-indices` | All Indices |
| `major-indices` | Major Indices |
| `streamer` | Streamer |
| `instrument-explorer` | Instrument Explorer |
| `etf-explorer` | ETF Explorer |
| `heatmap-explorer` | Heatmap Explorer |
| `market-analysis` | Market Analysis |
| `analysis-dashboard` | Analysis Dashboard |
| `price-test` | Price Test |
| `admin` | Admin Dashboard |

---

## 4. Architecture

### 4.1 Router (`app_router.dart`)

```
AppRouter (GoRouter)
├── redirect guard  → /login if unauthenticated on /app/*
├── /login          → LoginPage
├── /register       → RegisterPage
├── /forgot-password
├── /reset-password
└── ShellRoute (AppShell)
    ├── /app/dashboard
    ├── /app/portfolio/:tab
    ├── /app/trade/:tab
    ├── /app/market/:tab
    ├── /app/ai-chat
    ├── /app/lab
    ├── /app/analysis
    ├── /app/doc-intel
    ├── /app/profile
    └── /app/subscription
```

### 4.2 AppShell Changes

- Receives a `child` widget from `ShellRoute` (replaces `_buildPage()` switch).
- `GlobalSidebar` taps call `context.go('/app/<module>')`.
- Active nav item derived from `GoRouterState.of(context).matchedLocation` instead of `_selectedIndex`.
- `showMobileGlobalBar` becomes simply `!isDesktop` (always shown on mobile).

### 4.3 Module Screen Changes

Each module screen (`PortfolioWebScreen`, `TradeWebScreen`, `MarketPage`) receives an `initialTab` string parameter from the router path param. On internal sidebar/tab change, calls `context.go('/app/<module>/$newTab')` to keep the URL in sync.

```dart
// Example: PortfolioWebScreen
class PortfolioWebScreen extends ConsumerStatefulWidget {
  final String initialTab;   // 'overview' | 'holdings' | 'analysis' | 'heatmap' | 'baskets'
  ...
}
```

### 4.4 Redirect After Login

```dart
// In GoRouter redirect:
if (!isAuthenticated && goingToApp) {
  return '/login?redirect=${state.uri}';
}

// In LoginPage after success:
final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
context.go(redirect ?? '/app/dashboard');
```

---

## 5. Share Link / Copy Link Feature

### 5.1 Widget: `ShareLinkButton`

New file: `am_design_system/lib/shared/widgets/share/share_link_button.dart`

- Reads current URL via `Uri.base.toString()` (exact browser address bar).
- **On tap:** copies URL to clipboard via `Clipboard.setData`, shows `SnackBar("Link copied")`.
- **On web mobile:** also attempts `navigator.share()` native sheet.
- Icon: `Icons.link_rounded` → animates to `Icons.check_rounded` for 2 seconds after copy.
- Fully self-contained, no params required beyond `BuildContext`.

```dart
// Usage — drop into any module header
ShareLinkButton()

// With label (optional)
ShareLinkButton(showLabel: true)  // shows "Copy link" text beside icon
```

### 5.2 Placement

| Module | Location of ShareLinkButton |
|---|---|
| Dashboard | Top-right of DashboardPage header |
| Portfolio | Top-right action row in PortfolioWebScreen |
| Trade | Top-right action row in TradeWebScreen |
| Market | Top-right action row in MarketPage |
| AI Chat | Top-right of AiChatScreen |
| All others | Top-right of each screen's content header |

### 5.3 GlobalSidebar Long-Press

Long-pressing any `_GlobalSidebarItem` shows a tooltip: `"Copy link to <Module>"` and copies the module's default URL to clipboard (e.g. `/app/portfolio/overview` for Portfolio).

---

## 6. Files to Change

| File | Change |
|---|---|
| `am_app/pubspec.yaml` | Add `go_router: ^14.x` |
| `am_app/lib/core/router/app_router.dart` | **Create** — full GoRouter definition |
| `am_app/lib/app.dart` | Replace `MaterialApp` → `MaterialApp.router` |
| `am_app/lib/features/shell/app_shell.dart` | ShellRoute `child`, `context.go()` on nav, fix mobile bar |
| `am_portfolio_ui/lib/.../portfolio_screen.dart` | Accept `initialTab` param |
| `am_portfolio_ui/lib/.../portfolio_web_screen.dart` | Push sub-route on tab change |
| `am_trade_ui/lib/.../trade_responsive_layout.dart` | Accept `initialTab` param |
| `am_trade_ui/lib/.../trade_web_screen.dart` | Push sub-route on tab change |
| `am_market/ui/lib/.../market_page.dart` | Accept `initialTab`, push sub-route |
| `am_design_system/lib/.../share_link_button.dart` | **Create** — ShareLinkButton widget |
| `am_design_system/lib/.../global_sidebar.dart` | Add long-press copy-link on each nav item |

---

## 7. Dependencies

| Package | Version | Reason |
|---|---|---|
| `go_router` | `^14.0.0` | URL routing and deep-linking |
| `flutter/services` | (SDK) | `Clipboard.setData` for copy |
| `url_launcher` (if not already) | latest | Web native share fallback |

---

## 8. Acceptance Criteria

- [ ] Navigating to any module changes the browser URL bar.
- [ ] Navigating to a module sub-page (e.g. Trade → Journal) changes URL to `/app/trade/journal`.
- [ ] Browser Back button navigates to the previous module/sub-page.
- [ ] Pasting `/app/portfolio/heatmap` in the browser bar lands on the Portfolio Heatmap tab (after login).
- [ ] Sharing a link to a page: recipient is redirected to login, then forwarded to the exact page after auth.
- [ ] `ShareLinkButton` copies correct URL and shows "Link copied" snack bar.
- [ ] GlobalSidebar long-press copies module default URL.
- [ ] Mobile global bottom nav visible on all module pages (not just Dashboard/Lab).
- [ ] Unauthenticated access to `/app/*` redirects to `/login`.
- [ ] Existing auth flow (login, register, forgot password) unchanged.

---

## 9. Out of Scope (this sprint)

- Landing / marketing page design.
- Portfolio-ID in the URL (e.g. `/app/portfolio/P123/holdings`).
- Trade-ID or journal-entry deep links.
- Push notifications with deep links.

---

## 10. Notes

- `go_router` will be added to `am_app` only. Module packages (`am_portfolio_ui`, `am_trade_ui`) receive `initialTab` as a plain `String` constructor param — they do not depend on `go_router` directly, keeping them decoupled.
- `ShareLinkButton` reads `GoRouterState` from context, so it requires `go_router` to be in scope. It lives in `am_design_system` but only uses `go_router` as a dev dependency when building the design system standalone; in the main app it inherits the router from `AMApp`.
