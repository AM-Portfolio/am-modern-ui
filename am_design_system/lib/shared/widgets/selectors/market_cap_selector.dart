import 'package:flutter/material.dart';
import 'package:am_common/am_common.dart';
import '../inputs/app_segmented_control.dart';

/// UI Extension for MarketCapType to provide icons (UI layer only)
extension MarketCapTypeUIExtension on MarketCapType {
  IconData get icon {
    switch (this) {
      case MarketCapType.all:
        return Icons.donut_large_rounded;
      case MarketCapType.largeCap:
        return Icons.account_balance_rounded;
      case MarketCapType.midCap:
        return Icons.business_center_rounded;
      case MarketCapType.smallCap:
        return Icons.storefront_rounded;
      case MarketCapType.microCap:
        return Icons.store_rounded;
      case MarketCapType.megaCap:
        return Icons.corporate_fare_rounded;
    }
  }
}

/// Widget for selecting different market cap categories
class MarketCapSelector extends StatelessWidget {
  /// Constructor
  const MarketCapSelector({
    required this.selectedMarketCap,
    required this.onMarketCapChanged,
    super.key,
    this.availableMarketCaps,
    this.compact = false,
    this.primaryColor,
    this.showIcons = false,
    this.useDisplayNames = false,
    this.title,
    this.asDropdown = true,
  });

  /// Factory constructor for portfolio context
  factory MarketCapSelector.portfolio({
    required MarketCapType selectedMarketCap,
    required ValueChanged<MarketCapType> onMarketCapChanged,
    Key? key,
    bool compact = true,
    Color? primaryColor,
    bool showIcons = false,
    String? title,
  }) => MarketCapSelector(
    key: key,
    selectedMarketCap: selectedMarketCap,
    onMarketCapChanged: onMarketCapChanged,
    availableMarketCaps: MarketCapType.portfolioMarketCaps,
    compact: compact,
    primaryColor: primaryColor,
    showIcons: showIcons,
    title: title,
    asDropdown: false,
  );

  /// Factory constructor for heatmap context
  factory MarketCapSelector.heatmap({
    required MarketCapType selectedMarketCap,
    required ValueChanged<MarketCapType> onMarketCapChanged,
    Key? key,
    bool asDropdown = true,
    Color? primaryColor,
    String? title,
  }) => MarketCapSelector(
    key: key,
    selectedMarketCap: selectedMarketCap,
    onMarketCapChanged: onMarketCapChanged,
    availableMarketCaps: MarketCapType.standardMarketCaps,
    asDropdown: asDropdown,
    primaryColor: primaryColor,
    title: title,
  );

  /// Currently selected market cap
  final MarketCapType selectedMarketCap;

  /// Callback when market cap changes
  final ValueChanged<MarketCapType> onMarketCapChanged;

  /// Available market cap options (defaults to portfolio market caps)
  final List<MarketCapType>? availableMarketCaps;

  /// Whether to show as compact chips instead of dropdown
  final bool compact;

  /// Primary color for the selector
  final Color? primaryColor;

  /// Whether to show icons alongside text
  final bool showIcons;

  /// Whether to use full display names instead of short names
  final bool useDisplayNames;

  /// Optional title for the selector
  final String? title;

  /// Whether to show as dropdown instead of chips
  final bool asDropdown;

  @override
  Widget build(BuildContext context) {
    final marketCaps = availableMarketCaps ?? MarketCapType.portfolioMarketCaps;

    Widget selector;

    if (asDropdown) {
      selector = _buildDropdownSelector(context, marketCaps);
    } else if (compact) {
      selector = _buildCompactSelector(context, marketCaps);
    } else {
      selector = _buildSegmentedSelector(context, marketCaps);
    }

    if (title != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title!,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          selector,
        ],
      );
    }

    return selector;
  }

  Widget _buildSegmentedSelector(
    BuildContext context,
    List<MarketCapType> marketCaps,
  ) {
    final children = Map<MarketCapType, String>.fromEntries(
      marketCaps.map(
        (marketCap) => MapEntry(
          marketCap,
          useDisplayNames ? marketCap.displayName : marketCap.shortName,
        ),
      ),
    );

    return AppSegmentedControl<MarketCapType>(
      selectedValue: selectedMarketCap,
      children: children,
      onValueChanged: onMarketCapChanged,
      primaryColor: primaryColor,
    );
  }

  Widget _buildCompactSelector(
    BuildContext context,
    List<MarketCapType> marketCaps,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: marketCaps.map((marketCap) {
      final isSelected = marketCap == selectedMarketCap;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onMarketCapChanged(marketCap),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 40,
            ), // Better touch target
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? (primaryColor ?? Theme.of(context).primaryColor)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? (primaryColor ?? Theme.of(context).primaryColor)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (primaryColor ?? Theme.of(context).primaryColor)
                            .withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcons) ...[
                  Icon(
                    marketCap.icon,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  useDisplayNames ? marketCap.displayName : marketCap.shortName,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _buildDropdownSelector(
    BuildContext context,
    List<MarketCapType> marketCaps,
  ) => DropdownButtonFormField<MarketCapType>(
    value: selectedMarketCap,
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    ),
    items: marketCaps
        .map(
          (marketCap) => DropdownMenuItem<MarketCapType>(
            value: marketCap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcons) ...[
                  Icon(marketCap.icon, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(
                  useDisplayNames ? marketCap.displayName : marketCap.shortName,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        )
        .toList(),
    onChanged: (marketCap) {
      if (marketCap != null) {
        onMarketCapChanged(marketCap);
      }
    },
  );
}
