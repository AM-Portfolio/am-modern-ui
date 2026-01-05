import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../internal/domain/entities/journal_template.dart';
import '../../../../internal/domain/enums/journal_template_category.dart';
import '../../../cubit/journal_template/journal_template_cubit.dart';
import '../../../cubit/journal_template/journal_template_state.dart';
import '../../../journal_template_providers.dart';
import '../widgets/template_card.dart';
import '../widgets/template_category_filter.dart';
import '../widgets/template_detail_dialog.dart';
import '../widgets/create_template_dialog.dart';

/// Modern template browser page with glassmorphism design
class TemplateBrowserPage extends ConsumerStatefulWidget {
  const TemplateBrowserPage({
    required this.userId,
    this.onTemplateSelected,
    super.key,
  });

  final String userId;
  final Function(JournalTemplate)? onTemplateSelected;

  @override
  ConsumerState<TemplateBrowserPage> createState() =>
      _TemplateBrowserPageState();
}

class _TemplateBrowserPageState extends ConsumerState<TemplateBrowserPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  JournalTemplateCategory? _selectedCategory;
  String _searchQuery = '';
  bool _isGridView = true;

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
    
    // Load templates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = ref.read(journalTemplateCubitProvider);
      cubit.loadTemplates(userId: widget.userId);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = ref.watch(journalTemplateCubitProvider);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Row(
                  children: [
                    // Category Filter Sidebar
                    TemplateCategoryFilter(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() => _selectedCategory = category);
                        cubit.loadTemplates(
                          userId: widget.userId,
                          category: category,
                          search: _searchQuery.isEmpty ? null : _searchQuery,
                        );
                      },
                    ),
                    
                    // Main Content Area
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: BlocConsumer<JournalTemplateCubit,
                            JournalTemplateState>(
                          bloc: cubit,
                          listener: (context, state) {
                            if (state is JournalTemplateError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(state.message),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            } else if (state is JournalTemplateCreated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Template "${state.template.name}" created!'),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              );
                              cubit.loadTemplates(userId: widget.userId);
                            }
                          },
                          builder: (context, state) {
                            if (state is JournalTemplateLoading) {
                              return _buildLoadingState();
                            } else if (state is JournalTemplateLoaded) {
                              return _buildTemplateGrid(context, state.templates);
                            } else if (state is JournalTemplateError) {
                              return _buildErrorState(context, state.message);
                            }
                            return _buildEmptyState(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Journal Templates',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a template to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: () => setState(() => _isGridView = !_isGridView),
                tooltip: _isGridView ? 'List View' : 'Grid View',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
          final cubit = ref.read(journalTemplateCubitProvider);
          cubit.loadTemplates(
            userId: widget.userId,
            category: _selectedCategory,
            search: value.isEmpty ? null : value,
          );
        },
        decoration: InputDecoration(
          hintText: 'Search templates...',
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTemplateGrid(BuildContext context, List<JournalTemplate> templates) {
    if (templates.isEmpty) {
      return _buildEmptyState(context);
    }

    return _isGridView
        ? GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              childAspectRatio: 0.85,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: TemplateCard(
                  template: templates[index],
                  onTap: () => _showTemplateDetail(context, templates[index]),
                  onFavoriteToggle: () => _toggleFavorite(templates[index]),
                ),
              );
            },
          )
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 200 + (index * 30)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TemplateCard(
                    template: templates[index],
                    onTap: () => _showTemplateDetail(context, templates[index]),
                    onFavoriteToggle: () => _toggleFavorite(templates[index]),
                    isListView: true,
                  ),
                ),
              );
            },
          );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading templates...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No templates found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or create a new template',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading templates',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final cubit = ref.read(journalTemplateCubitProvider);
              cubit.loadTemplates(userId: widget.userId);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateTemplateDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('Create Template'),
    );
  }

  void _showTemplateDetail(BuildContext context, JournalTemplate template) {
    showDialog(
      context: context,
      builder: (context) => TemplateDetailDialog(
        template: template,
        userId: widget.userId,
        onUseTemplate: widget.onTemplateSelected,
      ),
    );
  }

  void _showCreateTemplateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateTemplateDialog(
        userId: widget.userId,
      ),
    );
  }

  void _toggleFavorite(JournalTemplate template) {
    final cubit = ref.read(journalTemplateCubitProvider);
    cubit.toggleFavorite(
      templateId: template.id,
      userId: widget.userId,
    );
  }
}
