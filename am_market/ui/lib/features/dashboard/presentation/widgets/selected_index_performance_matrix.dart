import 'dart:math' as math;

import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/models/historical_performance_model.dart';
import 'package:am_market_common/services/api_service.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';

/// Ten-year monthly returns for one dashboard index, never aggregate rankings.
class SelectedIndexPerformanceMatrix extends StatefulWidget {
  const SelectedIndexPerformanceMatrix({
    super.key,
    required this.symbol,
    this.fetchPerformance,
  });

  final String symbol;

  /// Injectable to cover symbol changes and late responses without HTTP.
  final Future<HistoricalPerformanceResponse> Function(String symbol)?
      fetchPerformance;

  @override
  State<SelectedIndexPerformanceMatrix> createState() =>
      _SelectedIndexPerformanceMatrixState();
}

class _SelectedIndexPerformanceMatrixState
    extends State<SelectedIndexPerformanceMatrix> {
  static const _months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];
  static const _shortMonths = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  final ScrollController _horizontal = ScrollController();
  ApiService? _api;
  HistoricalPerformanceResponse? _data;
  Object? _error;
  bool _loading = true;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SelectedIndexPerformanceMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol ||
        oldWidget.fetchPerformance != widget.fetchPerformance) {
      _load();
      if (_horizontal.hasClients) _horizontal.jumpTo(0);
    }
  }

  Future<void> _load() async {
    final generation = ++_requestGeneration;
    final symbol = widget.symbol;
    setState(() {
      _loading = true;
      _data = null;
      _error = null;
    });
    try {
      final data = await (widget.fetchPerformance?.call(symbol) ??
          (_api ??= ApiService()).fetchHistoricalPerformance(symbol, years: 10));
      if (!mounted ||
          generation != _requestGeneration ||
          symbol != widget.symbol) {
        return;
      }
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted ||
          generation != _requestGeneration ||
          symbol != widget.symbol) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _requestGeneration++;
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = ModuleColors.market;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historical Monthly Performance · ${widget.symbol}',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_loading)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(color: accent)),
            )
          else if (_error != null)
            _message(
              context,
              'Could not load ${widget.symbol} performance.',
              retry: true,
            )
          else if (_data == null || _data!.yearlyPerformance.isEmpty)
            _message(context,
                'No historical performance is available for ${widget.symbol}.')
          else
            _buildMatrix(context, _data!),
        ],
      ),
    );
  }

  Widget _message(BuildContext context, String message, {bool retry = false}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            Text(message,
                style: TextStyle(color: context.colors.textSecondary)),
            if (retry)
              TextButton(
                onPressed: _load,
                child:
                    Text('Retry', style: TextStyle(color: ModuleColors.market)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrix(
      BuildContext context, HistoricalPerformanceResponse data) {
    final years = [...data.yearlyPerformance]
      ..sort((a, b) => b.year.compareTo(a.year));
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AmBreakpoints.mobile;
    final colors = context.colors;
    final overall = data.overallReturn;
    final totalColor = overall == null || overall == 0
        ? colors.textSecondary
        : overall > 0
            ? context.marketTheme.positive
            : context.marketTheme.negative;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          overall == null
              ? 'Overall Return (${data.startYear}-${data.endYear}): -'
              : 'Overall Return (${data.startYear}-${data.endYear}): '
                  '${overall.toStringAsFixed(2)}%',
          style: TextStyle(
              color: totalColor,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 18),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isMobile)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text('Swipe to see more months →',
                style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final yearWidth = isMobile ? 44.0 : 60.0;
            final available = math.max(0.0, constraints.maxWidth - yearWidth);
            final cellWidth = isMobile ? 76.0 : math.max(78.0, available / 13);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: yearWidth,
                  child: Column(
                    children: [
                      _yearLabel(context, 'YEAR', header: true),
                      for (final year in years)
                        _yearLabel(context, '${year.year}'),
                    ],
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _horizontal,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _horizontal,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: cellWidth * 13,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 36,
                              child: Row(
                                children: [
                                  for (final month in _shortMonths)
                                    _columnLabel(context, month, cellWidth),
                                  _columnLabel(context, 'YEAR %', cellWidth),
                                ],
                              ),
                            ),
                            for (final year in years)
                              SizedBox(
                                height: 44,
                                child: Row(
                                  children: [
                                    for (var i = 0; i < _months.length; i++)
                                      _returnCell(context,
                                          value:
                                              year.monthlyReturns[_months[i]],
                                          label:
                                              '${_shortMonths[i]} ${year.year}',
                                          width: cellWidth,
                                          decimals: 1),
                                    _returnCell(context,
                                        value: year.yearlyReturn,
                                        label: 'Total ${year.year}',
                                        width: cellWidth,
                                        decimals: 2,
                                        total: true),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _yearLabel(BuildContext context, String text, {bool header = false}) {
    return SizedBox(
      height: header ? 36 : 44,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: TextStyle(
              color: header
                  ? context.colors.textSecondary
                  : context.colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: header ? 10 : 12,
            )),
      ),
    );
  }

  Widget _columnLabel(BuildContext context, String text, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(text,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }

  Widget _returnCell(
    BuildContext context, {
    required double? value,
    required String label,
    required double width,
    required int decimals,
    bool total = false,
  }) {
    final colors = context.colors;
    final base = value == null || value == 0
        ? colors.cardSurface
        : value > 0
            ? context.marketTheme.positive
            : context.marketTheme.negative;
    final background =
        value == null || value == 0 ? base : base.withValues(alpha: 0.55);
    final formatted = value == null ? '-' : value.toStringAsFixed(decimals);
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs, vertical: AppSpacing.xs),
        child: Semantics(
          label:
              '$label: ${value == null ? 'unavailable' : '$formatted percent'}',
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border:
                  total ? Border.all(color: base.withValues(alpha: 0.7)) : null,
            ),
            child: Text(formatted,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ),
      ),
    );
  }
}
