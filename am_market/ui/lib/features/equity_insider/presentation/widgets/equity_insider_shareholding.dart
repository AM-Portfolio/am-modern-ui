import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../../core/styles/market_theme_extension.dart';
import '../../providers/equity_insider_provider.dart';
import 'equity_insider_shareholding_table.dart';

class EquityInsiderShareholding extends ConsumerStatefulWidget {
  final String symbol;

  const EquityInsiderShareholding({super.key, required this.symbol});

  @override
  ConsumerState<EquityInsiderShareholding> createState() =>
      _EquityInsiderShareholdingState();
}

class _EquityInsiderShareholdingState
    extends ConsumerState<EquityInsiderShareholding> {
  int _activeIndex = -1;
  int _selectedQuarterIndex = 0;

  void _onClick(int index) {
    setState(() {
      _activeIndex = _activeIndex == index ? -1 : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(fundamentalShareholdingProvider(widget.symbol));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text(
        'Error loading shareholding: $e',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      data: (shareholding) {
        if (shareholding == null || shareholding.isEmpty) {
          return const SizedBox.shrink();
        }

        _selectedQuarterIndex =
            _selectedQuarterIndex.clamp(0, shareholding.length - 1);
        final selected = shareholding[_selectedQuarterIndex] as Map;
        final slices = _getSlices(context, selected);

        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.maxHeight.isFinite &&
                constraints.maxHeight < double.infinity;
            final sideBySide = constraints.maxWidth >= 560;

            final chips = _buildPeriodChips(shareholding);
            final trendTable = ShareholdingTrendTable(
              shareholding: shareholding,
              dense: true,
              highlightPeriodIndex: _selectedQuarterIndex,
            );

            if (!hasBoundedHeight) {
              // Equity Insider full page (unbounded scroll): stack naturally.
              final chartCard =
                  _buildChartCard(context, slices, expandChart: false);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCompactHeader(chips),
                  const SizedBox(height: 8),
                  if (sideBySide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 210, child: chartCard),
                        const SizedBox(width: 12),
                        Expanded(child: trendTable),
                      ],
                    )
                  else ...[
                    chartCard,
                    const SizedBox(height: 10),
                    trendTable,
                  ],
                ],
              );
            }

            // Chart bottom panel: fill full height, no dead space.
            final chartCard =
                _buildChartCard(context, slices, expandChart: true);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCompactHeader(chips),
                const SizedBox(height: 6),
                Expanded(
                  child: sideBySide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 210,
                              child: chartCard,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SingleChildScrollView(child: trendTable),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 168,
                              child: _buildChartCard(
                                context,
                                slices,
                                expandChart: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: SingleChildScrollView(child: trendTable),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCompactHeader(Widget chips) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Shareholding',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: chips),
      ],
    );
  }

  Widget _buildPeriodChips(List<dynamic> shareholding) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(shareholding.length, (idx) {
          final q = shareholding[idx] as Map;
          final p = q['period'] ?? 'Q$idx';
          final isSelected = idx == _selectedQuarterIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => setState(() {
                _selectedQuarterIndex = idx;
                _activeIndex = -1;
              }),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? ModuleColors.market : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isSelected ? ModuleColors.market : context.borderColor,
                  ),
                ),
                child: Text(
                  p.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : context.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    List<_SliceData> slices, {
    required bool expandChart,
  }) {
    final chart = SizedBox(
      width: 128,
      height: 128,
      child: _buildChart(slices),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: expandChart ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (expandChart)
            Expanded(child: Center(child: chart))
          else
            Center(child: chart),
          const SizedBox(height: 4),
          _buildLegend(slices),
        ],
      ),
    );
  }

  List<_SliceData> _getSlices(BuildContext context, Map latest) {
    final list = <_SliceData>[];

    void add(String label, String key, Color color) {
      final v = latest[key] as num?;
      if (v != null && v > 0) {
        list.add(_SliceData(label, v.toDouble(), color));
      }
    }

    add('Promoters', 'promotersPercent', context.marketTheme.positive);
    add('FII / Foreign', 'fiiPercent', ModuleColors.market);
    add('Mutual Funds', 'mutualFundsPercent', context.marketTheme.chartPurple);
    add('Retail / Public', 'retailAndOtherPercent',
        context.marketTheme.textMuted);
    add('DII / Others', 'diiPercent', context.marketTheme.textSecondary);

    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  Widget _buildChart(List<_SliceData> slices) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  return;
                }
                _onClick(pieTouchResponse.touchedSection!.touchedSectionIndex);
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 2.0,
            centerSpaceRadius: 36,
            sections: slices.asMap().entries.map((entry) {
              final idx = entry.key;
              final data = entry.value;
              final isTouch = _activeIndex == idx;
              final radius = isTouch ? 28.0 : 20.0;
              return PieChartSectionData(
                color: data.color,
                value: data.value,
                title: '',
                radius: radius,
              );
            }).toList(),
          ),
        ),
        if (_activeIndex >= 0 && _activeIndex < slices.length)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                slices[_activeIndex].label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: context.textSecondary,
                ),
              ),
              Text(
                '${slices[_activeIndex].value.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          )
        else
          Text(
            'Holdings',
            style: TextStyle(
              fontSize: 10,
              color: context.textTertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildLegend(List<_SliceData> slices) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: slices.asMap().entries.map((entry) {
        final idx = entry.key;
        final data = entry.value;
        final isTouch = _activeIndex == idx;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _onClick(idx),
          onExit: (_) => _onClick(-1),
          child: GestureDetector(
            onTap: () => _onClick(idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: isTouch
                    ? context.textPrimary.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: data.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isTouch
                            ? context.textPrimary
                            : context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${data.value.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SliceData {
  final String label;
  final double value;
  final Color color;

  _SliceData(this.label, this.value, this.color);
}
