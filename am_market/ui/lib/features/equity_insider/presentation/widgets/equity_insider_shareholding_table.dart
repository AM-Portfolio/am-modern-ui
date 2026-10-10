import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../../core/styles/market_theme_extension.dart';

class ShareholdingTrendTable extends StatefulWidget {
  final List<dynamic> shareholding;

  const ShareholdingTrendTable({
    super.key,
    required this.shareholding,
  });

  @override
  State<ShareholdingTrendTable> createState() => _ShareholdingTrendTableState();
}

class _ShareholdingTrendTableState extends State<ShareholdingTrendTable> {
  final ScrollController _quarterScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatestQuarters());
  }

  @override
  void didUpdateWidget(covariant ShareholdingTrendTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shareholding.length != widget.shareholding.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatestQuarters());
    }
  }

  void _scrollToLatestQuarters() {
    if (!_quarterScrollController.hasClients) return;
    _quarterScrollController.jumpTo(_quarterScrollController.position.maxScrollExtent);
  }

  @override
  void dispose() {
    _quarterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shareholding.isEmpty) return const SizedBox.shrink();

    final periods = widget.shareholding
        .map((e) => (e is Map ? e['period'] : null)?.toString() ?? '---')
        .toList();

    final categories = <_ShareholdingCat>[
      _ShareholdingCat(label: 'Promoters', key: 'promotersPercent', color: context.marketTheme.positive),
      _ShareholdingCat(label: 'FII / Foreign', key: 'fiiPercent', color: ModuleColors.market),
      _ShareholdingCat(label: 'Mutual Funds', key: 'mutualFundsPercent', color: context.marketTheme.chartPurple),
      _ShareholdingCat(label: 'DII / Others', key: 'diiPercent', color: context.marketTheme.textSecondary),
      _ShareholdingCat(label: 'Retail & Public', key: 'retailAndOtherPercent', color: context.marketTheme.textMuted),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AmBreakpoints.mobile;
        final rowHeight = isMobile ? 38.0 : 28.0;
        const categoryWidth = 130.0;
        final quarterColWidth = isMobile
            ? ((constraints.maxWidth - categoryWidth - 24) / 3).clamp(72.0, 96.0)
            : 85.0;

        return Container(
          padding: EdgeInsets.all(isMobile ? 10 : 12),
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
                  SizedBox(
                    width: categoryWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _headerCell(context, 'Category', rowHeight: rowHeight, isFirst: true),
                        ...categories.map((cat) => _catCell(context, cat, rowHeight: rowHeight)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _quarterScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(widget.shareholding.length, (colIdx) {
                          final item =
                              widget.shareholding[colIdx] is Map ? widget.shareholding[colIdx] as Map : {};
                          return SizedBox(
                            width: quarterColWidth,
                            child: Column(
                              children: [
                                _headerCell(context, periods[colIdx], rowHeight: rowHeight),
                                ...categories.map((cat) {
                                  final num? val = item[cat.key] as num?;
                                  return _dataCell(
                                    context,
                                    val != null ? '${val.toStringAsFixed(1)}%' : '—',
                                    rowHeight: rowHeight,
                                  );
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
      },
    );
  }

  Widget _headerCell(
    BuildContext context,
    String text, {
    required double rowHeight,
    bool isFirst = false,
  }) {
    return Container(
      height: rowHeight,
      alignment: isFirst ? Alignment.centerLeft : Alignment.center,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor.withValues(alpha: 0.5))),
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

  Widget _catCell(BuildContext context, _ShareholdingCat cat, {required double rowHeight}) {
    return Container(
      height: rowHeight,
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

  Widget _dataCell(BuildContext context, String text, {required double rowHeight}) {
    return Container(
      height: rowHeight,
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
