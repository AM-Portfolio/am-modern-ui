import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../favorite_filter_providers.dart';
import '../../../internal/domain/entities/favorite_filter.dart';
import '../../../internal/domain/entities/metrics_filter_config.dart';
import '../../cubit/favorite_filter/favorite_filter_cubit.dart';
import '../../widgets/filters/date_range_filter_group.dart';
import '../../widgets/filters/instrument_filter_group.dart';
import '../../widgets/filters/profit_loss_filter_group.dart';
import '../../widgets/filters/trade_characteristics_filter_group.dart';

/// Mobile-optimized filter panel with bottom sheet and tabs
/// Now used as a utility class to show filter bottom sheet
class MobileFilterPanel {
  /// Show filter bottom sheet - can be called from anywhere
  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required MetricsFilterConfig initialConfig,
    required Function(MetricsFilterConfig) onApplyFilter,
    VoidCallback? onReset,
  }) async {
    // Get the cubit from the existing provider - don't create a new one
    final cubit = await ref.read(favoriteFilterCubitProvider.future);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: _FilterBottomSheetContent(
          ref: ref,
          userId: userId,
          initialConfig: initialConfig,
          onApplyFilter: onApplyFilter,
          onReset: onReset,
        ),
      ),
    );
  }
}

/// Internal stateful widget for filter bottom sheet content
class _FilterBottomSheetContent extends ConsumerStatefulWidget {
  const _FilterBottomSheetContent({
    required this.ref,
    required this.userId,
    required this.initialConfig,
    required this.onApplyFilter,
    this.onReset,
  });

  final WidgetRef ref;
  final String userId;
  final MetricsFilterConfig initialConfig;
  final Function(MetricsFilterConfig) onApplyFilter;
  final VoidCallback? onReset;

  @override
  ConsumerState<_FilterBottomSheetContent> createState() => _FilterBottomSheetContentState();
}

class _FilterBottomSheetContentState extends ConsumerState<_FilterBottomSheetContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter groups
  DateRangeFilterGroup? _dateRangeGroup;
  InstrumentFilterGroup? _instrumentGroup;
  TradeCharacteristicsFilterGroup? _tradeCharGroup;
  ProfitLossFilterGroup? _profitLossGroup;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeFilters();
  }

  void _initializeFilters() {
    final config = widget.initialConfig;
    _initializeDateRangeFilter(config);
    _initializeInstrumentFilter(config);
    _initializeTradeCharFilter(config);
    _initializeProfitLossFilter(config);
  }

  void _initializeDateRangeFilter(MetricsFilterConfig config) {
    _dateRangeGroup = DateRangeFilterGroup(
      startDate: config.dateRange?.startDate,
      endDate: config.dateRange?.endDate,
      onChanged: (start, end) => setState(() {}),
    );
  }

  void _initializeInstrumentFilter(MetricsFilterConfig config) {
    _instrumentGroup = InstrumentFilterGroup(onChanged: () => setState(() {}));

    if (config.instrumentFilters == null) return;

    _instrumentGroup!.selectedSegments = List.from(config.instrumentFilters!.marketSegments);
    _instrumentGroup!.selectedIndexTypes = List.from(config.instrumentFilters!.indexTypes);
    _instrumentGroup!.selectedDerivativeTypes = List.from(config.instrumentFilters!.derivativeTypes);
    _instrumentGroup!.symbolsController.text = config.instrumentFilters!.baseSymbols.join(', ');
  }

  void _initializeTradeCharFilter(MetricsFilterConfig config) {
    _tradeCharGroup = TradeCharacteristicsFilterGroup(onChanged: () => setState(() {}));

    if (config.tradeCharacteristics == null) return;

    final tradeChar = config.tradeCharacteristics!;
    _tradeCharGroup!.selectedDirections = List.from(tradeChar.directions);
    _tradeCharGroup!.selectedStatuses = List.from(tradeChar.statuses);
    _tradeCharGroup!.strategiesController.text = tradeChar.strategies.join(', ');
    _tradeCharGroup!.tagsController.text = tradeChar.tags.join(', ');

    if (tradeChar.minHoldingTimeHours != null) {
      _tradeCharGroup!.minHoldingHoursController.text = tradeChar.minHoldingTimeHours.toString();
    }
    if (tradeChar.maxHoldingTimeHours != null) {
      _tradeCharGroup!.maxHoldingHoursController.text = tradeChar.maxHoldingTimeHours.toString();
    }
  }

  void _initializeProfitLossFilter(MetricsFilterConfig config) {
    _profitLossGroup = ProfitLossFilterGroup(onChanged: () => setState(() {}));

    if (config.profitLossFilters == null) return;

    final pnl = config.profitLossFilters!;
    if (pnl.minProfitLoss != null) {
      _profitLossGroup!.minPnLController.text = pnl.minProfitLoss.toString();
    }
    if (pnl.maxProfitLoss != null) {
      _profitLossGroup!.maxPnLController.text = pnl.maxProfitLoss.toString();
    }
    if (pnl.minPositionSize != null) {
      _profitLossGroup!.minPositionSizeController.text = pnl.minPositionSize.toString();
    }
    if (pnl.maxPositionSize != null) {
      _profitLossGroup!.maxPositionSizeController.text = pnl.maxPositionSize.toString();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Note: DateRangeFilterGroup doesn't have dispose method
    _instrumentGroup?.dispose();
    _tradeCharGroup?.dispose();
    _profitLossGroup?.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    var count = 0;
    if (_dateRangeGroup?.hasActiveFilters ?? false) count++;
    if (_instrumentGroup?.hasActiveFilters ?? false) count++;
    if (_tradeCharGroup?.hasActiveFilters ?? false) count++;
    if (_profitLossGroup?.hasActiveFilters ?? false) count++;
    return count;
  }

  void _applyFilters() {
    final config = MetricsFilterConfig(
      dateRange: _dateRangeGroup?.toFilterCriteria(),
      instrumentFilters: _instrumentGroup?.toFilterCriteria(),
      tradeCharacteristics: _tradeCharGroup?.toFilterCriteria(),
      profitLossFilters: _profitLossGroup?.toFilterCriteria(),
    );
    widget.onApplyFilter(config);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _dateRangeGroup?.reset();
      _instrumentGroup?.reset();
      _tradeCharGroup?.reset();
      _profitLossGroup?.reset();
    });
    widget.onReset?.call();
  }

  void _showSaveDialog() {
    if (!mounted) return;

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final cubit = context.read<FavoriteFilterCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: AlertDialog(
          title: const Text('Save as Favorite'),
          content: _buildSaveDialogContent(nameController, descriptionController),
          actions: _buildSaveDialogActions(dialogContext, nameController, descriptionController, cubit),
        ),
      ),
    );
  }

  Widget _buildSaveDialogContent(TextEditingController nameController, TextEditingController descriptionController) =>
      SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Filter Name',
                hintText: 'e.g., Last Month Profitable Trades',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Brief description of this filter',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      );

  List<Widget> _buildSaveDialogActions(
    BuildContext dialogContext,
    TextEditingController nameController,
    TextEditingController descriptionController,
    FavoriteFilterCubit cubit,
  ) => [
    TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
    FilledButton(
      onPressed: () => _handleSaveFilter(dialogContext, nameController, descriptionController, cubit),
      child: const Text('Save'),
    ),
  ];

  void _handleSaveFilter(
    BuildContext dialogContext,
    TextEditingController nameController,
    TextEditingController descriptionController,
    FavoriteFilterCubit cubit,
  ) {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a filter name')));
      return;
    }

    final config = _getCurrentFilterConfig();
    final description = descriptionController.text.trim();

    cubit.createFilter(
      userId: widget.userId,
      name: name,
      filterConfig: config,
      description: description.isEmpty ? null : description,
      isDefault: false,
    );

    Navigator.of(dialogContext).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved filter "$name"')));
  }

  MetricsFilterConfig _getCurrentFilterConfig() => MetricsFilterConfig(
    dateRange: _dateRangeGroup?.toFilterCriteria(),
    instrumentFilters: _instrumentGroup?.toFilterCriteria(),
    tradeCharacteristics: _tradeCharGroup?.toFilterCriteria(),
    profitLossFilters: _profitLossGroup?.toFilterCriteria(),
  );

  void _applyFavoriteFilter(FavoriteFilter filter) {
    setState(() {
      _disposeExistingFilters();
      _reloadFiltersFromConfig(filter.filterConfig);
    });
    widget.onApplyFilter(filter.filterConfig);
  }

  void _disposeExistingFilters() {
    _instrumentGroup?.dispose();
    _tradeCharGroup?.dispose();
    _profitLossGroup?.dispose();
  }

  void _reloadFiltersFromConfig(MetricsFilterConfig config) {
    _initializeDateRangeFilter(config);
    _initializeInstrumentFilter(config);
    _initializeTradeCharFilter(config);
    _initializeProfitLossFilter(config);
  }

  Widget _buildBottomSheet() {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.5),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandleBar(theme),
          _buildHeader(theme),
          _buildTabBar(theme),
          _buildTabContent(),
          _buildActionBar(theme, bottomPadding),
        ],
      ),
    );
  }

  Widget _buildHandleBar(ThemeData theme) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    width: 48,
    height: 4,
    decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
  );

  Widget _buildHeader(ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Icon(Icons.filter_list_rounded, size: 22, color: theme.primaryColor),
        const SizedBox(width: 10),
        Text('Filters', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
        if (_activeFilterCount > 0) _buildFilterBadge(theme),
        const SizedBox(width: 10),
        _buildFavoriteFilterButton(),
        const Spacer(),
        _buildCloseButton(),
      ],
    ),
  );

  Widget _buildFilterBadge(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(12)),
      child: Text(
        '$_activeFilterCount',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ),
  );

  Widget _buildFavoriteFilterButton() => BlocBuilder<FavoriteFilterCubit, FavoriteFilterState>(
    builder: (context, state) => state.when(
      initial: () => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      loaded: (filterList, selectedFilter) {
        if (filterList.filters.isEmpty) return const SizedBox.shrink();
        return _buildFavoriteButton(Theme.of(context), filterList, selectedFilter);
      },
      error: (message) => const SizedBox.shrink(),
    ),
  );

  Widget _buildCloseButton() => IconButton(
    icon: const Icon(Icons.close, size: 24),
    padding: const EdgeInsets.all(8),
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    onPressed: () => Navigator.of(context).pop(),
  );

  Widget _buildTabBar(ThemeData theme) => TabBar(
    controller: _tabController,
    isScrollable: true,
    labelColor: theme.primaryColor,
    unselectedLabelColor: theme.hintColor,
    indicatorColor: theme.primaryColor,
    indicatorWeight: 3,
    labelPadding: const EdgeInsets.symmetric(horizontal: 20),
    labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    padding: const EdgeInsets.symmetric(vertical: 8),
    tabs: const [
      Tab(text: 'Date', height: 48),
      Tab(text: 'Instrument', height: 48),
      Tab(text: 'Trade', height: 48),
      Tab(text: 'P&L', height: 48),
    ],
  );

  Widget _buildTabContent() => SizedBox(
    height: 180,
    child: TabBarView(
      controller: _tabController,
      children: [_buildDateTab(), _buildInstrumentTab(), _buildTradeTab(), _buildPnLTab()],
    ),
  );

  Widget _buildActionBar(ThemeData theme, double bottomPadding) => Container(
    padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomPadding),
    decoration: BoxDecoration(
      color: theme.cardColor,
      border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
    ),
    child: Row(
      children: [
        if (_activeFilterCount > 0) ...[
          _buildSaveButton(theme),
          const SizedBox(width: 8),
          _buildResetButton(),
          const SizedBox(width: 8),
        ],
        _buildApplyButton(),
      ],
    ),
  );

  Widget _buildSaveButton(ThemeData theme) => IconButton(
    onPressed: _showSaveDialog,
    icon: const Icon(Icons.bookmark_add_outlined, size: 22),
    tooltip: 'Save as Favorite',
    padding: const EdgeInsets.all(12),
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    style: IconButton.styleFrom(
      backgroundColor: theme.primaryColor.withOpacity(0.1),
      foregroundColor: theme.primaryColor,
    ),
  );

  Widget _buildResetButton() => Expanded(
    child: OutlinedButton.icon(
      onPressed: _resetFilters,
      icon: const Icon(Icons.clear_all, size: 18),
      label: const Text('Reset', style: TextStyle(fontSize: 14)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(0, 48),
      ),
    ),
  );

  Widget _buildApplyButton() => Expanded(
    flex: _activeFilterCount > 0 ? 2 : 1,
    child: FilledButton.icon(
      onPressed: _applyFilters,
      icon: const Icon(Icons.check, size: 18),
      label: const Text('Apply', style: TextStyle(fontSize: 14)),
      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), minimumSize: const Size(0, 48)),
    ),
  );

  Widget _buildDateTab() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: _dateRangeGroup!.buildContent(context),
  );

  Widget _buildInstrumentTab() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: _instrumentGroup!.buildContent(context),
  );

  Widget _buildTradeTab() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: _tradeCharGroup!.buildContent(context),
  );

  Widget _buildPnLTab() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: _profitLossGroup!.buildContent(context),
  );
  @override
  Widget build(BuildContext context) => _buildBottomSheet();

  Widget _buildFavoriteButton(ThemeData theme, FavoriteFilterList filterList, FavoriteFilter? selectedFilter) =>
      PopupMenuButton<String>(
        icon: _buildFavoriteIcon(theme, selectedFilter),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        tooltip: 'Favorite Filters',
        itemBuilder: (context) => _buildFavoriteMenuItems(theme, filterList, selectedFilter),
        onSelected: (value) => _handleFavoriteSelection(value, filterList),
      );

  Widget _buildFavoriteIcon(ThemeData theme, FavoriteFilter? selectedFilter) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: selectedFilter != null ? theme.primaryColor.withOpacity(0.15) : theme.cardColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: selectedFilter != null ? theme.primaryColor : theme.dividerColor),
    ),
    child: Icon(Icons.bookmark_rounded, size: 22, color: selectedFilter != null ? theme.primaryColor : theme.hintColor),
  );

  List<PopupMenuEntry<String>> _buildFavoriteMenuItems(
    ThemeData theme,
    FavoriteFilterList filterList,
    FavoriteFilter? selectedFilter,
  ) => [
    _buildFavoriteMenuHeader(theme, filterList),
    const PopupMenuDivider(),
    ..._buildFilterListItems(theme, filterList, selectedFilter),
    const PopupMenuDivider(),
    _buildManageMenuItem(theme),
  ];

  PopupMenuItem<String> _buildFavoriteMenuHeader(ThemeData theme, FavoriteFilterList filterList) =>
      PopupMenuItem<String>(
        enabled: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.bookmark_rounded, size: 20, color: theme.primaryColor),
            const SizedBox(width: 10),
            Text(
              'Favorites',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.primaryColor),
            ),
            const Spacer(),
            Text('${filterList.filters.length}', style: TextStyle(fontSize: 13, color: theme.hintColor)),
          ],
        ),
      );

  List<PopupMenuItem<String>> _buildFilterListItems(
    ThemeData theme,
    FavoriteFilterList filterList,
    FavoriteFilter? selectedFilter,
  ) => filterList.filters.map((filter) {
    final isSelected = selectedFilter?.id == filter.id;
    return PopupMenuItem<String>(
      value: filter.id,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _buildFilterListItemContent(theme, filter, isSelected),
    );
  }).toList();

  Widget _buildFilterListItemContent(ThemeData theme, FavoriteFilter filter, bool isSelected) => Row(
    children: [
      _buildSelectionIcon(theme, isSelected),
      const SizedBox(width: 10),
      if (filter.isDefault) ...[Icon(Icons.star, size: 16, color: Colors.amber[700]), const SizedBox(width: 6)],
      Expanded(
        child: Text(
          filter.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? theme.primaryColor : null,
          ),
        ),
      ),
      _buildFilterOptionsMenu(theme, filter),
    ],
  );

  Widget _buildSelectionIcon(ThemeData theme, bool isSelected) =>
      isSelected ? Icon(Icons.check_circle, size: 18, color: theme.primaryColor) : const SizedBox(width: 18);

  Widget _buildFilterOptionsMenu(ThemeData theme, FavoriteFilter filter) => PopupMenuButton<String>(
    icon: Icon(Icons.more_vert, size: 18, color: theme.hintColor),
    tooltip: 'Filter options',
    itemBuilder: (context) => [if (!filter.isDefault) _buildSetDefaultMenuItem(theme), _buildDeleteMenuItem(theme)],
    onSelected: (action) => _handleFilterAction(action, filter),
  );

  PopupMenuItem<String> _buildSetDefaultMenuItem(ThemeData theme) => PopupMenuItem<String>(
    value: 'set_default',
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(Icons.star_outline, size: 18, color: theme.hintColor),
        const SizedBox(width: 10),
        const Text('Set as Default', style: TextStyle(fontSize: 14)),
      ],
    ),
  );

  PopupMenuItem<String> _buildDeleteMenuItem(ThemeData theme) => PopupMenuItem<String>(
    value: 'delete',
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
        const SizedBox(width: 10),
        Text('Delete', style: TextStyle(fontSize: 14, color: Colors.red.shade400)),
      ],
    ),
  );

  PopupMenuItem<String> _buildManageMenuItem(ThemeData theme) => PopupMenuItem<String>(
    value: 'manage',
    child: Row(
      children: [
        Icon(Icons.settings_outlined, size: 18, color: theme.hintColor),
        const SizedBox(width: 12),
        Text(
          'Manage Filters',
          style: TextStyle(fontWeight: FontWeight.w500, color: theme.hintColor),
        ),
      ],
    ),
  );

  void _handleFavoriteSelection(String value, FavoriteFilterList filterList) {
    if (value == 'manage') {
      _showManageDialog(filterList);
    } else {
      final filter = filterList.filters.firstWhere((f) => f.id == value);
      if (mounted) {
        context.read<FavoriteFilterCubit>().selectFilter(filter);
        _applyFavoriteFilter(filter);
      }
    }
  }

  void _handleFilterAction(String action, FavoriteFilter filter) {
    if (action == 'set_default') {
      _setAsDefault(filter);
    } else if (action == 'delete') {
      _confirmDelete(filter);
    }
  }

  void _setAsDefault(FavoriteFilter filter) {
    if (!mounted) return;
    context.read<FavoriteFilterCubit>().setAsDefault(widget.userId, filter.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${filter.name}" set as default')));
  }

  void _confirmDelete(FavoriteFilter filter) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Favorite Filter'),
        content: Text('Are you sure you want to delete "${filter.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (mounted) {
                context.read<FavoriteFilterCubit>().deleteFilter(widget.userId, filter.id);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${filter.name}" deleted')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showManageDialog(FavoriteFilterList filterList) {
    final cubit = context.read<FavoriteFilterCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: AlertDialog(
          title: const Text('Manage Favorite Filters'),
          content: _buildManageDialogContent(filterList),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close'))],
        ),
      ),
    );
  }

  Widget _buildManageDialogContent(FavoriteFilterList filterList) => SizedBox(
    width: 500,
    height: 400,
    child: filterList.filters.isEmpty
        ? const Center(child: Text('No favorite filters yet'))
        : _buildFilterList(filterList),
  );

  Widget _buildFilterList(FavoriteFilterList filterList) => ListView.builder(
    itemCount: filterList.filters.length,
    itemBuilder: (context, index) => _buildFilterCard(filterList.filters[index]),
  );

  Widget _buildFilterCard(FavoriteFilter filter) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: _buildFilterLeadingIcon(filter.isDefault),
      title: Text(filter.name),
      subtitle: filter.description != null ? Text(filter.description!) : null,
      trailing: _buildFilterTrailingActions(filter),
    ),
  );

  Widget _buildFilterLeadingIcon(bool isDefault) =>
      Icon(isDefault ? Icons.star : Icons.bookmark_outline, color: isDefault ? Colors.amber[700] : null);

  Widget _buildFilterTrailingActions(FavoriteFilter filter) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (!filter.isDefault)
        IconButton(
          icon: const Icon(Icons.star_outline),
          onPressed: () => _setAsDefault(filter),
          tooltip: 'Set as default',
        ),
      IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () {
          Navigator.of(context).pop();
          _confirmDelete(filter);
        },
        tooltip: 'Delete',
      ),
    ],
  );
}
