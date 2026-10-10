import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/am_text_styles.dart';
import 'package:am_market_common/models/indices_performance_model.dart';
import 'package:am_market_ui/features/market_analysis/services/market_analysis_service.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/monthly_performance_card.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/cylinder_month_scroller.dart';
import 'package:get_it/get_it.dart';

class HistoricalPerformanceSection extends StatefulWidget {
  const HistoricalPerformanceSection({
    Key? key,
    this.focusSymbol,
  }) : super(key: key);

  /// When set (e.g. pinned dashboard index), shown in the section title.
  final String? focusSymbol;

  @override
  State<HistoricalPerformanceSection> createState() =>
      _HistoricalPerformanceSectionState();
}

class _HistoricalPerformanceSectionState
    extends State<HistoricalPerformanceSection> {
  final MarketAnalysisService _service = GetIt.I<MarketAnalysisService>();
  late Future<IndicesHistoricalPerformanceResponse> _future;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _future = _service.getIndicesHistoricalPerformance(years: 10);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scroll(double offset) {
    _scrollController.animateTo(
      (_scrollController.offset + offset)
          .clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final hasBoundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        final header = Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.focusSymbol != null &&
                          widget.focusSymbol!.trim().isNotEmpty
                      ? 'Historical Monthly Performance · ${widget.focusSymbol}'
                      : 'Historical Monthly Performance (10 Years)',
                  style: AmTextStyles.h6.copyWith(
                    color: context.colors.textPrimary,
                    fontSize: isMobile ? 14 : 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isMobile)
                Text(
                  'Scroll to view more months  ➡',
                  style: TextStyle(
                    color: context.colors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        );

        final table = FutureBuilder<IndicesHistoricalPerformanceResponse>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(color: context.statusError))));
            }
            if (!snapshot.hasData ||
                snapshot.data!.monthlyPerformance.isEmpty) {
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('No data available',
                          style:
                              TextStyle(color: context.colors.textSecondary))));
            }

            final data = snapshot.data!.monthlyPerformance;

            // Group data by Year
            final Map<int, Map<String, MonthlyIndicesPerformance>> groupedData =
                {};
            for (var item in data) {
              if (!groupedData.containsKey(item.year)) {
                groupedData[item.year] = {};
              }
              groupedData[item.year]![item.monthName.toUpperCase()] = item;
            }

            // Sort years descending
            final sortedYears = groupedData.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            final months = [
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
              'DECEMBER'
            ];
            final shortMonths = [
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
              'DEC'
            ];

            // Dimensions — fill available width on desktop so months
            // don't leave a large empty strip on the right.
            final double yearColWidth = isMobile ? 44.0 : 60.0;
            final double arrowReserve = isMobile ? 0.0 : 96.0;
            final double availableForMonths =
                (constraints.maxWidth - yearColWidth - arrowReserve)
                    .clamp(600.0, double.infinity);
            final double cellWidth = isMobile
                ? 140.0
                : (availableForMonths / 12).clamp(120.0, 200.0);

            // ── MOBILE: Cylinder drum-roll layout ─────────────────
            if (isMobile) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pinned YEAR column — tight against month scroller
                  SizedBox(
                    width: yearColWidth,
                    child: Column(
                      children: [
                        Container(
                          height: 36.0,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            color: context.colors.cardSurface
                                .withValues(alpha: 0.70),
                            border: Border(
                              bottom: BorderSide(
                                color: context.colors.border
                                    .withValues(alpha: 0.35),
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'YEAR',
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...sortedYears.map((year) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SizedBox(
                              height: 34,
                              child: Center(
                                child: Text(
                                  '$year',
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Months start flush beside YEAR (left-aligned scroller)
                  Expanded(
                    child: CylinderMonthScroller(
                      months: months,
                      shortMonths: shortMonths,
                      sortedYears: sortedYears,
                      groupedData: groupedData,
                      rowHeight: 34.0,
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            }

            // ── DESKTOP: Standard horizontal scroll with arrow buttons ─
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios,
                        color: context.colors.textSecondary),
                    onPressed: () => _scroll(-300),
                  ),
                ),
                SizedBox(
                  width: yearColWidth,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color: context.colors.cardSurface
                              .withValues(alpha: 0.70),
                          border: Border(
                            bottom: BorderSide(
                              color:
                                  context.colors.border.withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'YEAR',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...sortedYears.map((year) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            height: 34,
                            child: Center(
                              child: Text(
                                '$year',
                                style: TextStyle(
                                    color: context.colors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: cellWidth * 12,
                        child: Column(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                color: context.colors.cardSurface
                                    .withValues(alpha: 0.70),
                                border: Border(
                                  bottom: BorderSide(
                                    color: context.colors.border
                                        .withValues(alpha: 0.35),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: shortMonths
                                    .map((m) => SizedBox(
                                          width: cellWidth,
                                          child: Center(
                                            child: Text(
                                              m,
                                              style: TextStyle(
                                                color: context
                                                    .colors.textSecondary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...sortedYears.map((year) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: SizedBox(
                                  height: 34,
                                  child: Row(
                                    children: months.map((month) {
                                      final item = groupedData[year]?[month];
                                      return SizedBox(
                                        width: cellWidth,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0),
                                          child: item != null
                                              ? MonthlyPerformanceCard(
                                                  data: item,
                                                  isCompactTable: true)
                                              : Container(
                                                  decoration: BoxDecoration(
                                                      color: context
                                                          .colors.surface
                                                          .withValues(
                                                              alpha: 0.5),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8))),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: IconButton(
                    icon: Icon(Icons.arrow_forward_ios,
                        color: context.colors.textSecondary),
                    onPressed: () => _scroll(300),
                  ),
                ),
              ],
            );
          },
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            header,
            if (hasBoundedHeight)
              Expanded(
                child: SingleChildScrollView(
                  child: table,
                ),
              )
            else
              table,
          ],
        );
      },
    );
  }
}
