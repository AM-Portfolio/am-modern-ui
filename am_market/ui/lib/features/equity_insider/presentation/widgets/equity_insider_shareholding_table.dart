import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../../core/styles/market_theme_extension.dart';

class ShareholdingTrendTable extends StatelessWidget {
  final List<dynamic> shareholding;

  const ShareholdingTrendTable({
    super.key,
    required this.shareholding,
  });

  @override
  Widget build(BuildContext context) {
    if (shareholding.isEmpty) return const SizedBox.shrink();

    final periods = shareholding
        .map((e) => (e is Map ? e['period'] : null)?.toString() ?? '---')
        .toList();

    final categories = <_ShareholdingCat>[
      _ShareholdingCat(label: 'Promoters', key: 'promotersPercent', color: context.marketTheme.positive),
      const _ShareholdingCat(label: 'FII / Foreign', key: 'fiiPercent', color: ModuleColors.market),
      _ShareholdingCat(label: 'Mutual Funds', key: 'mutualFundsPercent', color: context.marketTheme.chartPurple),
      _ShareholdingCat(label: 'DII / Others', key: 'diiPercent', color: context.marketTheme.textSecondary),
      _ShareholdingCat(label: 'Retail & Public', key: 'retailAndOtherPercent', color: context.marketTheme.textMuted),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historical Holding Trend',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              Text(
                'Quarter-on-Quarter %',
                style: TextStyle(
                  fontSize: 10,
                  color: context.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky category column
              SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headerCell(context, 'Category', isFirst: true),
                    ...categories.map((cat) => _catCell(context, cat)),
                  ],
                ),
              ),
              // Scrollable quarter columns
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(shareholding.length, (colIdx) {
                      final item = shareholding[colIdx] is Map ? shareholding[colIdx] as Map : {};
                      return SizedBox(
                        width: 85,
                        child: Column(
                          children: [
                            _headerCell(context, periods[colIdx]),
                            ...categories.map((cat) {
                              final num? val = item[cat.key] as num?;
                              return _dataCell(context, val != null ? '${val.toStringAsFixed(1)}%' : '---');
                            }),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String text, {bool isFirst = false}) {
    return Container(
      height: 28,
      alignment: isFirst ? Alignment.centerLeft : Alignment.center,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: context.textTertiary,
        ),
      ),
    );
  }

  Widget _catCell(BuildContext context, _ShareholdingCat cat) {
    return Container(
      height: 28,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
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

  Widget _dataCell(BuildContext context, String text) {
    return Container(
      height: 28,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
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
