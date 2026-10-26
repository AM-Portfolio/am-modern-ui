import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../components/journal_form_header.dart';
import '../widgets/url_preview_widget_stub.dart'
    if (dart.library.html) '../widgets/url_preview_widget.dart';

/// Section containing optional fields like date and URL.
/// Trade linking is owned by "Today's trades" — no free-text Trade ID field.
class OptionalFieldsSection extends StatefulWidget {
  const OptionalFieldsSection({
    required this.entryDate,
    required this.urlController,
    required this.isEditMode,
    required this.isUrlExpanded,
    required this.urlPreview,
    required this.onDateSelect,
    required this.onToggleUrlExpansion,
    required this.onClearUrl,
    this.onWatchlistChanged,
    this.onReflectionChanged,
    this.initialWatchlist,
    this.initialReflection,
    super.key,
  });

  final DateTime entryDate;
  final TextEditingController urlController;
  final bool isEditMode;
  final bool isUrlExpanded;
  final String? urlPreview;
  final VoidCallback onDateSelect;
  final VoidCallback onToggleUrlExpansion;
  final VoidCallback onClearUrl;
  final ValueChanged<List<String>>? onWatchlistChanged;
  final ValueChanged<String>? onReflectionChanged;
  final List<String>? initialWatchlist;
  final String? initialReflection;

  @override
  State<OptionalFieldsSection> createState() => _OptionalFieldsSectionState();
}

class _OptionalFieldsSectionState extends State<OptionalFieldsSection> {
  late TextEditingController _watchlistController;
  late TextEditingController _reflectionController;
  List<String> _watchlistItems = [];

  @override
  void initState() {
    super.initState();
    _watchlistController = TextEditingController();
    _reflectionController = TextEditingController(text: widget.initialReflection ?? '');
    _watchlistItems = List.from(widget.initialWatchlist ?? []);
  }

  @override
  void dispose() {
    _watchlistController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  void _addWatchlistItem() {
    final item = _watchlistController.text.trim();
    if (item.isNotEmpty && !_watchlistItems.contains(item)) {
      setState(() {
        _watchlistItems.add(item);
        _watchlistController.clear();
      });
      widget.onWatchlistChanged?.call(_watchlistItems);
    }
  }

  void _removeWatchlistItem(int index) {
    setState(() {
      _watchlistItems.removeAt(index);
    });
    widget.onWatchlistChanged?.call(_watchlistItems);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUrl = widget.urlController.text.trim().isNotEmpty;
    final hasWatchlist = _watchlistItems.isNotEmpty;
    final hasReflection = _reflectionController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JournalFormHeader(
          entryDate: widget.entryDate,
          isEditMode: widget.isEditMode,
          onDateSelect: widget.onDateSelect,
        ),
        if (widget.isEditMode || hasUrl) ...[
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: widget.onToggleUrlExpansion,
            borderRadius: AppRadii.card,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.isUrlExpanded
                      ? ModuleColors.trade.withValues(alpha: 0.55)
                      : theme.dividerColor.withValues(alpha: 0.35),
                ),
                borderRadius: AppRadii.card,
                color: widget.isUrlExpanded
                    ? ModuleColors.trade.withValues(alpha: 0.08)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 18,
                    color: widget.isUrlExpanded
                        ? ModuleColors.trade
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.isUrlExpanded ? 'Add URL' : 'Add URL (optional)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: widget.isUrlExpanded
                          ? ModuleColors.trade
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: widget.isUrlExpanded
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    widget.isUrlExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: widget.isUrlExpanded
                        ? ModuleColors.trade
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (widget.isUrlExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildUrlField(theme),
            if (widget.urlPreview != null) ...[
              const SizedBox(height: AppSpacing.sm),
              UrlPreviewWidget(
                url: widget.urlPreview!,
                onClose: widget.onClearUrl,
              ),
            ],
          ],
        ],
        if (widget.isEditMode || hasWatchlist) ...[
          const SizedBox(height: AppSpacing.md),
          _buildWatchlistSection(theme),
        ],
        if (widget.isEditMode || hasReflection) ...[
          const SizedBox(height: AppSpacing.md),
          _buildReflectionSection(theme),
        ],
      ],
    );
  }

  Widget _buildUrlField(ThemeData theme) {
    final hasUrl = widget.urlController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: hasUrl ? theme.colorScheme.primary.withOpacity(0.5) : theme.dividerColor.withOpacity(0.5),
          width: hasUrl ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: hasUrl ? theme.colorScheme.primaryContainer.withOpacity(0.1) : null,
      ),
      child: TextFormField(
        controller: widget.urlController,
        decoration: InputDecoration(
          labelText: 'Add URL (optional)',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelAlignment: FloatingLabelAlignment.start,
          hintText: 'https://tradingview.com/chart/...',
          prefixIcon: Icon(Icons.link, size: 20, color: hasUrl ? theme.colorScheme.primary : null),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildWatchlistSection(ThemeData theme) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.secondary.withOpacity(0.08),
    ),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.visibility, size: 18, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text(
              'Pre-Market Watchlist',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Watchlist input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _watchlistController,
                decoration: InputDecoration(
                  hintText: 'Add stock symbol (e.g., AAPL, NIFTY50)',
                  prefixIcon: Icon(Icons.search, size: 18, color: theme.colorScheme.secondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (_) => _addWatchlistItem(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _addWatchlistItem, icon: const Icon(Icons.add)),
          ],
        ),
        // Watchlist items
        if (_watchlistItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _watchlistItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeWatchlistItem(index),
                      child: Icon(Icons.close, size: 14, color: theme.colorScheme.secondary.withOpacity(0.7)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    ),
  );

  Widget _buildReflectionSection(ThemeData theme) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.tertiary.withOpacity(0.08),
    ),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb, size: 18, color: theme.colorScheme.tertiary),
            const SizedBox(width: 8),
            Text(
              'Post-Session Thoughts',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reflectionController,
          maxLines: 3,
          onChanged: (value) => widget.onReflectionChanged?.call(value),
          decoration: InputDecoration(
            hintText: 'What did you learn? What mistakes did you make? How will you improve?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    ),
  );
}
