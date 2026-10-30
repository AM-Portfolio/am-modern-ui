import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../../journal/widgets/journal_symbol_suggest_field.dart';
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

  void _addWatchlistItem([String? raw]) {
    final item = (raw ?? _watchlistController.text).trim().toUpperCase();
    if (item.isNotEmpty && !_watchlistItems.contains(item)) {
      setState(() {
        _watchlistItems.add(item);
        _watchlistController.clear();
      });
      widget.onWatchlistChanged?.call(_watchlistItems);
    } else {
      _watchlistController.clear();
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
    final colors = context.colors;
    final accent = ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;
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
                      ? accent.withValues(alpha: 0.55)
                      : colors.border,
                ),
                borderRadius: AppRadii.card,
                color: widget.isUrlExpanded
                    ? accent.withValues(alpha: 0.08)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 18,
                    color: widget.isUrlExpanded
                        ? accent
                        : colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.isUrlExpanded ? 'Add URL' : 'Add URL (optional)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: widget.isUrlExpanded
                          ? accent
                          : colors.textSecondary,
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
                        ? accent
                        : colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (widget.isUrlExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildUrlField(),
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
          _buildWatchlistSection(),
        ],
        if (widget.isEditMode || hasReflection) ...[
          const SizedBox(height: AppSpacing.md),
          _buildReflectionSection(),
        ],
      ],
    );
  }

  Widget _buildUrlField() {
    final theme = Theme.of(context);
    final colors = context.colors;
    final accent = ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;
    final hasUrl = widget.urlController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: hasUrl ? accent.withValues(alpha: 0.5) : colors.border,
          width: hasUrl ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: hasUrl ? accent.withValues(alpha: 0.08) : null,
      ),
      child: TextFormField(
        controller: widget.urlController,
        decoration: InputDecoration(
          labelText: 'Add URL (optional)',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelAlignment: FloatingLabelAlignment.start,
          hintText: 'https://tradingview.com/chart/...',
          prefixIcon: Icon(Icons.link, size: 20, color: hasUrl ? accent : null),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildWatchlistSection() {
    final theme = Theme.of(context);
    final colors = context.colors;
    final accent = ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
        color: accent.withValues(alpha: 0.06),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                'Pre-Market Watchlist',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Watchlist input row — securities / ETF recommendations
          Row(
            children: [
              Expanded(
                child: JournalSymbolSuggestField(
                  controller: _watchlistController,
                  enabled: widget.isEditMode,
                  hintText: 'Search stocks, ETFs, indices…',
                  clearOnSelect: true,
                  decoration: InputDecoration(
                    hintText: 'Search stocks, ETFs, indices…',
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: accent,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: colors.surface,
                  ),
                  onSelected: (hit) => _addWatchlistItem(hit.symbol),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: widget.isEditMode ? () => _addWatchlistItem() : null,
                icon: const Icon(Icons.add),
              ),
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
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeWatchlistItem(index),
                        child: Icon(Icons.close, size: 14, color: accent.withValues(alpha: 0.7)),
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
  }

  Widget _buildReflectionSection() {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.statusInfo.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
        color: colors.statusInfo.withValues(alpha: 0.06),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, size: 18, color: colors.statusInfo),
              const SizedBox(width: 8),
              Text(
                'Post-Session Thoughts',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.statusInfo,
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
}
