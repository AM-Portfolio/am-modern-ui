/// Card renderer and factory for universal calendar
library;

import 'package:flutter/material.dart';

import 'card_types.dart' as calendar_types;

/// Factory for creating calendar card widgets
class CalendarCardFactory {
  static Widget createCard({
    required calendar_types.CalendarCardConfig config,
    required calendar_types.CardData data,
    VoidCallback? onTap,
    Map<String, dynamic>? customization,
  }) => CalendarCard(
    config: config,
    data: data,
    onTap: onTap,
    customization: customization,
  );

  static List<Widget> createCardGrid({
    required List<calendar_types.CalendarCardConfig> configs,
    required Map<String, List<calendar_types.CardData>> dataMap,
    required String dateKey,
    Function(calendar_types.CalendarCardConfig, calendar_types.CardData)?
    onCardTap,
    int crossAxisCount = 2,
  }) {
    final cards = <Widget>[];

    for (final config in configs) {
      final cardDataList = dataMap[dateKey] ?? [];
      final cardData = cardDataList.firstWhere(
        (data) => _isCardDataForConfig(data, config),
        orElse: () => _createEmptyCardData(dateKey, config.type),
      );

      cards.add(
        CalendarCard(
          config: config,
          data: cardData,
          onTap: onCardTap != null ? () => onCardTap(config, cardData) : null,
        ),
      );
    }

    return cards;
  }

  static bool _isCardDataForConfig(
    calendar_types.CardData data,
    calendar_types.CalendarCardConfig config,
  ) {
    switch (config.type) {
      case calendar_types.CalendarCardType.pnlSummary:
      case calendar_types.CalendarCardType.tradeMetrics:
      case calendar_types.CalendarCardType.winLossRatio:
      case calendar_types.CalendarCardType.riskReward:
      case calendar_types.CalendarCardType.tradeVolume:
        return data is calendar_types.TradeCardData;
      case calendar_types.CalendarCardType.portfolioValue:
      case calendar_types.CalendarCardType.assetAllocation:
      case calendar_types.CalendarCardType.portfolioPerformance:
      case calendar_types.CalendarCardType.diversification:
        return data is calendar_types.PortfolioCardData;
      default:
        return true;
    }
  }

  static calendar_types.CardData _createEmptyCardData(
    String dateKey,
    calendar_types.CalendarCardType type,
  ) {
    switch (type) {
      case calendar_types.CalendarCardType.pnlSummary:
      case calendar_types.CalendarCardType.tradeMetrics:
      case calendar_types.CalendarCardType.winLossRatio:
      case calendar_types.CalendarCardType.riskReward:
      case calendar_types.CalendarCardType.tradeVolume:
        return calendar_types.TradeCardData(
          dateKey: dateKey,
          pnl: 0,
          tradeCount: 0,
          winCount: 0,
          lossCount: 0,
        );
      case calendar_types.CalendarCardType.portfolioValue:
      case calendar_types.CalendarCardType.assetAllocation:
      case calendar_types.CalendarCardType.portfolioPerformance:
      case calendar_types.CalendarCardType.diversification:
        return calendar_types.PortfolioCardData(
          dateKey: dateKey,
          totalValue: 0,
          dailyChange: 0,
          dailyChangePercent: 0,
        );
      default:
        return calendar_types.CustomCardData(
          dateKey: dateKey,
          title: 'Empty',
          value: '--',
        );
    }
  }
}

/// Universal calendar card widget
class CalendarCard extends StatelessWidget {
  const CalendarCard({
    required this.config,
    required this.data,
    super.key,
    this.onTap,
    this.customization,
  });

  final calendar_types.CalendarCardConfig config;
  final calendar_types.CardData data;
  final VoidCallback? onTap;
  final Map<String, dynamic>? customization;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: config.isInteractive ? onTap : null,
    child: Container(
      constraints: _getCardConstraints(),
      decoration: _getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config.showHeader) _buildHeader(context),
          Expanded(child: _buildContent(context)),
          if (config.showFooter) _buildFooter(context),
        ],
      ),
    ),
  );

  BoxConstraints _getCardConstraints() {
    switch (config.size) {
      case calendar_types.CardSizeType.small:
        return const BoxConstraints(
          minWidth: 80,
          maxWidth: 120,
          minHeight: 60,
          maxHeight: 80,
        );
      case calendar_types.CardSizeType.medium:
        return const BoxConstraints(
          minWidth: 160,
          maxWidth: 200,
          minHeight: 120,
          maxHeight: 150,
        );
      case calendar_types.CardSizeType.large:
        return const BoxConstraints(
          minWidth: 240,
          maxWidth: 300,
          minHeight: 180,
          maxHeight: 220,
        );
      case calendar_types.CardSizeType.full:
        return const BoxConstraints(
          minWidth: 300,
          minHeight: 200,
          maxHeight: 250,
        );
    }
  }

  BoxDecoration _getCardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final cardColors = _getThemeColors(theme);

    return BoxDecoration(
      color: cardColors['background'],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: cardColors['border'] ?? Colors.grey.shade300),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Map<String, Color?> _getThemeColors(ThemeData theme) {
    if (config.customColors != null) {
      return config.customColors!.map(MapEntry.new);
    }

    switch (config.theme) {
      case calendar_types.CardTheme.success:
        return {
          'background': Colors.green.shade50,
          'primary': Colors.green.shade600,
          'border': Colors.green.shade200,
          'text': Colors.green.shade800,
        };
      case calendar_types.CardTheme.warning:
        return {
          'background': Colors.orange.shade50,
          'primary': Colors.orange.shade600,
          'border': Colors.orange.shade200,
          'text': Colors.orange.shade800,
        };
      case calendar_types.CardTheme.danger:
        return {
          'background': Colors.red.shade50,
          'primary': Colors.red.shade600,
          'border': Colors.red.shade200,
          'text': Colors.red.shade800,
        };
      case calendar_types.CardTheme.info:
        return {
          'background': Colors.blue.shade50,
          'primary': Colors.blue.shade600,
          'border': Colors.blue.shade200,
          'text': Colors.blue.shade800,
        };
      case calendar_types.CardTheme.neutral:
      default:
        return {
          'background': theme.cardColor,
          'primary': theme.primaryColor,
          'border': Colors.grey.shade300,
          'text': theme.textTheme.bodyLarge?.color,
        };
    }
  }

  Widget _buildHeader(BuildContext context) {
    final colors = _getThemeColors(Theme.of(context));

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors['border'] ?? Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              config.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors['text'],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (config.isInteractive)
            Icon(Icons.chevron_right, size: 16, color: colors['primary']),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (config.layout) {
      case calendar_types.CardLayoutStyle.metric:
        return _buildMetricLayout(context);
      case calendar_types.CardLayoutStyle.comparison:
        return _buildComparisonLayout(context);
      case calendar_types.CardLayoutStyle.chart:
        return _buildChartLayout(context);
      case calendar_types.CardLayoutStyle.list:
        return _buildListLayout(context);
      case calendar_types.CardLayoutStyle.grid:
        return _buildGridLayout(context);
      case calendar_types.CardLayoutStyle.timeline:
        return _buildTimelineLayout(context);
      case calendar_types.CardLayoutStyle.heatmap:
        return _buildHeatmapLayout(context);
    }
  }

  Widget _buildMetricLayout(BuildContext context) {
    final colors = _getThemeColors(Theme.of(context));
    final metricData = _getMetricData();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metricData['value'] ?? '--',
            style: TextStyle(
              fontSize: _getFontSize(config.size, 'large'),
              fontWeight: FontWeight.bold,
              color: colors['primary'],
            ),
          ),
          if (metricData['subtitle'] != null) ...[
            const SizedBox(height: 4),
            Text(
              metricData['subtitle']!,
              style: TextStyle(
                fontSize: _getFontSize(config.size, 'small'),
                color: colors['text']?.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonLayout(BuildContext context) {
    // Implementation for comparison layout
    return const Center(child: Text('Comparison View'));
  }

  Widget _buildChartLayout(BuildContext context) {
    // Implementation for chart layout
    return const Center(child: Text('Chart View'));
  }

  Widget _buildListLayout(BuildContext context) {
    // Implementation for list layout
    return const Center(child: Text('List View'));
  }

  Widget _buildGridLayout(BuildContext context) {
    final gridData = _getGridData();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: gridData.length,
        itemBuilder: (context, index) {
          final item = gridData[index];
          return Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['label'] ?? '',
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
                Text(
                  item['value'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineLayout(BuildContext context) {
    // Implementation for timeline layout
    return const Center(child: Text('Timeline View'));
  }

  Widget _buildHeatmapLayout(BuildContext context) {
    // Implementation for heatmap layout
    return const Center(child: Text('Heatmap View'));
  }

  Widget _buildFooter(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    child: const Text('Footer', style: TextStyle(fontSize: 10)),
  );

  Map<String, String?> _getMetricData() {
    if (data is calendar_types.TradeCardData) {
      final tradeData = data as calendar_types.TradeCardData;
      switch (config.type) {
        case calendar_types.CalendarCardType.pnlSummary:
          return {
            'value': '\$${tradeData.pnl.toStringAsFixed(2)}',
            'subtitle': '${tradeData.tradeCount} trades',
          };
        case calendar_types.CalendarCardType.winLossRatio:
          return {
            'value': tradeData.winLossRatio.toStringAsFixed(2),
            'subtitle': 'Win/Loss',
          };
        default:
          return {'value': '--', 'subtitle': null};
      }
    } else if (data is calendar_types.PortfolioCardData) {
      final portfolioData = data as calendar_types.PortfolioCardData;
      switch (config.type) {
        case calendar_types.CalendarCardType.portfolioValue:
          return {
            'value': '\$${portfolioData.totalValue.toStringAsFixed(0)}',
            'subtitle':
                '${portfolioData.dailyChangePercent.toStringAsFixed(2)}%',
          };
        default:
          return {'value': '--', 'subtitle': null};
      }
    }

    return {'value': '--', 'subtitle': null};
  }

  List<Map<String, String>> _getGridData() {
    if (data is calendar_types.TradeCardData) {
      final tradeData = data as calendar_types.TradeCardData;
      return [
        {'label': 'Trades', 'value': '${tradeData.tradeCount}'},
        {'label': 'Wins', 'value': '${tradeData.winCount}'},
        {'label': 'Losses', 'value': '${tradeData.lossCount}'},
        {
          'label': 'Win Rate',
          'value': '${(tradeData.calculatedWinRate * 100).toStringAsFixed(0)}%',
        },
      ];
    }

    return [
      {'label': 'No', 'value': 'Data'},
      {'label': 'Available', 'value': '--'},
    ];
  }

  double _getFontSize(calendar_types.CardSizeType size, String type) {
    switch (size) {
      case calendar_types.CardSizeType.small:
        return type == 'large' ? 14 : 10;
      case calendar_types.CardSizeType.medium:
        return type == 'large' ? 18 : 12;
      case calendar_types.CardSizeType.large:
        return type == 'large' ? 24 : 14;
      case calendar_types.CardSizeType.full:
        return type == 'large' ? 28 : 16;
    }
  }
}
