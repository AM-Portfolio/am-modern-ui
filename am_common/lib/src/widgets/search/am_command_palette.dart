import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class CommandItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String category;
  final VoidCallback onSelected;

  CommandItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.onSelected,
  });
}

class AmCommandPalette extends StatefulWidget {
  final List<CommandItem> globalItems;

  /// Optional context banner (e.g. "Searching in Baskets").
  final String? bannerTitle;
  final String? bannerSubtitle;

  /// When set, invoked on query changes for live / ranked results.
  /// Call [emit] one or more times (progressive); category chip still filters.
  final Future<void> Function(
    String query,
    void Function(List<CommandItem> items, {bool isLoading}) emit,
  )? liveSearch;

  /// Synchronous seed for empty query when [liveSearch] is null.
  final List<CommandItem> Function()? emptySuggestions;

  /// Keep search field + banner + chips pinned while results scroll (mobile sheet).
  final bool stickyChrome;

  const AmCommandPalette({
    super.key,
    required this.globalItems,
    this.bannerTitle,
    this.bannerSubtitle,
    this.liveSearch,
    this.emptySuggestions,
    this.stickyChrome = false,
  });

  static Future<void> show(
    BuildContext context, {
    required List<CommandItem> items,
    String? bannerTitle,
    String? bannerSubtitle,
    Future<void> Function(
      String query,
      void Function(List<CommandItem> items, {bool isLoading}) emit,
    )? liveSearch,
    List<CommandItem> Function()? emptySuggestions,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Command Palette',
      barrierColor: Theme.of(context)
              .extension<AppColorsTheme>()
              ?.scaffoldBackground
              .withValues(alpha: 0.8) ??
          const Color(0xCC000000),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: AmCommandPalette(
            globalItems: items,
            bannerTitle: bannerTitle,
            bannerSubtitle: bannerSubtitle,
            liveSearch: liveSearch,
            emptySuggestions: emptySuggestions,
            stickyChrome: false,
          ),
        );
      },
    );
  }

  /// Mobile-friendly top-anchored sheet (keyboard-safe). Prefer inline morph
  /// via [MobileInlineSearchField] when embedding in module chrome.
  static Future<void> showMobileTop(
    BuildContext context, {
    required List<CommandItem> items,
    String? bannerTitle,
    String? bannerSubtitle,
    Future<void> Function(
      String query,
      void Function(List<CommandItem> items, {bool isLoading}) emit,
    )? liveSearch,
    List<CommandItem> Function()? emptySuggestions,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.85,
            child: AmCommandPalette(
              globalItems: items,
              bannerTitle: bannerTitle,
              bannerSubtitle: bannerSubtitle,
              liveSearch: liveSearch,
              emptySuggestions: emptySuggestions,
              stickyChrome: true,
            ),
          ),
        );
      },
    );
  }

  @override
  State<AmCommandPalette> createState() => _AmCommandPaletteState();
}

class _AmCommandPaletteState extends State<AmCommandPalette> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<CommandItem> _sourceItems = [];
  List<CommandItem> _filteredItems = [];
  bool _loading = false;
  int _liveGen = 0;

  @override
  void initState() {
    super.initState();
    _sourceItems = widget.emptySuggestions?.call() ?? widget.globalItems;
    _filteredItems = _sourceItems;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _selectedCategory = 'All';

  void _applyCategoryFilter() {
    setState(() {
      _filteredItems = _sourceItems.where((item) {
        return _selectedCategory == 'All' || item.category == _selectedCategory;
      }).toList();
    });
  }

  Future<void> _onQueryChanged(String raw) async {
    final live = widget.liveSearch;
    if (live == null) {
      final query = raw.toLowerCase();
      setState(() {
        _sourceItems = widget.globalItems.where((item) {
          if (query.isEmpty) return true;
          return item.title.toLowerCase().contains(query) ||
              item.subtitle.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query);
        }).toList();
      });
      _applyCategoryFilter();
      return;
    }

    final gen = ++_liveGen;
    setState(() => _loading = true);
    try {
      await live(raw, (items, {bool isLoading = false}) {
        if (!mounted || gen != _liveGen) return;
        setState(() {
          _sourceItems = items;
          _loading = isLoading;
        });
        _applyCategoryFilter();
      });
      if (!mounted || gen != _liveGen) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted || gen != _liveGen) return;
      setState(() => _loading = false);
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyCategoryFilter();
  }

  Widget _buildHighlightedText(
      String text, String query, TextStyle style, Color highlightColor) {
    if (query.isEmpty) return Text(text, style: style);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int startIndex = lowerText.indexOf(lowerQuery);
    if (startIndex == -1) return Text(text, style: style);

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, startIndex + query.length),
            style: style.copyWith(
              color: highlightColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(startIndex + query.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: 600,
              constraints: const BoxConstraints(maxHeight: 500),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: context.colors.border.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.stickyChrome)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: context.colors.border
                                    .withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      // Search Input
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                color: context.colors.textSecondary, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                onChanged: _onQueryChanged,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: context.colors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Search markets, portfolios, trades...',
                                  hintStyle: TextStyle(
                                      color: context.colors.textSecondary
                                          .withValues(alpha: 0.5)),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_loading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            if (query.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.close,
                                    color: context.colors.textSecondary,
                                    size: 20),
                                onPressed: () {
                                  _controller.clear();
                                  _onQueryChanged('');
                                },
                              ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: context.colors.textSecondary,
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              child: const Text('Cancel'),
                            )
                          ],
                        ),
                      ),
                      if (widget.bannerTitle != null &&
                          widget.bannerTitle!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.actionPrimaryBg
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.colors.actionPrimaryBg
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.bannerTitle!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                                if (widget.bannerSubtitle != null &&
                                    widget.bannerSubtitle!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.bannerSubtitle!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      // Category Filter Pills
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              'All',
                              'Baskets',
                              'Market',
                              'Portfolio',
                              'Trade',
                              'News',
                              'Action'
                            ].map((category) {
                              final isSelected = _selectedCategory == category;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => _onCategorySelected(category),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? context.colors.actionPrimaryBg
                                              .withValues(alpha: 0.15)
                                          : context.colors.surface
                                              .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? context.colors.actionPrimaryBg
                                            : context.colors.border
                                                .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? context.colors.textPrimary
                                            : context.colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Divider(
                          height: 1,
                          color: context.colors.border.withValues(alpha: 0.5)),

                      // Results List
                      Flexible(
                        child: _loading && _filteredItems.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              )
                            : _filteredItems.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.search_off,
                                            size: 48,
                                            color: context.colors.textSecondary
                                                .withValues(alpha: 0.5)),
                                        const SizedBox(height: 16),
                                        Text(
                                          query.isEmpty
                                              ? 'Start typing to search'
                                              : 'No results found for "$query"',
                                          style: TextStyle(
                                              color:
                                                  context.colors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: _filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      return InkWell(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          item.onSelected();
                                        },
                                        hoverColor: context
                                            .colors.actionPrimaryBg
                                            .withValues(alpha: 0.1),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: context.colors.border
                                                      .withValues(alpha: 0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(item.icon,
                                                    size: 20,
                                                    color: context
                                                        .colors.textPrimary),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _buildHighlightedText(
                                                        item.title,
                                                        query,
                                                        TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: context
                                                                .colors
                                                                .textPrimary),
                                                        context
                                                            .colors.statusInfo),
                                                    const SizedBox(height: 2),
                                                    _buildHighlightedText(
                                                        item.subtitle,
                                                        query,
                                                        TextStyle(
                                                            fontSize: 12,
                                                            color: context
                                                                .colors
                                                                .textSecondary),
                                                        context
                                                            .colors.statusInfo),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: context.colors.border
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  item.category,
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: context.colors
                                                          .textSecondary),
                                                ),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
