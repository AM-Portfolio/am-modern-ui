import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class TradePortfolioMobileFilter extends StatefulWidget {
  const TradePortfolioMobileFilter({
    required this.searchQuery,
    required this.sortBy,
    required this.showOnlyProfit,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onProfitFilterChanged,
    super.key,
  });
  final String searchQuery;
  final String sortBy;
  final bool showOnlyProfit;
  final Function(String) onSearchChanged;
  final Function(String) onSortChanged;
  final Function(bool) onProfitFilterChanged;

  @override
  State<TradePortfolioMobileFilter> createState() => _TradePortfolioMobileFilterState();
}

class _TradePortfolioMobileFilterState extends State<TradePortfolioMobileFilter> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;
    final onAccent = context.colors.actionPrimaryFg;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
        boxShadow: [BoxShadow(color: context.shadow(0.02), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          // Filter Toggle Bar
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                    ),
                    child: Icon(Icons.filter_list, size: 16, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isExpanded ? 'Hide Filters' : 'Show Filters & Search',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  if (widget.searchQuery.isNotEmpty || widget.showOnlyProfit)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(color: onAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: accent),
                ],
              ),
            ),
          ),

          // Expandable Filter Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  // Search field
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      hintStyle: TextStyle(fontSize: 13, color: context.textSecondary),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.search, size: 18, color: accent),
                      ),
                      suffixIcon: widget.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: context.textSecondary,
                              ),
                              onPressed: () => widget.onSearchChanged(''),
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: OutlineInputBorder(borderRadius: AppRadii.button, borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadii.button,
                        borderSide: BorderSide(color: accent, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: widget.onSearchChanged,
                  ),

                  const SizedBox(height: 8),

                  // Sort and Filter Row
                  Row(
                    children: [
                      // Sort Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: AppRadii.button,
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadii.xs),
                                ),
                                child: Icon(Icons.sort, size: 13, color: accent),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: widget.sortBy,
                                  underline: const SizedBox(),
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    size: 18,
                                    color: accent,
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                                  items: const [
                                    DropdownMenuItem(value: 'name', child: Text('Name')),
                                    DropdownMenuItem(value: 'value', child: Text('Value')),
                                    DropdownMenuItem(value: 'performance', child: Text('Performance')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      widget.onSortChanged(value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Profit Filter Toggle
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onProfitFilterChanged(!widget.showOnlyProfit),
                          borderRadius: AppRadii.button,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: widget.showOnlyProfit
                                  ? accent
                                  : accent.withValues(alpha: 0.1),
                              borderRadius: AppRadii.button,
                              border: Border.all(
                                color: accent.withValues(alpha: widget.showOnlyProfit ? 1 : 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 14,
                                  color: widget.showOnlyProfit ? onAccent : accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Profit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: widget.showOnlyProfit ? onAccent : accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
