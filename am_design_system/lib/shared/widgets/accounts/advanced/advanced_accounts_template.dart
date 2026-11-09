import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/module/module_config.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_extensions.dart';
import 'advanced_account_row.dart';
import 'advanced_accounts_cards.dart';
import 'advanced_accounts_table.dart';

/// Shared advanced accounts table/card UI (visual twin of holdings).
///
/// Domain-neutral — callers supply [AdvancedAccountRow]s and own category /
/// broker chips outside this template.
class AdvancedAccountsTemplate extends StatefulWidget {
  const AdvancedAccountsTemplate({
    required this.accounts,
    required this.isLoading,
    super.key,
    this.errorMessage,
    this.onRowTap,
    this.onRefresh,
    this.itemsPerPage = 20,
    this.accentColor,
    this.initialSearchQuery = '',
    this.emptyTitle = 'No accounts found',
    this.emptySubtitle = 'Linked accounts will appear here',
    this.sectionTitle,
    this.sectionBadge,
    this.toolbarLeading,
    this.footerNoun = 'accounts',
    this.footerCenterNote,
    this.searchHint = 'Search accounts, broker, DP ID…',
  });

  final List<AdvancedAccountRow> accounts;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<AdvancedAccountRow>? onRowTap;
  final VoidCallback? onRefresh;
  final int itemsPerPage;
  final Color? accentColor;
  final String initialSearchQuery;
  final String emptyTitle;
  final String emptySubtitle;
  final String? sectionTitle;
  final String? sectionBadge;

  /// Replaces section title/badge on the left of the toolbar (e.g. category tabs).
  final Widget? toolbarLeading;
  final String footerNoun;
  final String? footerCenterNote;
  final String searchHint;

  @override
  State<AdvancedAccountsTemplate> createState() =>
      _AdvancedAccountsTemplateState();
}

class _AdvancedAccountsTemplateState extends State<AdvancedAccountsTemplate>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<AdvancedAccountRow> _sortedAccounts = [];
  late AnimationController _refreshController;
  String _viewMode = 'table';
  late final TextEditingController _searchController;
  String _searchQuery = '';

  Color get _accent => widget.accentColor ?? ModuleColors.dashboard;

  static const double _controlHeight = 36;

  @override
  void initState() {
    super.initState();
    _sortedAccounts = List.from(widget.accounts);
    _searchQuery = widget.initialSearchQuery;
    _searchController = TextEditingController(text: _searchQuery);
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AdvancedAccountsTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accounts != oldWidget.accounts) {
      _sortedAccounts = List.from(widget.accounts);
      if (_sortColumnIndex != null) {
        _applySort(_sortColumnIndex!, _sortAscending);
      }
      _currentPage = 0;
    }
    if (widget.initialSearchQuery != oldWidget.initialSearchQuery) {
      _searchQuery = widget.initialSearchQuery;
      if (_searchController.text != _searchQuery) {
        _searchController.text = _searchQuery;
      }
      _currentPage = 0;
    }
  }

  int get _totalPages {
    final n = (_filteredAccounts.length / widget.itemsPerPage).ceil();
    return n < 1 ? 1 : n;
  }

  List<AdvancedAccountRow> get _filteredAccounts =>
      _sortedAccounts.where((a) => a.matchesQuery(_searchQuery)).toList();

  List<AdvancedAccountRow> get _paginatedAccounts {
    final startIndex = _currentPage * widget.itemsPerPage;
    final endIndex =
        (startIndex + widget.itemsPerPage).clamp(0, _filteredAccounts.length);
    if (startIndex >= _filteredAccounts.length) return const [];
    return _filteredAccounts.sublist(startIndex, endIndex);
  }

  void _applySort(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
    _sortedAccounts.sort((a, b) {
      int result;
      // Column order: BROKER | TYPE | TITLE | DP/ID | NOMINEE | EMAIL | MOBILE | STATUS | VALUE
      switch (columnIndex) {
        case 0:
          result = a.displayBroker.compareTo(b.displayBroker);
          break;
        case 1:
          result = a.displayType.compareTo(b.displayType);
          break;
        case 2:
          result = a.displayTitle.compareTo(b.displayTitle);
          break;
        case 3:
          result = a.displayAccountId.compareTo(b.displayAccountId);
          break;
        case 4:
          result = a.displayNominee.compareTo(b.displayNominee);
          break;
        case 5:
          result = a.displayEmail.compareTo(b.displayEmail);
          break;
        case 6:
          result = a.displayMobile.compareTo(b.displayMobile);
          break;
        case 7:
          result = a.displayStatus.compareTo(b.displayStatus);
          break;
        case 8:
          result = a.value.compareTo(b.value);
          break;
        default:
          result = 0;
      }
      return ascending ? result : -result;
    });
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() => _applySort(columnIndex, ascending));
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(0, (_totalPages - 1).clamp(0, _totalPages));
    });
  }

  void _onViewModeChanged(String mode) {
    setState(() => _viewMode = mode);
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 0;
    });
  }

  void _onRefreshPressed() {
    _refreshController.forward(from: 0);
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    } else {
      setState(() {
        _searchQuery = '';
        _searchController.clear();
        _currentPage = 0;
      });
    }
  }

  bool get _isDarkChrome {
    final scheme = Theme.of(context).colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) return true;
    return ThemeData.estimateBrightnessForColor(scheme.surface) ==
        Brightness.dark;
  }

  BoxDecoration get _segmentGroupDecoration => BoxDecoration(
        color: _isDarkChrome
            ? context.glassOverlay(0.06)
            : _accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: context.borderColor),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.errorMessage != null) {
      return _buildErrorState();
    }
    if (widget.accounts.isEmpty) {
      return Column(
        children: [
          _buildControlsHeader(),
          Expanded(child: _buildEmptyState()),
        ],
      );
    }

    return Column(
      children: [
        _buildControlsHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: _viewMode == 'table'
              ? AdvancedAccountsTable(
                  accounts: _paginatedAccounts,
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  accent: _accent,
                  onSort: _sort,
                  onRowTap: widget.onRowTap,
                )
              : AdvancedAccountsCards(
                  accounts: _paginatedAccounts,
                  isDarkChrome: _isDarkChrome,
                  accent: _accent,
                  onRowTap: widget.onRowTap,
                ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildControlsHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) => constraints.maxWidth >= 720
            ? _buildDesktopFilterRow()
            : _buildNarrowFilterLayout(),
      ),
    );
  }

  Widget _buildToolbarLeading() {
    if (widget.toolbarLeading != null) {
      return widget.toolbarLeading!;
    }
    final title = widget.sectionTitle;
    final badge = widget.sectionBadge;
    if (title == null || title.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (badge != null && badge.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF8B7355).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF8B7355).withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB8956C),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopFilterRow() => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        child: Row(
          children: [
            Expanded(child: _buildToolbarLeading()),
            const SizedBox(width: AppSpacing.sm),
            _buildViewModeToggle(),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(width: 240, child: _buildSearchField()),
            const SizedBox(width: AppSpacing.sm),
            _buildRefreshButton(),
          ],
        ),
      );

  Widget _buildNarrowFilterLayout() => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToolbarLeading(),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: _controlHeight,
              child: Row(
                children: [
                  _buildViewModeToggle(),
                  const Spacer(),
                  _buildRefreshButton(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSearchField(),
          ],
        ),
      );

  Widget _buildViewModeToggle() {
    Widget pill(String mode, IconData icon, String label) {
      final selected = _viewMode == mode;
      return InkWell(
        onTap: () => _onViewModeChanged(mode),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          height: _controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? _accent.withValues(alpha: 0.18) : null,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? _accent : context.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _accent : context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: _segmentGroupDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill('table', Icons.table_rows_rounded, 'Table'),
          pill('card', Icons.grid_view_rounded, 'Card'),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: widget.searchHint,
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return IconButton(
      tooltip: 'Refresh',
      onPressed: _onRefreshPressed,
      icon: RotationTransition(
        turns: _refreshController,
        child: const Icon(Icons.refresh_rounded),
      ),
    );
  }

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.statusError)
                .animate()
                .shake(hz: 2, offset: const Offset(4, 0))
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage!,
              style: TextStyle(color: context.statusError, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (widget.onRefresh != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _refreshController.forward(from: 0);
                  widget.onRefresh?.call();
                },
                icon: RotationTransition(
                  turns: _refreshController,
                  child: const Icon(Icons.refresh),
                ),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: context.textTertiary)
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 16),
            Text(
              widget.emptyTitle,
              style: TextStyle(
                color: context.textTertiary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.emptySubtitle,
              style: TextStyle(color: context.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _buildFooter() {
    final total = _filteredAccounts.length;
    final from = total == 0 ? 0 : _currentPage * widget.itemsPerPage + 1;
    final to =
        (_currentPage * widget.itemsPerPage + _paginatedAccounts.length)
            .clamp(0, total);
    final note = widget.footerCenterNote;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $from to $to of $total mapped ${widget.footerNoun}',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ),
          if (note != null && note.isNotEmpty)
            Expanded(
              child: Text(
                note,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: context.textTertiary,
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: _currentPage > 0
                    ? () => _goToPage(_currentPage - 1)
                    : null,
                child: const Text('Previous'),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${_currentPage + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                  ),
                ),
              ),
              TextButton(
                onPressed: _currentPage < _totalPages - 1
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
