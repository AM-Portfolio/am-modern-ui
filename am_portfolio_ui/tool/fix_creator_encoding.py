from pathlib import Path

root = Path(__file__).resolve().parents[1] / "lib/features/basket/presentation/customize"

for path in [root / "customize_basket_logic.dart", root / "customize_basket_layouts.dart"]:
    text = path.read_text(encoding="utf-8")
    text = text.replace("â‚¹", "₹").replace("â€”", "—").replace("â€¢", "•")
    text = text.replace("_formatPreset(preset)", "CustomizeBasketFormatters.formatPreset(preset)")
    text = text.replace("_investedText(item)", "CustomizeBasketFormatters.investedText(item)")
    text = text.replace(
        "formatCurrency: (val) => '₹${val.toStringAsFixed(0)}'",
        "formatCurrency: CustomizeBasketFormatters.formatRupee",
    )
    path.write_text(text, encoding="utf-8")

# Remove unused helpers from logic (delegated to shared classes)
logic = root / "customize_basket_logic.dart"
t = logic.read_text(encoding="utf-8")
# Remove _getTabItems, _formatPreset, _investedText method blocks - optional keep for now

# Remove _buildStatsStrip from layouts (unused)
layouts = root / "customize_basket_layouts.dart"
lt = layouts.read_text(encoding="utf-8")
start = lt.find("  Widget _buildStatsStrip(")
end = lt.find("  // ---------------------------------------------------------------------------\n  // DESKTOP TABLE HEADER", start)
if start != -1 and end != -1:
    lt = lt[:start] + lt[end:]
    layouts.write_text(lt, encoding="utf-8")

print("fixed")
