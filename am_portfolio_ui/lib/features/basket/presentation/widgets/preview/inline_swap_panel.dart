import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../domain/models/basket_opportunity.dart';

class InlineSwapPanel extends StatefulWidget {
  final List<Alternative> alternatives;
  final ValueChanged<String> onSwapSelected;

  const InlineSwapPanel({
    super.key,
    required this.alternatives,
    required this.onSwapSelected,
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
    _filteredAlternatives = widget.alternatives;
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

  void _filterAlternatives(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredAlternatives = widget.alternatives;
      });
      return;
    }

    setState(() {
      _filteredAlternatives = widget.alternatives.where((alt) {
        return alt.symbol.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surfaceSecondary,
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
                borderSide: BorderSide(color: context.colors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.input,
                borderSide: BorderSide(color: context.colors.borderLight),
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
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surfacePrimary,
                    borderRadius: AppRadii.button,
                    border: Border.all(color: context.colors.borderLight),
                  ),
                  child: Row(
                    children: [
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
                              'Same sector | Held weight: ${alt.userWeight.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => widget.onSwapSelected(alt.symbol),
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
