import 'package:am_common/am_common.dart';
import 'package:flutter/widgets.dart';

/// Bridge for host-injected Market pages to publish their visible symbols.
class MarketStreamSurfaceScope extends InheritedWidget {
  const MarketStreamSurfaceScope({
    super.key,
    required this.onSymbolsChanged,
    required super.child,
  });

  final ValueChanged<Iterable<MarketStreamInstrument>> onSymbolsChanged;

  static void publish(
    BuildContext context,
    Iterable<MarketStreamInstrument> instruments,
  ) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<MarketStreamSurfaceScope>();
    scope?.onSymbolsChanged(instruments);
  }

  @override
  bool updateShouldNotify(MarketStreamSurfaceScope oldWidget) =>
      onSymbolsChanged != oldWidget.onSymbolsChanged;
}
