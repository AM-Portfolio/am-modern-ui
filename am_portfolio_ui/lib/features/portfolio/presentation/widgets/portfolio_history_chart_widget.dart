import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';

import '../cubit/portfolio_history_cubit.dart';
import '../cubit/portfolio_history_state.dart';
import '../../internal/data/dtos/portfolio_snapshot_dto.dart';

class PortfolioHistoryChartWidget extends ConsumerStatefulWidget {
  const PortfolioHistoryChartWidget({
    super.key,
    required this.portfolioId,
    required this.timeFrame,
    this.height = 320,
  });

  final String? portfolioId;
  final TimeFrame timeFrame;
  final double height;

  @override
  ConsumerState<PortfolioHistoryChartWidget> createState() =>
      _PortfolioHistoryChartWidgetState();
}

class _PortfolioHistoryChartWidgetState
    extends ConsumerState<PortfolioHistoryChartWidget> {
  String _selectedBroker = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PortfolioHistoryChartWidget old) {
    super.didUpdateWidget(old);
    if (old.timeFrame != widget.timeFrame ||
        old.portfolioId != widget.portfolioId) {
      _selectedBroker = 'ALL'; // Reset broker tab on context change
      context.read<PortfolioHistoryCubit>().invalidate();
      _load();
    }
  }

  void _load() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PortfolioHistoryCubit>().loadHistory(
          widget.portfolioId,
          widget.timeFrame,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioHistoryCubit, PortfolioHistoryState>(
      builder: (context, state) {
        if (state is PortfolioHistoryLoading) return _buildShimmer();
        if (state is PortfolioHistoryError) return _buildError(state.message);
        if (state is PortfolioHistoryLoaded) return _buildContent(state);
        return _buildShimmer();
      },
    );
  }

  // ── Broker Tab Switcher ─────────────────────────────────────────────────

  Widget _buildBrokerTabs(List<String> brokers) {
    if (brokers.length <= 1) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: brokers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final broker = brokers[i];
          final isSelected = _selectedBroker == broker;
          return GestureDetector(
            onTap: () => setState(() => _selectedBroker = broker),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.withOpacity(0.35),
                ),
              ),
              child: Text(
                _brokerLabel(broker),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Chart Content ────────────────────────────────────────────────────────

  Widget _buildContent(PortfolioHistoryLoaded state) {
    if (state.snapshots.isEmpty) return _buildEmpty();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Broker tabs (only shown when > 1 broker exists)
        _buildBrokerTabs(state.availableBrokers),
        if (state.availableBrokers.length > 1) const SizedBox(height: 12),
        // Chart
        _selectedBroker == 'ALL'
            ? _buildMultiLineChart(state)
            : _buildSingleLineChart(state),
      ],
    );
  }

  /// ALL mode: one line per broker, using ChartLineData multi-line comparison
  Widget _buildMultiLineChart(PortfolioHistoryLoaded state) {
    // Group snapshots by brokerType → list of (index, date, close)
    final Map<String, List<CommonChartDataPoint>> brokerPoints = {};

    for (int i = 0; i < state.snapshots.length; i++) {
      final snap = state.snapshots[i];
      final label = _formatDate(snap.snapshotDate);
      for (final entry in snap.portfolios) {
        final broker = entry.brokerType ?? 'Unknown';
        brokerPoints.putIfAbsent(broker, () => []);
        brokerPoints[broker]!.add(CommonChartDataPoint(
          x: i.toDouble(),
          y: entry.close ?? 0,
          xLabel: label,
          yLabel: '₹${_formatNum(entry.close ?? 0)}',
        ));
      }
    }

    // One color per broker
    final colors = [
      AppColors.primary,
      const Color(0xFF4FC3F7), // light blue
      const Color(0xFFFFB74D), // amber
      const Color(0xFF81C784), // green
      const Color(0xFFBA68C8), // purple
    ];

    final lines = <ChartLineData>[];
    final brokerList = brokerPoints.keys.toList()..sort();
    for (int i = 0; i < brokerList.length; i++) {
      lines.add(ChartLineData(
        label: _brokerLabel(brokerList[i]),
        points: brokerPoints[brokerList[i]]!,
        color: colors[i % colors.length],
      ));
    }

    return CommonPerformanceChart(
      title: 'Portfolio Journey',
      primaryData: const [], // Bypassed — lines takes over
      lines: lines,
      height: widget.height,
      showGrid: true,
      enableScrolling: true,
    );
  }

  /// Single broker / specific portfolio: single line + ₹/% toggle
  Widget _buildSingleLineChart(PortfolioHistoryLoaded state) {
    // Filter snapshots to the selected broker only
    final List<CommonChartDataPoint> primaryPoints = [];
    final List<CommonChartDataPoint> secondaryPoints = [];

    double? firstValue;

    for (int i = 0; i < state.snapshots.length; i++) {
      final snap = state.snapshots[i];
      final label = _formatDate(snap.snapshotDate);

      double value;
      if (_selectedBroker == 'ALL') {
        value = snap.totalUserWealth ?? 0;
      } else {
        // Find matching broker entry
        final entry = snap.portfolios.firstWhere(
          (p) => p.brokerType == _selectedBroker,
          orElse: () => const PortfolioSnapshotEntryDto(close: 0),
        );
        value = entry.close ?? 0;
      }

      firstValue ??= value;
      final pct = (firstValue != 0)
          ? ((value - firstValue) / firstValue) * 100
          : 0.0;

      primaryPoints.add(CommonChartDataPoint(
        x: i.toDouble(),
        y: value,
        xLabel: label,
        yLabel: '₹${_formatNum(value)}',
      ));

      secondaryPoints.add(CommonChartDataPoint(
        x: i.toDouble(),
        y: pct,
        xLabel: label,
        yLabel: '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
      ));
    }

    return CommonPerformanceChart(
      title: _brokerLabel(_selectedBroker),
      primaryData: primaryPoints,
      secondaryData: secondaryPoints,
      primaryToggleLabel: '₹',
      secondaryToggleLabel: '%',
      height: widget.height,
      showGrid: true,
      enableScrolling: true,
    );
  }

  // ── Utility helpers ──────────────────────────────────────────────────────

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d').format(dt); // "Jun 9"
    } catch (_) {
      return raw;
    }
  }

  String _formatNum(double value) {
    if (value >= 1e7) return '${(value / 1e7).toStringAsFixed(2)}Cr';
    if (value >= 1e5) return '${(value / 1e5).toStringAsFixed(2)}L';
    return value.toStringAsFixed(0);
  }

  String _brokerLabel(String broker) {
    switch (broker.toUpperCase()) {
      case 'ALL':
        return 'All';
      case 'ZERODHA':
        return 'Zerodha';
      case 'DHAN':
        return 'Dhan';
      case 'GROWW':
        return 'Groww';
      case 'UPSTOX':
        return 'Upstox';
      default:
        return broker;
    }
  }

  // ── Loading / Error / Empty states ───────────────────────────────────────

  Widget _buildShimmer() => SizedBox(
        height: widget.height + 50,
        child: const Center(child: CircularProgressIndicator()),
      );

  Widget _buildError(String msg) => SizedBox(
        height: widget.height,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text('Could not load history',
                style: TextStyle(color: Colors.grey[600])),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );

  Widget _buildEmpty() => SizedBox(
        height: widget.height,
        child: const Center(
          child: Text('No history yet.\nCheck back after market close.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ),
      );
}
