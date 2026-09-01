from pathlib import Path

root = Path(__file__).resolve().parents[1] / "lib/features/basket/presentation"
layouts = (root / "customize/customize_basket_layouts.dart").read_text(encoding="utf-8")

marker = "  // ---------------------------------------------------------------------------\n  // RIGHT SIDEBAR (desktop)"
idx = layouts.find(marker)
if idx == -1:
    raise SystemExit("marker not found")

main_part = layouts[:idx].rstrip() + "\n}\n"
sidebar_part = (
    "part of '../pages/manual_basket_creator_page.dart';\n\n"
    "extension _ManualBasketCreatorPageSidebar on _ManualBasketCreatorPageState {\n"
    + layouts[idx:]
)

(root / "customize/customize_basket_layouts.dart").write_text(main_part, encoding="utf-8")
(root / "customize/customize_basket_sidebar.dart").write_text(sidebar_part, encoding="utf-8")
print("split ok", len(main_part.splitlines()), len(sidebar_part.splitlines()))
