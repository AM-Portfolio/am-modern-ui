import 'dart:ui';

import 'package:am_design_system/core/module/module_color_provider.dart';
import 'package:flutter/material.dart';

import 'am_command_palette.dart';
import 'mobile_global_search_overlay.dart';

export 'mobile_global_search_overlay.dart';

/// Provides global command-search items to mobile module chrome without
/// duplicating [AppShell] item lists.
class MobileSearchScope extends InheritedWidget {
  const MobileSearchScope({
    required this.getItems,
    required this.searchOpen,
    required super.child,
    this.openGlobalSearch,
    this.liveSearch,
    this.hintText,
    this.bannerTitle,
    this.bannerSubtitle,
    this.emptySuggestions,
    super.key,
  });

  final List<CommandItem> Function() getItems;

  /// Shared with AppShell so bottom nav can hide while search is open.
  final ValueNotifier<bool> searchOpen;

  /// Opens fullscreen Global Search (sets [searchOpen] / shell overlay).
  final VoidCallback? openGlobalSearch;

  final LiveSearchFn? liveSearch;
  final String? hintText;
  final String? bannerTitle;
  final String? bannerSubtitle;
  final List<CommandItem> Function()? emptySuggestions;

  static MobileSearchScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MobileSearchScope>();
  }

  static List<CommandItem> itemsOf(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) return const [];
    return scope.getItems();
  }

  static void setOpen(BuildContext context, bool open) {
    final scope = maybeOf(context);
    if (scope == null) return;
    if (scope.searchOpen.value != open) {
      scope.searchOpen.value = open;
    }
  }

  /// Opens Global Search when [openGlobalSearch] is wired; otherwise false.
  static bool tryOpenGlobalSearch(BuildContext context) {
    final scope = maybeOf(context);
    final open = scope?.openGlobalSearch;
    if (open == null) return false;
    open();
    return true;
  }

  @override
  bool updateShouldNotify(MobileSearchScope oldWidget) =>
      getItems != oldWidget.getItems ||
      searchOpen != oldWidget.searchOpen ||
      openGlobalSearch != oldWidget.openGlobalSearch ||
      liveSearch != oldWidget.liveSearch ||
      hintText != oldWidget.hintText ||
      bannerTitle != oldWidget.bannerTitle ||
      bannerSubtitle != oldWidget.bannerSubtitle ||
      emptySuggestions != oldWidget.emptySuggestions;
}

/// Compact mobile search field used when the Dashboard sticky row or module
/// pill strip morphs into search mode (fallback when shell overlay is absent).
class MobileInlineSearchField extends StatefulWidget {
  const MobileInlineSearchField({
    required this.items,
    required this.onClose,
    super.key,
    this.autofocus = true,
  });

  final List<CommandItem> items;
  final VoidCallback onClose;
  final bool autofocus;

  @override
  State<MobileInlineSearchField> createState() =>
      _MobileInlineSearchFieldState();
}

class _MobileInlineSearchFieldState extends State<MobileInlineSearchField>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late List<CommandItem> _filtered;
  late final AnimationController _reveal;

  @override
  void initState() {
    super.initState();
    _filtered = _suggested(widget.items);
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MobileSearchScope.setOpen(context, true);
      if (widget.autofocus) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _reveal.dispose();
    super.dispose();
  }

  List<CommandItem> _suggested(List<CommandItem> all) {
    const prefer = ['Action', 'Trade', 'Portfolio', 'Market'];
    final out = <CommandItem>[];
    for (final cat in prefer) {
      out.addAll(
          all.where((i) => i.category == cat).take(cat == 'Market' ? 4 : 2));
      if (out.length >= 8) break;
    }
    if (out.isEmpty) return all.take(8).toList();
    return out.take(8).toList();
  }

  void _onQuery(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _suggested(widget.items);
        return;
      }
      _filtered = widget.items
          .where(
            (i) =>
                i.title.toLowerCase().contains(q) ||
                i.subtitle.toLowerCase().contains(q) ||
                i.category.toLowerCase().contains(q),
          )
          .toList();
    });
  }

  void _close() {
    MobileSearchScope.setOpen(context, false);
    widget.onClose();
  }

  void _select(CommandItem item) {
    _close();
    item.onSelected();
  }

  Map<String, List<CommandItem>> _grouped(List<CommandItem> items) {
    final map = <String, List<CommandItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  Widget _highlight(String text, String query, TextStyle style, Color accent) {
    if (query.isEmpty) {
      return Text(text,
          style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final i = lower.indexOf(q);
    if (i < 0) {
      return Text(text,
          style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(
            text: text.substring(i, i + q.length),
            style: style.copyWith(color: accent, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text.substring(i + q.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = ModuleColorProvider.of(context);
    final query = _controller.text.trim();
    final showSuggested = query.isEmpty;
    final groups =
        showSuggested ? {'Suggested': _filtered} : _grouped(_filtered);

    final surfaceColor = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.08 : 0.04),
      isDark
          ? (theme.cardColor.withValues(alpha: 0.95))
          : Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
    );
    final borderColor = accent.withValues(alpha: isDark ? 0.35 : 0.28);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _reveal, curve: Curves.easeOutCubic),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Close search',
                        onPressed: _close,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: scheme.onSurface,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: _onQuery,
                          cursorColor: accent,
                          textInputAction: TextInputAction.search,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search markets, trades, actions…',
                            hintStyle: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.4),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: 20,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                          onPressed: () {
                            _controller.clear();
                            _onQuery('');
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: _reveal,
                curve: Curves.easeOutCubic,
              ),
              alignment: Alignment.topCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: () {
                        final media = MediaQuery.of(context);
                        final available = media.size.height -
                            media.padding.top -
                            media.viewInsets.bottom -
                            58 -
                            24;
                        return available.clamp(120.0, media.size.height * 0.42);
                      }(),
                    ),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: _filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(28),
                            child: Center(
                              child: Text(
                                'No matches',
                                style: TextStyle(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                            children: [
                              for (final entry in groups.entries) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 8, 12, 6),
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: accent.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),
                                for (final item in entry.value)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _select(item),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: accent.withValues(
                                                  alpha: 0.14),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              item.icon,
                                              size: 18,
                                              color: accent,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _highlight(
                                                  item.title,
                                                  query,
                                                  TextStyle(
                                                    color: scheme.onSurface,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  accent,
                                                ),
                                                if (item.subtitle.isNotEmpty)
                                                  Text(
                                                    item.subtitle,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: scheme.onSurface
                                                          .withValues(
                                                        alpha: 0.5,
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
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
