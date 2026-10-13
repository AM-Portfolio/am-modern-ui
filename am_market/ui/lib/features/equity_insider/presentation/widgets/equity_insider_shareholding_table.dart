import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../../core/styles/market_theme_extension.dart';

class ShareholdingTrendTable extends StatelessWidget {
  final List<dynamic> shareholding;
  final bool dense;
  final int? highlightPeriodIndex;

  const ShareholdingTrendTable({
    super.key,
    required this.shareholding,
    this.dense = false,
    this.highlightPeriodIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (shareholding.isEmpty) return const SizedBox.shrink();

    final periods = shareholding
        .map((e) => (e is Map ? e['period'] : null)?.toString() ?? '---')
        .toList();

    final categories = <_ShareholdingCat>[
      _ShareholdingCat(
        label: 'Promoters',
        key: 'promotersPercent',
        color: context.marketTheme.positive,
      ),
      _ShareholdingCat(
        label: 'FII / Foreign',
        key: 'fiiPercent',
        color: ModuleColors.market,
      ),
      _ShareholdingCat(
        label: 'Mutual Funds',
        key: 'mutualFundsPercent',
        color: context.marketTheme.chartPurple,
      ),
      _ShareholdingCat(
        label: 'DII / Others',
        key: 'diiPercent',
        color: context.marketTheme.textSecondary,
      ),
      _ShareholdingCat(
        label: 'Retail & Public',
        key: 'retailAndOtherPercent',
        color: context.marketTheme.textMuted,
      ),
    ];

    final catW = dense ? 110.0 : 130.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isBounded = constraints.maxHeight.isFinite &&
            constraints.maxHeight < double.infinity;

        const pad = 12.0;
        final titleH = dense ? 16.0 : 20.0;
        final spacing = dense ? 6.0 : 8.0;

        final double rowH;
        final bool shouldScroll;

        if (isBounded) {
          final availableTableH =
              constraints.maxHeight - (pad * 2) - titleH - spacing;
          final rowCount = categories.length + 1; // 1 header + 5 categories
          final idealRowH = availableTableH / rowCount;

          if (idealRowH < 22.0) {
            rowH = 22.0;
            shouldScroll = true;
          } else {
            rowH = idealRowH.clamp(24.0, 36.0);
            shouldScroll = false;
          }
        } else {
          rowH = dense ? 24.0 : 28.0;
          shouldScroll = false;
        }

        Widget tableBody = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: catW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCell(
                    context,
                    'Category',
                    isFirst: true,
                    height: rowH,
                  ),
                  ...categories.map(
                    (cat) => _catCell(context, cat, height: rowH),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, colConstraints) {
                  final n = shareholding.length;

                  Widget col(int colIdx, {double? width}) {
                    final item = shareholding[colIdx] is Map
                        ? shareholding[colIdx] as Map
                        : {};
                    final highlighted = highlightPeriodIndex == colIdx;
                    final body = Column(
                      children: [
                        _headerCell(
                          context,
                          periods[colIdx],
                          height: rowH,
                          highlighted: highlighted,
                        ),
                        ...categories.map((cat) {
                          final num? val = item[cat.key] as num?;
                          return _dataCell(
                            context,
                            val != null ? '${val.toStringAsFixed(1)}%' : '—',
                            height: rowH,
                            highlighted: highlighted,
                          );
                        }),
                      ],
                    );
                    if (width != null) {
                      return SizedBox(width: width, child: body);
                    }
                    return Expanded(child: body);
                  }

                  return Row(
                    children: List.generate(n, (i) => col(i)),
                  );
                },
              ),
            ),
          ],
        );

        return Container(
          width: double.infinity,
          height: isBounded ? double.infinity : null,
          padding: const EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: context.cardColor,
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: isBounded ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dense ? 'Holding Trend' : 'Historical Holding Trend',
                      style: TextStyle(
                        fontSize: dense ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'QoQ %',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.textTertiary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              if (isBounded && !shouldScroll)
                Expanded(child: tableBody)
              else if (isBounded && shouldScroll)
                Expanded(child: SingleChildScrollView(child: tableBody))
              else
                tableBody,
            ],
          ),
        );
      },
    );
  }

  Widget _headerCell(
    BuildContext context,
    String text, {
    bool isFirst = false,
    required double height,
    bool highlighted = false,
  }) {
    return Container(
      height: height,
      alignment: isFirst ? Alignment.centerLeft : Alignment.center,
      decoration: BoxDecoration(
        color: highlighted ? ModuleColors.market.withValues(alpha: 0.08) : null,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: highlighted ? ModuleColors.market : context.textTertiary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _catCell(
    BuildContext context,
    _ShareholdingCat cat, {
    required double height,
  }) {
    return Container(
      height: height,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: cat.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              cat.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCell(
    BuildContext context,
    String text, {
    required double height,
    bool highlighted = false,
  }) {
    return Container(
      height: height,
      alignment: Alignment.center,
      color: highlighted ? ModuleColors.market.withValues(alpha: 0.06) : null,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
          color: context.textPrimary,
        ),
      ),
    );
  }
}

class _ShareholdingCat {
  final String label;
  final String key;
  final Color color;

  const _ShareholdingCat({
    required this.label,
    required this.key,
    required this.color,
  });
}
