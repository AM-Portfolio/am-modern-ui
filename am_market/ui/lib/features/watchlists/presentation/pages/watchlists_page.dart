import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../providers/watchlist_provider.dart';
import '../../data/models/watchlist_model.dart';
import '../widgets/watchlist_management_view.dart';
import '../widgets/watchlist_mobile_detail_view.dart';
import '../widgets/create_watchlist_dialog.dart';
import '../widgets/edit_watchlist_dialog.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';

class WatchlistsPage extends ConsumerStatefulWidget {
  final ValueChanged<String>? onStockSelected;

  const WatchlistsPage({super.key, this.onStockSelected});

  @override
  ConsumerState<WatchlistsPage> createState() => _WatchlistsPageState();
}

class _WatchlistsPageState extends ConsumerState<WatchlistsPage> {
  String? _selectedWatchlistId;
  String _watchlistSearchQuery = '';
  final TextEditingController _watchlistSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(watchlistsProvider.notifier).refresh();
    });
    _watchlistSearchController.addListener(() {
      setState(() {
        _watchlistSearchQuery = _watchlistSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _watchlistSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final watchlistsAsync = ref.watch(watchlistsProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.scaffoldBackground,
              Color.alphaBlend(ModuleColors.market.withValues(alpha: 0.05), colors.scaffoldBackground),
              colors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: watchlistsAsync.when(
            data: (watchlists) {
              if (watchlists.isEmpty) {
                return const Center(child: Text('No watchlists available.'));
              }

              // Filter watchlists by search
              final filteredWatchlists = watchlists.where((w) {
                if (_watchlistSearchQuery.isEmpty) return true;
                return w.name.toLowerCase().contains(_watchlistSearchQuery);
              }).toList();

              // For Desktop: select first if none selected
              if (!isMobile && (_selectedWatchlistId == null || !watchlists.any((w) => w.id == _selectedWatchlistId))) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _selectedWatchlistId = watchlists.first.id);
                  }
                });
              }

              final selectedWatchlist = watchlists.firstWhere(
                (w) => w.id == _selectedWatchlistId,
                orElse: () => watchlists.first,
              );

              // Mobile View Logic
              if (isMobile) {
                if (_selectedWatchlistId != null) {
                  // Mobile Detail View
                  return WatchlistMobileDetailView(
                    watchlist: selectedWatchlist,
                    onBack: () => setState(() => _selectedWatchlistId = null),
                    onStockSelected: widget.onStockSelected,
                  );
                }

                // Mobile Master List View (Matching Screenshot 1 Left)
                return _buildMobileMasterList(context, watchlists, filteredWatchlists);
              }

              // Desktop View: Two-pane layout
              return _buildDesktopLayout(context, watchlists, selectedWatchlist);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading watchlists: $e')),
          ),
        ),
      ),
    );
  }

  /// Mobile Master List matching Screenshot 1 (Left)
  Widget _buildMobileMasterList(
    BuildContext context,
    List<Watchlist> allWatchlists,
    List<Watchlist> filteredWatchlists,
  ) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Watchlist',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Create and manage your custom watchlists to track the stocks that matter to you.',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),

        // Search watchlists...
        TextField(
          controller: _watchlistSearchController,
          style: TextStyle(color: colors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search watchlists...',
            hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6), fontSize: 13),
            prefixIcon: Icon(Icons.search, size: 18, color: colors.textSecondary),
            filled: true,
            fillColor: colors.surface.withValues(alpha: 0.6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ModuleColors.market, width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // + Create New Watchlist Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {
              CreateWatchlistDialog.show(
                context,
                onCreated: (name) {
                  ref.read(watchlistsProvider.notifier).createWatchlist(name);
                },
              );
            },
            icon: Icon(Icons.add, size: 18, color: colors.actionPrimaryFg),
            label: Text(
              'Create New Watchlist',
              style: TextStyle(color: colors.actionPrimaryFg, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ModuleColors.market,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Section Title: My Watchlists (N)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Watchlists (${allWatchlists.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.swap_vert, size: 20, color: colors.textSecondary),
          ],
        ),
        const SizedBox(height: 12),

        // List of Watchlist Cards
        Expanded(
          child: filteredWatchlists.isEmpty
              ? Center(
                  child: Text(
                    'No watchlists found.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  itemCount: filteredWatchlists.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final list = filteredWatchlists[index];
                    final isDefault = list.isDefault;

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedWatchlistId = list.id);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: 0.7),
                          border: Border.all(
                            color: isDefault ? ModuleColors.market.withValues(alpha: 0.5) : colors.border.withValues(alpha: 0.4),
                            width: isDefault ? 1.2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            // Icon Box
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: colors.scaffoldBackground.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isDefault ? Icons.star_rounded : _getIconForIndex(index),
                                color: isDefault ? ModuleColors.market : colors.textSecondary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Name and stock count
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          list.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: ModuleColors.market.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Default',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: ModuleColors.market,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${list.items.length} stocks',
                                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            // 3-dots Menu
                            if (!isDefault)
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.more_vert, size: 18, color: colors.textSecondary),
                                onSelected: (action) async {
                                  if (action == 'edit') {
                                    EditWatchlistDialog.show(
                                      context,
                                      currentName: list.name,
                                      onSaved: (newName) {
                                        ref.read(watchlistsProvider.notifier).updateWatchlist(list.id, newName);
                                      },
                                    );
                                  } else if (action == 'delete') {
                                    final confirm = await ConfirmationDialog.show(
                                      context: context,
                                      title: 'Delete Watchlist',
                                      subtitle: 'This action cannot be undone',
                                      message: 'Are you sure you want to delete "${list.name}"?',
                                      icon: Icons.warning_amber_rounded,
                                      confirmText: 'Delete',
                                      isDestructive: true,
                                    );
                                    if (confirm) {
                                      ref.read(watchlistsProvider.notifier).deleteWatchlist(list.id);
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit Name'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, color: colors.statusError, size: 18),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: colors.statusError)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              const SizedBox(width: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Desktop Layout (Sidebar + Management View)
  Widget _buildDesktopLayout(
    BuildContext context,
    List<Watchlist> watchlists,
    Watchlist selectedWatchlist,
  ) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Watchlist',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create and manage your custom watchlists to track the stocks that matter to you.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                CreateWatchlistDialog.show(
                  context,
                  onCreated: (name) {
                    ref.read(watchlistsProvider.notifier).createWatchlist(name);
                  },
                );
              },
              icon: Icon(Icons.add, size: 18, color: colors.actionPrimaryFg),
              label: Text(
                'Create Watchlist',
                style: TextStyle(color: colors.actionPrimaryFg, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ModuleColors.market,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Tabs
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 12, right: 16, left: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: ModuleColors.market, width: 2)),
                ),
                child: Text(
                  'My Watchlists',
                  style: TextStyle(color: ModuleColors.market, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Watchlists (${watchlists.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        itemCount: watchlists.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final list = watchlists[index];
                          final isSelected = list.id == _selectedWatchlistId;

                          return InkWell(
                            onTap: () => setState(() => _selectedWatchlistId = list.id),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? ModuleColors.market.withValues(alpha: 0.1) : colors.surface,
                                border: Border.all(
                                  color: isSelected ? ModuleColors.market : colors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    list.isDefault ? Icons.star_rounded : Icons.list_alt_rounded,
                                    color: isSelected ? ModuleColors.market : colors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          list.name,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? context.textPrimary : colors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${list.items.length} stocks',
                                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (list.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: ModuleColors.market.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text('Default', style: TextStyle(fontSize: 10, color: ModuleColors.market, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Main Content
              Expanded(
                child: WatchlistManagementView(
                  watchlist: selectedWatchlist,
                  onStockSelected: widget.onStockSelected,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconForIndex(int index) {
    const icons = [
      Icons.bar_chart_rounded,
      Icons.pie_chart_outline_rounded,
      Icons.energy_savings_leaf_outlined,
      Icons.trending_up_rounded,
      Icons.folder_outlined,
    ];
    return icons[index % icons.length];
  }
}
