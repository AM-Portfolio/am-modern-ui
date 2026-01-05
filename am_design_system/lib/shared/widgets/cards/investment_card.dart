
import 'package:flutter/material.dart';

import 'app_card.dart';
import '../../../models/investment_card/models.dart';

/// Clean investment card using structured models
class InvestmentCard extends StatelessWidget {
  const InvestmentCard({
    required this.data,
    super.key,
    this.config = const InvestmentCardConfig(),
    this.style = InvestmentCardStyle.regular,
    this.displayOptions = InvestmentDisplayOptions.full,
  });

  /// Legacy constructor for backward compatibility
  InvestmentCard.legacy({
    required String symbol,
    required String name,
    required double currentValue,
    required double investedAmount,
    required double avgPrice,
    required int quantity,
    required double currentPrice,
    required double changeValue,
    required double changePercent,
    required bool isPositive,
    super.key,
    VoidCallback? onTap,
    Widget? leadingIcon,
    Widget? trailingWidget,
    List<Widget>? additionalWidgets,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    Color? cardColor,
    bool showInvestmentDetails = true,
    bool showCurrentPrice = true,
    bool showQuantity = true,
    bool showAveragePrice = true,
    String currencySymbol = '₹',
    String? additionalInfo,
    Widget? customBottomWidget,
    CrossAxisAlignment leftAlignment = CrossAxisAlignment.start,
    CrossAxisAlignment rightAlignment = CrossAxisAlignment.end,
  }) : data = InvestmentData(
         symbol: symbol,
         name: name,
         currentValue: currentValue,
         investedAmount: investedAmount,
         avgPrice: avgPrice,
         quantity: quantity,
         currentPrice: currentPrice,
         changeValue: changeValue,
         changePercent: changePercent,
         isPositive: isPositive,
         additionalInfo: additionalInfo,
       ),
       config = InvestmentCardConfig(
         onTap: onTap,
         leadingIcon: leadingIcon,
         trailingWidget: trailingWidget,
         additionalWidgets: additionalWidgets,
         customBottomWidget: customBottomWidget,
         currencySymbol: currencySymbol,
       ),
       style = InvestmentCardStyle(
         padding: padding,
         margin: margin,
         borderRadius: borderRadius,
         cardColor: cardColor,
         leftAlignment: leftAlignment,
         rightAlignment: rightAlignment,
       ),
       displayOptions = InvestmentDisplayOptions(
         showInvestmentDetails: showInvestmentDetails,
         showCurrentPrice: showCurrentPrice,
         showQuantity: showQuantity,
         showAveragePrice: showAveragePrice,
       );
  final InvestmentData data;
  final InvestmentCardConfig config;
  final InvestmentCardStyle style;
  final InvestmentDisplayOptions displayOptions;

  @override
  Widget build(BuildContext context) => AppCard(
    margin: style.margin ?? const EdgeInsets.only(bottom: 8),
    backgroundColor: style.cardColor,
    borderRadius: style.borderRadius ?? BorderRadius.circular(8),
    padded: false, // We handle padding inside InkWell
    child: InkWell(
      onTap: config.onTap,
      borderRadius: style.borderRadius ?? BorderRadius.circular(8),
      child: Padding(
        padding: style.padding ?? const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTopRow(),
            const SizedBox(height: 12),
            if (config.additionalWidgets != null) ...[
              ...config.additionalWidgets!,
              const SizedBox(height: 8),
            ],
            config.customBottomWidget ?? _buildBottomRow(),
          ],
        ),
      ),
    ),
  );

  Widget _buildTopRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _buildLeftSection(),
      config.trailingWidget ??
          (displayOptions.showDefaultValue
              ? _buildValueDisplay()
              : const SizedBox.shrink()),
    ],
  );

  Widget _buildLeftSection() => Row(
    children: [
      config.leadingIcon ?? _buildDefaultIcon(),
      const SizedBox(width: 12),
      _buildTitleSection(),
    ],
  );

  Widget _buildTitleSection() => Column(
    crossAxisAlignment: style.leftAlignment,
    children: [
      _buildSymbolText(),
      _buildNameText(),
      if (data.additionalInfo != null && displayOptions.showAdditionalInfo)
        _buildAdditionalInfo(),
    ],
  );

  Widget _buildSymbolText() => Text(
    data.symbol,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  );

  Widget _buildNameText() => Text(
    data.name,
    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
  );

  Widget _buildAdditionalInfo() => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(
      data.additionalInfo!,
      style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
    ),
  );

  Widget _buildValueDisplay() => Text(
    '${config.currencySymbol}${data.currentValue.toStringAsFixed(2)}',
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  );

  Widget _buildDefaultIcon() {
    final color = data.isPositive ? Colors.green : Colors.red;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          data.symbol.length >= 2
              ? data.symbol.substring(0, 2).toUpperCase()
              : data.symbol.toUpperCase(),
          style: TextStyle(
            color: color.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      if (displayOptions.showInvestmentDetails) _buildInvestmentDetails(),
      if (displayOptions.showPerformanceSection) _buildPerformanceSection(),
    ],
  );

  Widget _buildInvestmentDetails() => Column(
    crossAxisAlignment: style.leftAlignment,
    children: [
      _buildInvestmentAmount(),
      const SizedBox(height: 2),
      _buildDetailsRow(),
    ],
  );

  Widget _buildInvestmentAmount() => Row(
    children: [
      Text(
        'Inv. ',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      Text(
        '${config.currencySymbol}${data.investedAmount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    ],
  );

  Widget _buildDetailsRow() => Row(
    children: [
      if (displayOptions.showAveragePrice) ..._buildAveragePrice(),
      if (displayOptions.showQuantity && displayOptions.showAveragePrice)
        const SizedBox(width: 8),
      if (displayOptions.showQuantity) ..._buildQuantityInfo(),
    ],
  );

  List<Widget> _buildAveragePrice() => [
    Icon(
      data.isPositive ? Icons.trending_up : Icons.trending_down,
      color: data.isPositive ? Colors.green : Colors.red,
      size: 12,
    ),
    const SizedBox(width: 2),
    Text(
      'Avg ${data.avgPrice.toStringAsFixed(2)}',
      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
    ),
  ];

  List<Widget> _buildQuantityInfo() => [
    Icon(Icons.inventory_2_outlined, color: Colors.grey.shade600, size: 12),
    const SizedBox(width: 2),
    Text(
      '${data.quantity.toInt()}',
      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
    ),
  ];

  Widget _buildPerformanceSection() {
    final color = data.isPositive ? Colors.green : Colors.red;
    return Column(
      crossAxisAlignment: style.rightAlignment,
      children: [
        if (displayOptions.showChangeValue) _buildChangeValue(color),
        if (displayOptions.showChangePercent) _buildChangePercent(color),
        if (displayOptions.showCurrentPrice) _buildCurrentPrice(),
      ],
    );
  }

  Widget _buildChangeValue(Color color) => Text(
    '${data.isPositive ? '+' : ''}${config.currencySymbol}${data.changeValue.toStringAsFixed(2)}',
    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
  );

  Widget _buildChangePercent(Color color) => Text(
    '${data.isPositive ? '+' : ''}${data.changePercent.toStringAsFixed(2)}%',
    style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12),
  );

  Widget _buildCurrentPrice() => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Live ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        Text(
          data.currentPrice.toStringAsFixed(2),
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ],
    ),
  );
}

/// Clean factory constructors using structured models
extension InvestmentCardFactory on InvestmentCard {
  /// Compact card for watchlists/summaries
  static InvestmentCard compact({
    required String symbol,
    required String name,
    required double currentValue,
    required double changeValue,
    required double changePercent,
    required bool isPositive,
    VoidCallback? onTap,
    String currencySymbol = '₹',
  }) => InvestmentCard(
    data: InvestmentData(
      symbol: symbol,
      name: name,
      currentValue: currentValue,
      investedAmount: 0,
      avgPrice: 0,
      quantity: 0,
      currentPrice: 0,
      changeValue: changeValue,
      changePercent: changePercent,
      isPositive: isPositive,
    ),
    config: InvestmentCardConfig(onTap: onTap, currencySymbol: currencySymbol),
    style: InvestmentCardStyle.compact,
    displayOptions: InvestmentDisplayOptions.watchlist,
  );

  /// Stock card with equity-specific terminology
  static InvestmentCard stock({
    required String ticker,
    required String companyName,
    required double marketValue,
    required double investedAmount,
    required double avgPrice,
    required int shares,
    required double currentPrice,
    required double dayChange,
    required double dayChangePercent,
    required bool isPositive,
    VoidCallback? onTap,
    String? sector,
    List<Widget>? badges,
    String currencySymbol = '₹',
  }) => InvestmentCard(
    data: InvestmentData(
      symbol: ticker,
      name: companyName,
      currentValue: marketValue,
      investedAmount: investedAmount,
      avgPrice: avgPrice,
      quantity: shares,
      currentPrice: currentPrice,
      changeValue: dayChange,
      changePercent: dayChangePercent,
      isPositive: isPositive,
      additionalInfo: sector,
    ),
    config: InvestmentCardConfig(
      onTap: onTap,
      additionalWidgets: badges,
      currencySymbol: currencySymbol,
    ),
  );

  /// Mutual fund card with fund-specific details
  static InvestmentCard mutualFund({
    required String fundCode,
    required String fundName,
    required double currentValue,
    required double investedAmount,
    required double nav,
    required double units,
    required double changeValue,
    required double changePercent,
    required bool isPositive,
    VoidCallback? onTap,
    String? category,
    String? amc,
    String currencySymbol = '₹',
  }) => InvestmentCard(
    data: InvestmentData(
      symbol: fundCode,
      name: fundName,
      currentValue: currentValue,
      investedAmount: investedAmount,
      avgPrice: nav,
      quantity: units.toInt(),
      currentPrice: nav,
      changeValue: changeValue,
      changePercent: changePercent,
      isPositive: isPositive,
      additionalInfo: _formatInfo(category, amc),
    ),
    config: InvestmentCardConfig(onTap: onTap, currencySymbol: currencySymbol),
  );

  /// Crypto card with blockchain-specific details
  static InvestmentCard crypto({
    required String coinSymbol,
    required String coinName,
    required double holdingValue,
    required double investedAmount,
    required double avgBuyPrice,
    required double coins,
    required double currentPrice,
    required double priceChange,
    required double priceChangePercent,
    required bool isPositive,
    VoidCallback? onTap,
    String? blockchain,
    List<Widget>? tags,
    String currencySymbol = '₹',
  }) => InvestmentCard(
    data: InvestmentData(
      symbol: coinSymbol,
      name: coinName,
      currentValue: holdingValue,
      investedAmount: investedAmount,
      avgPrice: avgBuyPrice,
      quantity: coins.toInt(),
      currentPrice: currentPrice,
      changeValue: priceChange,
      changePercent: priceChangePercent,
      isPositive: isPositive,
      additionalInfo: blockchain,
    ),
    config: InvestmentCardConfig(
      onTap: onTap,
      additionalWidgets: tags,
      currencySymbol: currencySymbol,
    ),
  );

  static String? _formatInfo(String? primary, String? secondary) =>
      primary != null && secondary != null
      ? '$primary • $secondary'
      : primary ?? secondary;
}
