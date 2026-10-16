import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/shared/widgets/index_heatmap_panel.dart';

/// Self-contained market heatmap for Chart Terminal (and similar embeds).
///
/// Uses the same [IndexHeatmapPanel] / [loadDashboardIndexHeatmap] path as the
/// Market dashboard — overflow-safe tiles, no Heatmap Focus Mode.
class MarketHeatmapWidget extends StatefulWidget {
  const MarketHeatmapWidget({
    super.key,
    this.provider,
    this.symbol,
    this.timeframe = '1D',
    this.onSelectStock,
  });

  final MarketProvider? provider;
  final String? symbol;
  final String timeframe;
  final ValueChanged<String>? onSelectStock;

  @override
  State<MarketHeatmapWidget> createState() => _MarketHeatmapWidgetState();
}

class _MarketHeatmapWidgetState extends State<MarketHeatmapWidget> {
  late MarketProvider _provider;
  bool _ownsProvider = false;
  String? _emptyReason;

  @override
  void initState() {
    super.initState();
    if (widget.provider != null) {
      _provider = widget.provider!;
    } else {
      _provider = MarketProvider();
      _ownsProvider = true;
    }
    _validateSymbol();
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
      _validateSymbol();
    }
  }

  bool _isKnownIndex(String sym) {
    final u = sym.trim().toUpperCase();
    if (u.isEmpty) return false;
    bool match(Iterable list) => list.any((idx) {
          try {
            return (idx.indexSymbol as String).toUpperCase() == u;
          } catch (_) {
            return false;
          }
        });
    if (match(_provider.allIndicesData) || match(_provider.globalIndicesData)) {
      return true;
    }
    return u.contains('NIFTY') ||
        u.contains('SENSEX') ||
        u.contains('BANKNIFTY') ||
        u.contains('FINNIFTY') ||
        u.startsWith('INDIA VIX');
  }

  void _validateSymbol() {
    final sym = widget.symbol?.trim();
    if (sym == null || sym.isEmpty) {
      setState(() => _emptyReason = 'Select an index to view the heatmap');
      return;
    }
    if (!_isKnownIndex(sym)) {
      setState(() {
        _emptyReason =
            'Heatmap is available for indices. Select an index (e.g. NIFTY 50).';
      });
      return;
    }
    setState(() => _emptyReason = null);
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
    if (_emptyReason != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _emptyReason!,
            textAlign: TextAlign.center,
            style: TextStyle(color: MarketColors.textMuted(context)),
          ),
        ),
      );
    }

    final sym = widget.symbol!.trim();
    return ChangeNotifierProvider<MarketProvider>.value(
      value: _provider,
      child: IndexHeatmapPanel(
        indexSymbol: sym,
        timeframe: widget.timeframe,
        onSelectStock: widget.onSelectStock,
        embedCompact: true,
        showPercentFilters: true,
        title: 'Market Heatmap · $sym',
      ),
    );
  }
}
