import 'package:am_dashboard_ui/domain/models/overlay_series_adapter.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen comparison chart opened from dashboard or market via deep link.
class ComparisonChartExpandedPage extends ConsumerStatefulWidget {
  const ComparisonChartExpandedPage({
    super.key,
    required this.chartContext,
    required this.timeFrameCode,
    required this.series,
    required this.userId,
  });

  final String chartContext;
  final String timeFrameCode;
  final List<String> series;
  final String userId;

  @override
  ConsumerState<ComparisonChartExpandedPage> createState() =>
      _ComparisonChartExpandedPageState();
}

class _ComparisonChartExpandedPageState
    extends ConsumerState<ComparisonChartExpandedPage> {
  Map<String, List<Map<String, dynamic>>> _marketHistorical = {};
  bool _loading = false;
  String? _error;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.chartContext == 'market') {
      _loadMarketHistory();
    }
  }

  Future<void> _loadMarketHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await _apiService.fetchHistoryBatch(widget.series, widget.timeFrameCode);
      if (!mounted) return;
      setState(() {
        _marketHistorical = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load chart data';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tf = widget.timeFrameCode;

    if (widget.chartContext == 'dashboard') {
      final state = ref.watch(dashboardOverlayProvider(widget.userId));
      final overlay = ref.read(dashboardOverlayProvider(widget.userId).notifier);
      return Scaffold(
        appBar: AppBar(title: const Text('Performance Chart')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ComparisonChartView(
            data: overlayStateToChartData(state),
            config: MultiSeriesChartConfig(
              preferredSeriesOrder: overlaySelectedLabels(state),
              embedMode: true,
              timeFrameCode: tf,
              showExpandButton: false,
              onRemoveSeries: (label) {
                for (final entry in state.series.entries) {
                  if (entry.value.label == label) {
                    overlay.removeSeries(entry.key);
                    return;
                  }
                }
              },
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Indices Comparison')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ComparisonChartView(
          data: MultiSeriesChartData.fromLegacyMaps(_marketHistorical),
          config: MultiSeriesChartConfig(
            selectedSeries: widget.series,
            isLoading: _loading,
            error: _error,
            timeFrameCode: tf,
            showExpandButton: false,
          ),
        ),
      ),
    );
  }
}
