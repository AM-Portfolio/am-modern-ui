import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/journal_template.dart';
import '../../../internal/domain/enums/journal_template_category.dart';
import '../../../journal_template_providers.dart';
import '../../cubit/journal_template/journal_template_cubit.dart';
import '../../cubit/journal_template/journal_template_state.dart';
import '../../mobile/journal/pages/journal_create_template_mobile_page.dart';
import '../../mobile/journal/pages/journal_use_template_mobile_page.dart';
import '../widgets/template_card.dart';
import '../widgets/template_category_filter.dart';

/// Mobile Playbooks browser — always 1-col list; skip detail preview → inline use.
class TemplateBrowserMobilePage extends ConsumerStatefulWidget {
  const TemplateBrowserMobilePage({
    this.onTemplateSelected,
    this.embedded = false,
    super.key,
  });

  final Function(JournalTemplate)? onTemplateSelected;

  /// When true (Trade mobile Journal tab), skip Scaffold chrome.
  final bool embedded;

  @override
  ConsumerState<TemplateBrowserMobilePage> createState() =>
      TemplateBrowserMobilePageState();
}

class TemplateBrowserMobilePageState
    extends ConsumerState<TemplateBrowserMobilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  JournalTemplateCategory? _selectedCategory;
  String _searchQuery = '';

  JournalTemplate? _inlineUseTemplate;
  final _inlineUseKey = GlobalKey<JournalUseTemplateMobilePageState>();

  bool get isUsingTemplateInline => _inlineUseTemplate != null;

  void openCreateTemplate() => JournalCreateTemplateMobilePage.open(context);

  Color get _accent =>
      ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = await ref.read(journalTemplateCubitProvider.future);
      if (!mounted) return;
      cubit.loadTemplates();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> confirmLeaveInlineUse() async {
    if (_inlineUseTemplate == null) return true;
    final leave =
        await _inlineUseKey.currentState?.confirmLeaveIfUnsaved() ?? true;
    if (!leave) return false;
    if (mounted) setState(() => _inlineUseTemplate = null);
    return true;
  }

  void _closeInlineUse({required bool applied}) {
    final template = _inlineUseTemplate;
    setState(() => _inlineUseTemplate = null);
    if (applied && template != null) {
      widget.onTemplateSelected?.call(template);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubitAsync = ref.watch(journalTemplateCubitProvider);

    return cubitAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (cubit) {
        final body = ColoredBox(
          color: colors.surface,
          child: SafeArea(
            top: !widget.embedded,
            child: BlocConsumer<JournalTemplateCubit, JournalTemplateState>(
              bloc: cubit,
              listener: (context, state) {
                if (state is JournalTemplateError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: colors.statusError,
                    ),
                  );
                } else if (state is JournalTemplateCreated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Template "${state.template.name}" created!',
                      ),
                      backgroundColor: _accent,
                    ),
                  );
                  cubit.loadTemplates();
                }
              },
              builder: (context, state) {
                if (_inlineUseTemplate != null) {
                  return JournalUseTemplateMobilePage(
                    key: _inlineUseKey,
                    template: _inlineUseTemplate!,
                    embedded: true,
                    onSubmit: (_) => _closeInlineUse(applied: true),
                    onCancel: () => _closeInlineUse(applied: false),
                  );
                }

                final allTemplates = state is JournalTemplateLoaded
                    ? state.templates
                    : const <JournalTemplate>[];
                final counts = <JournalTemplateCategory, int>{};
                for (final t in allTemplates) {
                  counts[t.category] = (counts[t.category] ?? 0) + 1;
                }

                final filterContent = TemplateCategoryFilter(
                  selectedCategory: _selectedCategory,
                  isHorizontal: true,
                  totalCount: allTemplates.length,
                  categoryCounts: counts,
                  onCategorySelected: (category) {
                    setState(() => _selectedCategory = category);
                  },
                );

                Widget grid;
                if (state is JournalTemplateLoading) {
                  grid = _buildLoadingState(context);
                } else if (state is JournalTemplateLoaded) {
                  grid = _buildTemplateList(
                    context,
                    _visibleTemplates(state.templates),
                  );
                } else if (state is JournalTemplateError) {
                  grid = _buildErrorState(context, state.message);
                } else {
                  grid = _buildEmptyState(context);
                }

                return Column(
                  children: [
                    if (!widget.embedded) _buildStandaloneHeader(context),
                    filterContent,
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: grid,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        if (widget.embedded) return body;

        return Scaffold(
          backgroundColor: colors.surface,
          body: body,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: openCreateTemplate,
            backgroundColor: _accent,
            foregroundColor: colors.actionPrimaryFg,
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
          ),
        );
      },
    );
  }

  Widget _buildStandaloneHeader(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Playbooks',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.45),
              borderRadius: AppRadii.input,
              border: Border.all(color: colors.border.withValues(alpha: 0.4)),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search templates...',
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<JournalTemplate> _visibleTemplates(List<JournalTemplate> all) {
    final q = _searchQuery.trim().toLowerCase();
    return all.where((t) {
      if (_selectedCategory != null && t.category != _selectedCategory) {
        return false;
      }
      if (q.isEmpty) return true;
      final haystack =
          '${t.name} ${t.description ?? ''} ${t.category.displayName}'
              .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  Widget _buildTemplateList(
    BuildContext context,
    List<JournalTemplate> templates,
  ) {
    if (templates.isEmpty) return _buildEmptyState(context);

    final bottomPad =
        PlatformConstants.globalBottomNavReserve(context) + AppSpacing.xl;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        bottomPad,
      ),
      itemCount: templates.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
      itemBuilder: (context, index) {
        return TemplateCard(
          template: templates[index],
          onTap: () => setState(() => _inlineUseTemplate = templates[index]),
          onFavoriteToggle: () => _toggleFavorite(templates[index]),
          isMobileFullWidth: true,
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _accent),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Loading templates...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: colors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No templates found', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try adjusting filters or create a new template',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.statusError),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error loading templates',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'Retry',
              icon: Icons.refresh,
              backgroundColor: _accent,
              onPressed: () async {
                setState(() => _selectedCategory = null);
                final cubit =
                    await ref.read(journalTemplateCubitProvider.future);
                cubit.loadTemplates();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(JournalTemplate template) async {
    final cubit = await ref.read(journalTemplateCubitProvider.future);
    cubit.toggleFavorite(templateId: template.id);
  }
}
