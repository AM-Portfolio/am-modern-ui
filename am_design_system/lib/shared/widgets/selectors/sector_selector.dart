import 'package:flutter/material.dart';

import '../inputs/app_segmented_control.dart';

/// Enum for different sector categories
enum SectorType {
  all('All', 'All Sectors', Icons.dashboard),
  noGroup('No Group', 'No Grouping', Icons.view_list),
  technology('Tech', 'Technology', Icons.computer),
  healthcare('Health', 'Healthcare', Icons.medical_services),
  finance('Finance', 'Financial Services', Icons.account_balance),
  energy('Energy', 'Energy & Utilities', Icons.flash_on),
  consumer('Consumer', 'Consumer Goods', Icons.shopping_cart),
  industrials('Industry', 'Industrials', Icons.factory),
  materials('Materials', 'Materials & Mining', Icons.construction),
  telecom('Telecom', 'Telecommunications', Icons.phone),
  utilities('Utilities', 'Utilities', Icons.electrical_services),
  realEstate('RealEst', 'Real Estate', Icons.home),
  aerospace('Aerospace', 'Aerospace & Defense', Icons.flight);

  const SectorType(this.shortName, this.displayName, this.icon);

  /// Short name for compact display
  final String shortName;

  /// Full display name
  final String displayName;

  /// Representative icon
  final IconData icon;

  /// Get sector type from short name
  static SectorType? fromShortName(String shortName) {
    for (final sector in SectorType.values) {
      if (sector.shortName == shortName) {
        return sector;
      }
    }
    return null;
  }

  /// Common sectors for portfolio analysis
  static List<SectorType> get portfolioSectors => [
    SectorType.all,
    SectorType.noGroup,
    SectorType.technology,
    SectorType.healthcare,
    SectorType.finance,
    SectorType.energy,
    SectorType.consumer,
  ];

  /// All available sectors
  static List<SectorType> get allSectors => SectorType.values;
}

/// Widget for selecting different sectors
class SectorSelector extends StatelessWidget {
  /// Constructor
  const SectorSelector({
    required this.selectedSector,
    required this.onSectorChanged,
    super.key,
    this.availableSectors,
    this.compact = false,
    this.primaryColor,
    this.showIcons = false,
    this.useDisplayNames = false,
    this.title,
    this.asDropdown = true,
  });

  /// Factory constructor for portfolio context
  factory SectorSelector.portfolio({
    required SectorType selectedSector,
    required ValueChanged<SectorType> onSectorChanged,
    Key? key,
    bool compact = false,
    Color? primaryColor,
    bool showIcons = true,
    String? title,
  }) => SectorSelector(
    key: key,
    selectedSector: selectedSector,
    onSectorChanged: onSectorChanged,
    availableSectors: SectorType.portfolioSectors,
    compact: compact,
    primaryColor: primaryColor,
    showIcons: showIcons,
    title: title,
    asDropdown: false,
  );

  /// Factory constructor for heatmap context
  factory SectorSelector.heatmap({
    required SectorType selectedSector,
    required ValueChanged<SectorType> onSectorChanged,
    Key? key,
    bool asDropdown = true,
    Color? primaryColor,
    String? title,
  }) => SectorSelector(
    key: key,
    selectedSector: selectedSector,
    onSectorChanged: onSectorChanged,
    availableSectors: SectorType.allSectors,
    asDropdown: asDropdown,
    primaryColor: primaryColor,
    showIcons: true,
    title: title,
  );

  /// Currently selected sector
  final SectorType selectedSector;

  /// Callback when sector changes
  final ValueChanged<SectorType> onSectorChanged;

  /// Available sector options (defaults to portfolio sectors)
  final List<SectorType>? availableSectors;

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
    final sectors = availableSectors ?? SectorType.portfolioSectors;

    Widget selector;

    if (asDropdown) {
      selector = _buildDropdownSelector(context, sectors);
    } else if (compact) {
      selector = _buildCompactSelector(context, sectors);
    } else {
      selector = _buildSegmentedSelector(context, sectors);
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
    List<SectorType> sectors,
  ) {
    final children = Map<SectorType, String>.fromEntries(
      sectors.map(
        (sector) => MapEntry(
          sector,
          useDisplayNames ? sector.displayName : sector.shortName,
        ),
      ),
    );

    return AppSegmentedControl<SectorType>(
      selectedValue: selectedSector,
      children: children,
      onValueChanged: onSectorChanged,
      primaryColor: primaryColor,
    );
  }

  Widget _buildCompactSelector(
    BuildContext context,
    List<SectorType> sectors,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: sectors.map((sector) {
      final isSelected = sector == selectedSector;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSectorChanged(sector),
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
                    sector.icon,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  useDisplayNames ? sector.displayName : sector.shortName,
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
    List<SectorType> sectors,
  ) => DropdownButtonFormField<SectorType>(
    value: selectedSector,
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    ),
    items: sectors
        .map(
          (sector) => DropdownMenuItem<SectorType>(
            value: sector,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcons) ...[
                  Icon(sector.icon, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(
                  useDisplayNames ? sector.displayName : sector.shortName,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        )
        .toList(),
    onChanged: (sector) {
      if (sector != null) {
        onSectorChanged(sector);
      }
    },
  );
}
