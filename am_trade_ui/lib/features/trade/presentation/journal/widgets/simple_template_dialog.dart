import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/journal_template_catalog.dart';

export '../models/journal_template_catalog.dart'
    show
        JournalTemplateSelection,
        JournalTemplateCatalog,
        JournalTemplateCategory,
        JournalTemplateSection,
        buildTemplateDocument;

/// Journal templates picker matching the product mockup.
class EnhancedTemplateDialog extends StatefulWidget {
  const EnhancedTemplateDialog({
    required this.onTemplateSelected,
    super.key,
  });

  final ValueChanged<JournalTemplateSelection> onTemplateSelected;

  static Future<void> show({
    required BuildContext context,
    required ValueChanged<JournalTemplateSelection> onTemplateSelected,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => EnhancedTemplateDialog(
        onTemplateSelected: (selection) {
          onTemplateSelected(selection);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  State<EnhancedTemplateDialog> createState() => _EnhancedTemplateDialogState();
}

enum _TemplateFilter { all, daily, tradeSetup, review, myTemplates }

class _EnhancedTemplateDialogState extends State<EnhancedTemplateDialog> {
  late JournalTemplateSelection _selected;
  final TextEditingController _searchController = TextEditingController();
  _TemplateFilter _filter = _TemplateFilter.all;
  final FocusNode _searchFocus = FocusNode();

  List<Color> get _sectionColors => [
        ModuleColors.trade,
        ModuleColors.dashboard,
        ModuleColors.analytics,
        ModuleColors.reports,
      ];

  @override
  void initState() {
    super.initState();
    _selected = JournalTemplateCatalog.all.first;
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<JournalTemplateSelection> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return JournalTemplateCatalog.all.where((t) {
      final matchesFilter = switch (_filter) {
        _TemplateFilter.all => true,
        _TemplateFilter.daily => t.category == JournalTemplateCategory.daily,
        _TemplateFilter.tradeSetup =>
          t.category == JournalTemplateCategory.tradeSetup,
        _TemplateFilter.review => t.category == JournalTemplateCategory.review,
        _TemplateFilter.myTemplates =>
          t.category == JournalTemplateCategory.custom,
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return t.name.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
  }

  List<JournalTemplateSelection> get _recommended =>
      _filtered.where((t) => t.recommended).toList();

  List<JournalTemplateSelection> get _more =>
      _filtered.where((t) => !t.recommended).toList();

  IconData _iconFor(String key) {
    switch (key) {
      case 'breakout':
        return Icons.trending_up_rounded;
      case 'pullback':
        return Icons.south_east_rounded;
      case 'reversal':
        return Icons.swap_vert_rounded;
      case 'opening':
        return Icons.schedule_rounded;
      case 'options':
        return Icons.hub_outlined;
      case 'scalp':
        return Icons.bolt_rounded;
      case 'review':
        return Icons.rate_review_outlined;
      case 'blank':
        return Icons.add_rounded;
      case 'calendar':
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  Color _iconColorFor(String key) {
    switch (key) {
      case 'breakout':
        return ModuleColors.dashboard;
      case 'pullback':
        return ModuleColors.analytics;
      case 'reversal':
        return ModuleColors.reports;
      case 'opening':
        return ModuleColors.market;
      case 'options':
        return ModuleColors.trade;
      case 'scalp':
        return ModuleColors.portfolio;
      case 'review':
        return context.statusNeutral;
      case 'calendar':
      default:
        return ModuleColors.reports;
    }
  }

  Color _tagColor(String tag, int index) {
    final palette = [
      ModuleColors.trade,
      ModuleColors.dashboard,
      ModuleColors.analytics,
      context.statusNeutral,
      ModuleColors.reports,
      ModuleColors.portfolio,
    ];
    return palette[index % palette.length];
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyK &&
        HardwareKeyboard.instance.isControlPressed) {
      _searchFocus.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _useSelected() => widget.onTemplateSelected(_selected);

  void _useBlank() =>
      widget.onTemplateSelected(JournalTemplateCatalog.blank);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Focus(
      onKeyEvent: _onKey,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 720),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.cardSurface,
              borderRadius: AppRadii.dialog,
              border: Border.all(color: colors.border.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: context.shadow(0.45),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadii.dialog,
              child: Column(
                children: [
                  _buildHeader(theme, colors),
                  Divider(height: 1, color: colors.border.withValues(alpha: 0.35)),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 340,
                          child: _buildLeftPane(theme, colors),
                        ),
                        VerticalDivider(
                          width: 1,
                          color: colors.border.withValues(alpha: 0.35),
                        ),
                        Expanded(child: _buildRightPane(theme, colors)),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.border.withValues(alpha: 0.35)),
                  _buildFooter(theme, colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppColorsTheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ModuleColors.trade.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(
              Icons.description_outlined,
              color: ModuleColors.trade,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journal Templates',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Start with a template to save time and stay consistent.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPane(ThemeData theme, AppColorsTheme colors) {
    final recommended = _recommended;
    final more = _more;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              _SearchField(
                controller: _searchController,
                focusNode: _searchFocus,
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == _TemplateFilter.all,
                      onTap: () =>
                          setState(() => _filter = _TemplateFilter.all),
                    ),
                    const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
                    _FilterChip(
                      label: 'Daily',
                      selected: _filter == _TemplateFilter.daily,
                      onTap: () =>
                          setState(() => _filter = _TemplateFilter.daily),
                    ),
                    const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
                    _FilterChip(
                      label: 'Trade Setup',
                      selected: _filter == _TemplateFilter.tradeSetup,
                      onTap: () => setState(
                        () => _filter = _TemplateFilter.tradeSetup,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
                    _FilterChip(
                      label: 'Review',
                      selected: _filter == _TemplateFilter.review,
                      onTap: () =>
                          setState(() => _filter = _TemplateFilter.review),
                    ),
                    const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
                    _FilterChip(
                      label: 'My Templates',
                      selected: _filter == _TemplateFilter.myTemplates,
                      onTap: () => setState(
                        () => _filter = _TemplateFilter.myTemplates,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            children: [
              _BlankJournalCard(onTap: _useBlank),
              if (recommended.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _SectionLabel(label: 'Recommended'),
                const SizedBox(height: AppSpacing.sm),
                ...recommended.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _TemplateListTile(
                      template: t,
                      selected: t.name == _selected.name,
                      icon: _iconFor(t.icon),
                      iconColor: _iconColorFor(t.icon),
                      onTap: () => setState(() => _selected = t),
                    ),
                  ),
                ),
              ],
              if (more.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _SectionLabel(label: 'More Templates'),
                const SizedBox(height: AppSpacing.sm),
                ...more.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _TemplateListTile(
                      template: t,
                      selected: t.name == _selected.name,
                      icon: _iconFor(t.icon),
                      iconColor: _iconColorFor(t.icon),
                      onTap: () => setState(() => _selected = t),
                    ),
                  ),
                ),
              ],
              if (recommended.isEmpty && more.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Text(
                    'No templates match your filters.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightPane(ThemeData theme, AppColorsTheme colors) {
    final t = _selected;
    final sections = t.previewSections.isNotEmpty
        ? t.previewSections
        : [
            JournalTemplateSection(
              title: 'Setup checklist',
              items: t.checklistItems,
            ),
          ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (t.badgeLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs + 1,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: 0.7),
                          borderRadius: AppRadii.chip,
                          border: Border.all(
                            color: colors.border.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          t.badgeLabel!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.7,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          _iconFor(t.icon),
                          color: _iconColorFor(t.icon),
                          size: 26,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            t.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (var i = 0; i < t.tags.length; i++)
                          _OutlinedTag(
                            label: t.tags[i],
                            color: _tagColor(t.tags[i], i),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _MetaItem(
                          icon: Icons.check_circle_outline,
                          label: '${t.itemCount} checklist items',
                        ),
                        _MetaItem(
                          icon: Icons.schedule_outlined,
                          label: '~ ${t.estimatedMinutes} min to complete',
                        ),
                        if (t.recommended)
                          _MetaItem(
                            icon: Icons.star_rounded,
                            label: 'Recommended',
                            color: ModuleColors.reports,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Primary apply lives in the footer — avoid duplicate CTAs.
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.55),
                borderRadius: AppRadii.card,
                border: Border.all(color: colors.border.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
                        Text(
                          'Template Preview',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.sm,
                              AppSpacing.md,
                            ),
                            itemCount: sections.length,
                            itemBuilder: (context, index) {
                              final section = sections[index];
                              final color =
                                  _sectionColors[index % _sectionColors.length];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: _PreviewSectionBlock(
                                  index: index + 1,
                                  color: color,
                                  section: section,
                                ),
                              );
                            },
                          ),
                        ),
                        if (t.quote != null)
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                0,
                                0,
                                AppSpacing.md,
                                AppSpacing.md,
                              ),
                              child: _QuoteCard(quote: t.quote!),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, AppColorsTheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
          Expanded(
            child: Text(
              'Tip: You can always edit the template after creating the journal.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          AppButton(
            text: 'Cancel',
            type: AppButtonType.secondary,
            isOutlined: true,
            onPressed: () => Navigator.pop(context),
            height: 44,
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            text: 'Use ${_selected.name}',
            backgroundColor: ModuleColors.trade,
            onPressed: _useSelected,
            height: 44,
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: 'Search templates…',
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colors.textSecondary,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Center(
            widthFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + AppSpacing.xxs,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppRadii.xs),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              child: Text(
                'Ctrl K',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        filled: true,
        fillColor: colors.surface.withValues(alpha: 0.65),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(
            color: ModuleColors.trade.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AmToggleChip(
      label: label,
      selected: selected,
      compact: true,
      accentColor: ModuleColors.trade,
      onTap: onTap,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.textSecondary,
          ),
    );
  }
}

class _BlankJournalCard extends StatelessWidget {
  const _BlankJournalCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Material(
      color: colors.surface.withValues(alpha: 0.45),
      borderRadius: AppRadii.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.card,
            border: Border.all(
              color: colors.border.withValues(alpha: 0.45),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ModuleColors.trade.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: ModuleColors.trade.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(Icons.add_rounded, color: ModuleColors.trade),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blank Journal',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Start from scratch',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateListTile extends StatelessWidget {
  const _TemplateListTile({
    required this.template,
    required this.selected,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final JournalTemplateSelection template;
  final bool selected;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Material(
      color: selected
          ? ModuleColors.trade.withValues(alpha: 0.12)
          : colors.surface.withValues(alpha: 0.35),
      borderRadius: AppRadii.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
          decoration: BoxDecoration(
            borderRadius: AppRadii.card,
            border: Border.all(
              color: selected
                  ? ModuleColors.trade.withValues(alpha: 0.85)
                  : colors.border.withValues(alpha: 0.3),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      template.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${template.previewSections.isNotEmpty ? template.previewSections.length : template.itemCount} items',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedTag extends StatelessWidget {
  const _OutlinedTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadii.chip,
        border: Border.all(color: color.withValues(alpha: 0.65)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final c = color ?? colors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: c,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _PreviewSectionBlock extends StatelessWidget {
  const _PreviewSectionBlock({
    required this.index,
    required this.color,
    required this.section,
  });

  final int index;
  final Color color;
  final JournalTemplateSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: TextStyle(
              color: colors.actionPrimaryFg,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...section.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_box_outline_blank_rounded,
                        size: 18,
                        color: colors.textSecondary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          item,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ModuleColors.trade.withValues(alpha: 0.18),
            colors.surface.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: AppRadii.card,
        border: Border.all(
          color: ModuleColors.trade.withValues(alpha: 0.25),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -8,
            child: Icon(
              Icons.landscape_outlined,
              size: 96,
              color: ModuleColors.trade.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            right: 28,
            bottom: 56,
            child: Icon(
              Icons.nightlight_round,
              size: 28,
              color: ModuleColors.trade.withValues(alpha: 0.45),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                '"$quote"',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: colors.textPrimary.withValues(alpha: 0.92),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
