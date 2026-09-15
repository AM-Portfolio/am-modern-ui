# AM modern-ui page library (Stitch refs)

Growing visual catalog for Google Stitch. Agents must pick closest pages here as **references** before generating a new screen. Do not invent a new brand from DESIGN.md tokens alone.

Approved product-looking pages only. Do not dump every Flutter screenshot.

## Layout

```
docs/ui-pages/
  INDEX.md                 # lookup table — keep in sync
  README.md                # this file
  <module>/<slug>/
    preview.png            # required
    page.md                # job of the screen + Flutter widgets to match
    screen.html            # optional Stitch HTML
```

Modules: `shell/`, `auth/`, `dashboard/`, `market/`, `trade/`, `portfolio/`. Add a folder when a new module ships.

## How agents use this

Follow skill **am-stitch**:

1. Read [INDEX.md](INDEX.md) (glob this folder if INDEX is stale).
2. Pick the closest **1–3** pages (same module first, then same pattern: list, form, ticket, banner, empty).
3. Read those PNGs / `page.md` / HTML.
4. Prompt Stitch with DESIGN.md **and** a **Reference screens** block naming the paths and what to copy.
5. After the user **approves** the new mock: copy PNG (+ optional HTML + `page.md`) into `<module>/<slug>/` and append INDEX.

The catalog grows **only after approval**, not on failed generates.

## `page.md` (short)

- Screen job (first-run / empty / happy / error)
- Module accent
- Flutter widgets to match (`UnifiedSidebarScaffold`, glass cards, …)
- When to reuse this page as a Stitch ref
