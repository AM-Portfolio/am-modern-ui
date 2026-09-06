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
  ConsumerState<EquityInsiderShareholding> createState() => _EquityInsiderShareholdingState();
}

class _EquityInsiderShareholdingState extends ConsumerState<EquityInsiderShareholding> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        asyncData.when(
          data: (shareholding) {
            if (shareholding == null || shareholding.isEmpty) return const SizedBox.shrink();

            _selectedQuarterIndex = _selectedQuarterIndex.clamp(0, shareholding.length - 1);
            final selected = shareholding[_selectedQuarterIndex] as Map;
            final slices = _getSlices(context, selected);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'Shareholding pattern'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(shareholding.length, (idx) {
                      final q = shareholding[idx] as Map;
                      final p = q['period'] ?? 'Q$idx';
                      final isSelected = idx == _selectedQuarterIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0, bottom: 12.0),
                        child: InkWell(
                          onTap: () => setState(() {
                            _selectedQuarterIndex = idx;
                            _activeIndex = -1;
                          }),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? ModuleColors.market : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? ModuleColors.market : context.borderColor,
                              ),
                            ),
                            child: Text(
                              p,
                              style: TextStyle(
                                color: isSelected ? Colors.white : context.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 350;
                      if (isMobile) {
                        return Column(
                          children: [
                            _buildChart(slices),
                            const SizedBox(height: 16),
                            _buildLegend(slices),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(flex: 40, child: _buildChart(slices)),
                          const SizedBox(width: 16),
                          Expanded(flex: 60, child: _buildLegend(slices)),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                ShareholdingTrendTable(shareholding: shareholding),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error loading shareholding: $e', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shareholding Pattern',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'See how ownership has evolved over time.',
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondary,
            ),
          ),
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
    add('Retail / Public', 'retailAndOtherPercent', context.marketTheme.textMuted);
    add('DII / Others', 'diiPercent', context.marketTheme.textSecondary);

    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  Widget _buildChart(List<_SliceData> slices) {
    return SizedBox(
      height: 140,
      child: Stack(
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
              centerSpaceRadius: 40,
              sections: slices.asMap().entries.map((entry) {
                final idx = entry.key;
                final data = entry.value;
                final isTouch = _activeIndex == idx;
                final radius = isTouch ? 30.0 : 20.0;
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
                    fontSize: 16,
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
      ),
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
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isTouch ? context.textPrimary.withValues(alpha: 0.04) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: data.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isTouch ? context.textPrimary : context.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${data.value.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
