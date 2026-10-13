import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'heatmap_view.dart';

/// Self-contained market heatmap widget for embedding in hosts (e.g. Chart Terminal).
/// Provides [MarketProvider] and ensures the requested [symbol] index constituents are loaded.
class MarketHeatmapWidget extends StatefulWidget {
  const MarketHeatmapWidget({
    super.key,
    this.provider,
    this.symbol,
    this.onSelectStock,
  });

  final MarketProvider? provider;
  final String? symbol;
  final ValueChanged<String>? onSelectStock;

  @override
  State<MarketHeatmapWidget> createState() => _MarketHeatmapWidgetState();
}

class _MarketHeatmapWidgetState extends State<MarketHeatmapWidget> {
  late MarketProvider _provider;
  bool _ownsProvider = false;

  @override
  void initState() {
    super.initState();
    if (widget.provider != null) {
      _provider = widget.provider!;
    } else {
      _provider = MarketProvider();
      _ownsProvider = true;
    }
    _ensureSymbolLoaded();
  }

  @override
  void didUpdateWidget(covariant MarketHeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider != null && widget.provider != _provider) {
      if (_ownsProvider) {
        _provider.dispose();
        _ownsProvider = false;
      }
      _provider = widget.provider!;
    }
    if (widget.symbol != oldWidget.symbol) {
      _ensureSymbolLoaded();
    }
  }

  void _ensureSymbolLoaded() {
    final sym = widget.symbol?.trim();
    if (sym != null && sym.isNotEmpty) {
      final current = _provider.currentIndexData?.indexSymbol;
      if (current == null || current.toUpperCase() != sym.toUpperCase()) {
        _provider.selectIndex(sym);
      }
    }
  }

  @override
  void dispose() {
    if (_ownsProvider) {
      _provider.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MarketProvider>.value(
      value: _provider,
      child: HeatmapView(onSelectStock: widget.onSelectStock),
    );
  }
}
