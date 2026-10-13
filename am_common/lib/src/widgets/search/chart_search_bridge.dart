/// Chart terminal registers recent symbols + in-place [selectSymbol] so Global
/// Search can show chart history and update the active pane without remounting.
class ChartSearchBridge {
  ChartSearchBridge._();

  static List<String> recentSymbols = const [];
  static void Function(String symbol)? selectSymbol;

  static void bind({
    required List<String> recentSymbols,
    required void Function(String symbol) selectSymbol,
  }) {
    ChartSearchBridge.recentSymbols = List<String>.unmodifiable(recentSymbols);
    ChartSearchBridge.selectSymbol = selectSymbol;
  }

  static void unbind() {
    recentSymbols = const [];
    selectSymbol = null;
  }
}
