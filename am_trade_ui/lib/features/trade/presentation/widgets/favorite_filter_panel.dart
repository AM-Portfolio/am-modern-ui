import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../internal/domain/entities/favorite_filter.dart';
import '../cubit/favorite_filter/favorite_filter_cubit.dart';

/// Panel for managing and applying favorite filters
/// Displays a compact dropdown with all saved filters
class FavoriteFilterPanel extends StatelessWidget {
  const FavoriteFilterPanel({required this.userId, super.key, this.onFilterSelected});

  final String userId;
  final void Function(FavoriteFilter filter)? onFilterSelected;

  @override
  Widget build(BuildContext context) => BlocBuilder<FavoriteFilterCubit, FavoriteFilterState>(
    builder: (context, state) => state.when(
      initial: () => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      loaded: (filterList, selectedFilter) {
        if (filterList.filters.isEmpty) return const SizedBox.shrink();
        return _buildDropdown(context, filterList, selectedFilter);
      },
      error: (message) => const SizedBox.shrink(),
    ),
  );

  Widget _buildDropdownIcon(ThemeData theme, FavoriteFilter? selectedFilter) => Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(Icons.bookmark_rounded, color: theme.primaryColor, size: 20),
      if (selectedFilter != null)
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
            ),
            child: const Icon(Icons.check, size: 8, color: Colors.white),
          ),
        ),
    ],
  );

  PopupMenuItem<String> _buildHeaderMenuItem(ThemeData theme, int filterCount) => PopupMenuItem<String>(
    enabled: false,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Icon(Icons.bookmark_rounded, size: 18, color: theme.primaryColor),
        const SizedBox(width: 8),
        Text(
          'Favorite Filters',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
        ),
        const Spacer(),
        Text(
          '$filterCount',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  PopupMenuItem<String> _buildFilterMenuItem(
    BuildContext context,
    ThemeData theme,
    FavoriteFilter filter,
    bool isSelected,
  ) {
    final isDefault = filter.isDefault;

    return PopupMenuItem<String>(
      value: filter.id,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          if (isSelected) Icon(Icons.check_circle, size: 16, color: theme.primaryColor) else const SizedBox(width: 16),
          const SizedBox(width: 8),
          if (isDefault) ...[Icon(Icons.star, size: 14, color: Colors.amber[700]), const SizedBox(width: 4)],
          Expanded(
            child: Text(
              filter.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? theme.primaryColor : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelete(context, filter);
            },
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildManageMenuItem(ThemeData theme) => PopupMenuItem<String>(
    value: 'manage',
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Icon(Icons.settings_outlined, size: 18, color: theme.hintColor),
        const SizedBox(width: 12),
        Text(
          'Manage Filters',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.hintColor),
        ),
      ],
    ),
  );

  void _handleFilterSelection(BuildContext context, String value, FavoriteFilterList filterList) {
    if (value == 'manage') {
      _showManageDialog(context, filterList);
    } else {
      final filter = filterList.filters.firstWhere((f) => f.id == value);
      if (onFilterSelected != null) {
        onFilterSelected!(filter);
      }
      context.read<FavoriteFilterCubit>().selectFilter(filter);
    }
  }

  Widget _buildDropdown(BuildContext context, FavoriteFilterList filterList, FavoriteFilter? selectedFilter) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: _buildDropdownIcon(theme, selectedFilter),
      tooltip: 'Favorite Filters',
      itemBuilder: (context) => [
        _buildHeaderMenuItem(theme, filterList.filters.length),
        const PopupMenuDivider(),
        ...filterList.filters.map((filter) {
          final isSelected = selectedFilter?.id == filter.id;
          return _buildFilterMenuItem(context, theme, filter, isSelected);
        }),
        const PopupMenuDivider(),
        _buildManageMenuItem(theme),
      ],
      onSelected: (value) => _handleFilterSelection(context, value, filterList),
    );
  }

  Widget _buildFilterListTile(
    BuildContext dialogContext,
    BuildContext context,
    FavoriteFilterCubit cubit,
    FavoriteFilter filter,
  ) {
    final isDefault = filter.isDefault;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(isDefault ? Icons.star : Icons.bookmark_outline, color: isDefault ? Colors.amber[700] : null),
        title: Text(filter.name),
        subtitle: filter.description != null ? Text(filter.description!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDefault)
              IconButton(
                icon: const Icon(Icons.star_outline),
                onPressed: () => cubit.setAsDefault(userId, filter.id),
                tooltip: 'Set as default',
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _confirmDelete(context, filter);
              },
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageDialogContent(BuildContext dialogContext, BuildContext context, FavoriteFilterCubit cubit) =>
      BlocBuilder<FavoriteFilterCubit, FavoriteFilterState>(
        builder: (context, state) => state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (filterList, selectedFilter) => filterList.filters.isEmpty
              ? const Center(child: Text('No favorite filters yet'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filterList.filters.length,
                  itemBuilder: (context, index) {
                    final filter = filterList.filters[index];
                    return _buildFilterListTile(dialogContext, context, cubit, filter);
                  },
                ),
          error: (message) => Center(child: Text('Error: $message')),
        ),
      );

  void _showManageDialog(BuildContext context, FavoriteFilterList filterList) {
    final cubit = context.read<FavoriteFilterCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: AlertDialog(
          title: const Text('Manage Favorite Filters'),
          content: SizedBox(width: 500, child: _buildManageDialogContent(dialogContext, context, cubit)),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close'))],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FavoriteFilter filter) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Favorite Filter'),
        content: Text('Are you sure you want to delete "${filter.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<FavoriteFilterCubit>().deleteFilter(userId, filter.id);
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
