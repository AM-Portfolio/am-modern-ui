#!/usr/bin/env python3
"""Split manual_basket_creator_page.dart into part files."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAGE = ROOT / "lib/features/basket/presentation/pages/manual_basket_creator_page.dart"
CUSTOMIZE = ROOT / "lib/features/basket/presentation/customize"

lines = PAGE.read_text(encoding="utf-8").splitlines(keepends=True)

# 1-based line numbers -> 0-based slices [start, end inclusive]
logic_slices = [(114, 244), (290, 602)]
layout_slices = [(247, 288), (722, 1611)]

logic_body = []
for start, end in logic_slices:
    logic_body.extend(lines[start - 1 : end])

layout_body = []
for start, end in layout_slices:
    layout_body.extend(lines[start - 1 : end])

(CUSTOMIZE / "customize_basket_logic.dart").write_text(
    "part of '../pages/manual_basket_creator_page.dart';\n\n"
    "extension _ManualBasketCreatorPageLogic on _ManualBasketCreatorPageState {\n"
    + "".join(logic_body)
    + "}\n",
    encoding="utf-8",
)

(CUSTOMIZE / "customize_basket_layouts.dart").write_text(
    "part of '../pages/manual_basket_creator_page.dart';\n\n"
    "extension _ManualBasketCreatorPageLayouts on _ManualBasketCreatorPageState {\n"
    + "".join(layout_body)
    + "}\n",
    encoding="utf-8",
)

# Rebuild main: through dispose (line 107), then build (607-720)
header_end = 107  # inclusive 1-based line number
main_header = []
skip_imports = (
    "package:intl/intl.dart",
    "portfolio_holding.dart",
    "basket_success_page.dart",
)
for line in lines[:header_end]:
    if any(s in line for s in skip_imports):
        continue
    main_header.append(line)

insert_at = 0
for i, line in enumerate(main_header):
    if line.startswith("import "):
        insert_at = i + 1

main_header[insert_at:insert_at] = [
    "import '../customize/customize_basket_formatters.dart';\n",
    "import '../customize/customize_basket_metrics.dart';\n",
    "import '../shared/basket_constituent_grouper.dart';\n",
    "import '../shared/basket_item_status_theme.dart';\n",
    "part '../customize/customize_basket_logic.dart';\n",
    "part '../customize/customize_basket_layouts.dart';\n",
    "\n",
]

main_body = lines[606:720]
main_content = "".join(main_header) + "".join(main_body) + "}\n"

PAGE.write_text(main_content, encoding="utf-8")

print(f"Wrote logic: {len(logic_body)} lines")
print(f"Wrote layouts: {len(layout_body)} lines")
print(f"Main page: {main_content.count(chr(10))} lines")
