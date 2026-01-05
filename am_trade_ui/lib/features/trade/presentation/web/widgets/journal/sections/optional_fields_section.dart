import 'package:flutter/material.dart';

import '../components/journal_form_header.dart';
import '../widgets/url_preview_widget.dart' if (dart.library.io) '../widgets/url_preview_widget_stub.dart';

/// Section containing optional fields like date, trade ID, and URL
class OptionalFieldsSection extends StatefulWidget {
  const OptionalFieldsSection({
    required this.entryDate,
    required this.tradeIdController,
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
  final TextEditingController tradeIdController;
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
    final hasTradeId = widget.tradeIdController.text.trim().isNotEmpty;
    final hasUrl = widget.urlController.text.trim().isNotEmpty;
    final hasWatchlist = _watchlistItems.isNotEmpty;
    final hasReflection = _reflectionController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entry Date
          JournalFormHeader(
            entryDate: widget.entryDate,
            isEditMode: widget.isEditMode,
            onDateSelect: widget.onDateSelect,
          ),

          // Trade ID field - only show in edit mode or if it has a value
          if (widget.isEditMode || hasTradeId) ...[const SizedBox(height: 12), _buildTradeIdField(theme)],

          // URL section - only show in edit mode or if URL exists
          if (widget.isEditMode || hasUrl) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: widget.onToggleUrlExpansion,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.isUrlExpanded
                        ? theme.colorScheme.primary.withOpacity(0.5)
                        : theme.dividerColor.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: widget.isUrlExpanded ? theme.colorScheme.primaryContainer.withOpacity(0.2) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 18,
                      color: widget.isUrlExpanded ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isUrlExpanded ? 'Add URL' : 'Add URL (optional)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.isUrlExpanded ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        fontWeight: widget.isUrlExpanded ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      widget.isUrlExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: widget.isUrlExpanded ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            // Expandable URL field
            if (widget.isUrlExpanded) ...[
              const SizedBox(height: 8),
              _buildUrlField(theme),
              if (widget.urlPreview != null) ...[
                const SizedBox(height: 8),
                UrlPreviewWidget(url: widget.urlPreview!, onClose: widget.onClearUrl),
              ],
            ],
          ],

          // Pre-Market Watchlist Section
          if (widget.isEditMode || hasWatchlist) ...[const SizedBox(height: 16), _buildWatchlistSection(theme)],

          // Post-Session Reflection Section
          if (widget.isEditMode || hasReflection) ...[const SizedBox(height: 16), _buildReflectionSection(theme)],
        ],
      ),
    );
  }

  Widget _buildTradeIdField(ThemeData theme) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextFormField(
      controller: widget.tradeIdController,
      decoration: InputDecoration(
        label: Container(padding: const EdgeInsets.symmetric(horizontal: 4), child: const Text('Trade ID (optional)')),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        hintText: 'Optional',
        prefixIcon: const Icon(Icons.tag, size: 18),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    ),
  );

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
          label: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add URL (optional)'),
                if (hasUrl) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check_circle, size: 14, color: theme.colorScheme.primary),
                ],
              ],
            ),
          ),
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
