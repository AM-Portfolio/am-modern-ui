import 'package:flutter/material.dart';

// import 'package:am_design_system/am_design_system.dart' as ui_config;
// import 'package:am_design_system/am_design_system.dart';
import '../../internal/domain/entities/portfolio_analytics.dart';
import '../mappers/sector_heatmap_converter.dart';

/// Widget displaying sector allocation overview with visual heatmap
/// Shows sector performance with color-coded rectangles representing sector weightage
class SectorOverviewCard extends StatelessWidget {
  const SectorOverviewCard({
    super.key,
    this.heatmap,
    this.isLoading = false,
    this.error,
    this.showSubCards = true,
  });
  final Heatmap? heatmap;
  final bool isLoading;
  final String? error;
  final bool showSubCards;

  @override
  Widget build(BuildContext context) {
    // Convert sector data to generic heatmap data
    final heatmapData = SectorHeatmapConverter.convertToHeatmapData(
      heatmap: heatmap,
      showSubCards: showSubCards,
    );

    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    // Create raw data for universal widget (commented out for now)
    // final rawData = <String, dynamic>{
    //   'holdings': heatmapData.tiles
    //       .map(
    //         (tile) => {
    //           'id': tile.id,
    //           'name': tile.name,
    //           'displayName': tile.displayName,
    //           'weightage': tile.weightage,
    //           'performance': tile.performance,
    //           'value': tile.value,
    //           'metadata': tile.metadata,
    //         },
    //       )
    //       .toList(),
    // };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart),
                const SizedBox(width: 8),
                Text(
                  heatmapData.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              // TODO: Re-enable UniversalHeatmapWidget when ready
              child: Center(
                child: Text(
                  'Heatmap temporarily disabled',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              // child: UniversalHeatmapWidget(
              //   investmentType: InvestmentType.portfolio,
              //   rawData: rawData,
              //   config: ui_config.HeatmapConfig.mobilePortfolio(),
              //   templateType: UniversalTemplateType.minimal,
              //   showSelectors: false,
              //   compactMode: true,
              // ),
            ),
          ],
        ),
      ),
    );
  }
}
