import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../domain/models/basket_opportunity.dart';

class InlineSwapPanel extends StatefulWidget {
  final List<Alternative> alternatives;
  final ValueChanged<Alternative> onSwapSelected;
  final bool sectorialBasket;
  final String? dominantSector;
  final String? etfName;
  final List<String> etfConstituentIsins;
  final String? missingSector;

  const InlineSwapPanel({
    super.key,
    required this.alternatives,
    required this.onSwapSelected,
    this.sectorialBasket = false,
    this.dominantSector,
    this.etfName,
    this.etfConstituentIsins = const [],
    this.missingSector,
  });

  @override
  State<InlineSwapPanel> createState() => _InlineSwapPanelState();
}

class _InlineSwapPanelState extends State<InlineSwapPanel> {
  final TextEditingController _searchController = TextEditingController();
  List<Alternative> _filteredAlternatives = [];

  @override
  void initState() {
    super.initState();
    _filteredAlternatives = _sectorFiltered(widget.alternatives);
  }

  @override
  void didUpdateWidget(covariant InlineSwapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alternatives != widget.alternatives) {
      _filterAlternatives(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Alternative> _sectorFiltered(List<Alternative> alts) {
    if (widget.sectorialBasket) {
      final missing = widget.missingSector?.trim().toLowerCase();
      if (missing != null && missing.isNotEmpty) {
        return alts.where((alt) {
          final sector = alt.sector?.trim().toLowerCase();
          if (sector == null || sector.isEmpty) return true;
          return missing == sector || missing.contains(sector) || sector.contains(missing);
        }).toList();
      }
    } else if (widget.etfConstituentIsins.isNotEmpty) {
      final constituents = alts.where((alt) => widget.etfConstituentIsins.contains(alt.isin)).toList();
      if (constituents.isNotEmpty) return constituents;
    }
    return alts;
  }

  void _filterAlternatives(String query) {
    final base = _sectorFiltered(widget.alternatives);
    if (query.isEmpty) {
      setState(() => _filteredAlternatives = base);
      return;
    }

    setState(() {
      _filteredAlternatives = base.where((alt) {
        return alt.symbol.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  String _recommendationBanner() {
    if (widget.sectorialBasket) {
      final sectorLabel = widget.dominantSector ?? widget.missingSector ?? 'same sector';
      return 'Recommendation: Select $sectorLabel stocks to fill the gap.';
    }
    final indexLabel = widget.etfName ?? 'index';
    return 'Select from your $indexLabel holdings (index constituents preferred).';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.cardSurface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.search, size: 16, color: context.colors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Replace with alternative from your portfolio',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.actionPrimaryBg.withValues(alpha: 0.08),
              borderRadius: AppRadii.input,
            ),
            child: Text(
              _recommendationBanner(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _searchController,
            onChanged: _filterAlternatives,
            decoration: InputDecoration(
              hintText: 'Search alternatives...',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadii.input,
                borderSide: BorderSide(color: context.colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.input,
                borderSide: BorderSide(color: context.colors.border),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_filteredAlternatives.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Center(
                child: Text(
                  'No alternatives found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colors.textTertiary,
                      ),
                ),
              ),
            )
          else
            ..._filteredAlternatives.map((alt) {
              final isFullyCovered = alt.canFullyCover;
              final isSameSector = alt.isSameSector;
              
              final Color badgeColor = isSameSector 
                  ? (isFullyCovered ? Colors.green : Colors.orange) 
                  : Colors.red;
                  
              final IconData statusIcon = isSameSector 
                  ? (isFullyCovered ? Icons.check_circle : Icons.warning) 
                  : Icons.warning;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: AppRadii.button,
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: badgeColor, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alt.symbol,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSameSector 
                                  ? '${alt.userWeight.toStringAsFixed(1)}% held • ${alt.coverageLabel ?? "Matching gap"}'
                                  : 'Cross-sector • Not recommended',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => widget.onSwapSelected(alt),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        ),
                        child: const Text('SELECT'),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
