# Page index (Stitch refs)

One row per approved page. Agents pick **1–3** closest rows for each UI request (same module first, then same pattern).

If this table looks stale, glob `docs/ui-pages/**/*.png` and `**/page.md`.

| Module | Slug | States | Files | When to reuse |
|--------|------|--------|-------|----------------|
| auth | login | happy | `login/login.png` | Sign-in, session, device-link chrome |

## Pattern aliases

Use these when matching a user request if the slug is not an exact name:

| Pattern | Prefer |
|---------|--------|
| App chrome, FinDash tiles, glass prism sidebar | `shell/` |
| Sign-in, device link, session | `auth/` |
| Home / overview cards | `dashboard/` |
| Watchlist, quotes, depth | `market/` |
| Order ticket, paper banner, blotter | `trade/` |
| Holdings table, P&L, virtual cash | `portfolio/` |
