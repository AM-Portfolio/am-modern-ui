import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../../core/styles/market_theme_extension.dart';
import '../../providers/equity_insider_provider.dart';

class EquityInsiderShareholding extends ConsumerStatefulWidget {
  final String symbol;

  const EquityInsiderShareholding({super.key, required this.symbol});

  @override
  ConsumerState<EquityInsiderShareholding> createState() => _EquityInsiderShareholdingState();
}

class _EquityInsiderShareholdingState extends ConsumerState<EquityInsiderShareholding> {
  int _activeIndex = -1;

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

            final latest = shareholding.first as Map;
            final period = latest['period'] ?? 'Latest';
            
            final slices = _getSlices(context, latest);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'Shareholding pattern — $period'),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    border: Border.all(color: context.borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 500;
                      if (isMobile) {
                        return Column(
                          children: [
                            _buildChart(slices),
                            const SizedBox(height: 24),
                            _buildLegend(slices),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 220, child: _buildChart(slices)),
                          const SizedBox(width: 60),
                          SizedBox(width: 250, child: _buildLegend(slices)),
                        ],
                      );
                    },
                  ),
                ),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: context.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: context.borderColor,
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

    add('FII / Foreign', 'fiiPercent', context.marketTheme.chartBlue);
    add('Promoters', 'promotersPercent', context.marketTheme.positive);
    add('Mutual Funds', 'mutualFundsPercent', context.marketTheme.chartPurple);
    add('Retail / Public', 'retailAndOtherPercent', context.marketTheme.textMuted);
    add('DII / Others', 'diiPercent', context.marketTheme.textSecondary);

    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  Widget _buildChart(List<_SliceData> slices) {
    return SizedBox(
      height: 220,
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
              sectionsSpace: 3,
              centerSpaceRadius: 65,
              sections: slices.asMap().entries.map((entry) {
                final idx = entry.key;
                final data = entry.value;
                final isTouch = _activeIndex == idx;
                final radius = isTouch ? 40.0 : 30.0;
                return PieChartSectionData(
                  color: data.color,
                  value: data.value,
                  title: '', // We don't show title on chart itself
                  radius: radius,
                );
              }).toList(),
            ),
          ),
          // Center Text
          if (_activeIndex >= 0 && _activeIndex < slices.length)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slices[_activeIndex].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  '${slices[_activeIndex].value.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 22,
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
                fontSize: 12,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isTouch ? context.textPrimary.withValues(alpha: 0.04) : context.cardColor.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: data.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: isTouch ? context.textPrimary : context.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${data.value.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
