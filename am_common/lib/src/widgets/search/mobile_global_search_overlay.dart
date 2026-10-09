import 'dart:ui';

import 'package:am_design_system/core/module/module_color_provider.dart';
import 'package:am_design_system/core/theme/app_colors_theme.dart';
import 'package:flutter/material.dart';

import 'am_command_palette.dart';

typedef LiveSearchEmit = void Function(
  List<CommandItem> items, {
  bool isLoading,
});

typedef LiveSearchFn = Future<void> Function(String query, LiveSearchEmit emit);

/// Fullscreen mobile Global Search with left→right wave open / reverse close.
class MobileGlobalSearchOverlay extends StatefulWidget {
  const MobileGlobalSearchOverlay({
    required this.onClose,
    this.hintText = 'Search markets, portfolios, trades…',
    this.bannerTitle,
    this.bannerSubtitle,
    this.liveSearch,
    this.emptySuggestions,
    this.seedItems = const [],
    this.accent,
    super.key,
  });

  final VoidCallback onClose;
  final String hintText;
  final String? bannerTitle;
  final String? bannerSubtitle;
  final LiveSearchFn? liveSearch;
  final List<CommandItem> Function()? emptySuggestions;
  final List<CommandItem> seedItems;

  /// When set (e.g. from AppShell), wins over [ModuleColorProvider].
  final Color? accent;

  @override
  State<MobileGlobalSearchOverlay> createState() =>
      _MobileGlobalSearchOverlayState();
}

class _MobileGlobalSearchOverlayState extends State<MobileGlobalSearchOverlay>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _openCtrl;
  late final Animation<double> _wipe;
  late final Animation<double> _expand;
  late final Animation<double> _fade;

  List<CommandItem> _items = [];
  String _selectedCategory = 'All';
  bool _loading = false;
  int _liveGen = 0;
  bool _closing = false;

  static const _categories = [
    'All',
    'Baskets',
    'Market',
    'Portfolio',
    'Trade',
    'News',
    'Action',
  ];

  @override
  void initState() {
    super.initState();
    _items = widget.emptySuggestions?.call() ?? widget.seedItems;

    _openCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _wipe = CurvedAnimation(
      parent: _openCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _expand = CurvedAnimation(
      parent: _openCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(
      parent: _openCtrl,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = MediaQuery.disableAnimationsOf(context);
      if (reduce) {
        _openCtrl.value = 1;
        _focusNode.requestFocus();
      } else {
        _openCtrl.forward().then((_) {
          if (mounted) _focusNode.requestFocus();
        });
      }
      _runLive('');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _openCtrl.dispose();
    super.dispose();
  }

  Future<void> _close({VoidCallback? afterClose}) async {
    if (_closing) return;
    _closing = true;
    _focusNode.unfocus();
    if (mounted && !MediaQuery.disableAnimationsOf(context)) {
      try {
        await _openCtrl.reverse();
      } catch (_) {}
    }
    if (mounted) widget.onClose();
    afterClose?.call();
  }

  List<CommandItem> get _filtered {
    if (_selectedCategory == 'All') return _items;
    return _items.where((i) => i.category == _selectedCategory).toList();
  }

  Future<void> _runLive(String raw) async {
    final live = widget.liveSearch;
    if (live == null) {
      final q = raw.trim().toLowerCase();
      setState(() {
        _items = (widget.emptySuggestions?.call() ?? widget.seedItems)
            .where((i) {
          if (q.isEmpty) return true;
          return i.title.toLowerCase().contains(q) ||
              i.subtitle.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q);
        }).toList();
        _loading = false;
      });
      return;
    }

    final gen = ++_liveGen;
    setState(() => _loading = true);
    try {
      await live(raw, (items, {bool isLoading = false}) {
        if (!mounted || gen != _liveGen) return;
        setState(() {
          _items = items;
          _loading = isLoading;
        });
      });
      if (!mounted || gen != _liveGen) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted || gen != _liveGen) return;
      setState(() => _loading = false);
    }
  }

  void _select(CommandItem item) {
    final action = item.onSelected;
    _close(afterClose: action);
  }

  Map<String, List<CommandItem>> _grouped(List<CommandItem> items) {
    final map = <String, List<CommandItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = widget.accent ?? ModuleColorProvider.of(context);
    final media = MediaQuery.of(context);
    final query = _controller.text.trim();
    final filtered = _filtered;
    final groups = query.isEmpty
        ? {'Suggested': filtered}
        : _grouped(filtered);

    final themeColors = theme.extension<AppColorsTheme>();
    final baseSurface = isDark
        ? (themeColors?.scaffoldBackground ?? scheme.surface)
        : (themeColors?.surface ?? scheme.surface);
    final surface = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.10 : 0.05),
      baseSurface,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AnimatedBuilder(
        animation: _openCtrl,
        builder: (context, _) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Scrim expands with phase B
                Opacity(
                  opacity: _expand.value.clamp(0.0, 1.0),
                  child: Container(color: surface.withValues(alpha: 0.97)),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 18 * _expand.value,
                    sigmaY: 18 * _expand.value,
                  ),
                  child: const SizedBox.expand(),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Phase A: left→right wipe of search chrome
                        ClipPath(
                          clipper: _WaveRevealClipper(_wipe.value),
                          child: Opacity(
                            opacity: _fade.value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.96 + (0.04 * _wipe.value),
                              alignment: Alignment.centerLeft,
                              child: _buildSearchHeader(
                                context,
                                accent,
                                scheme,
                                isDark,
                              ),
                            ),
                          ),
                        ),
                        // Phase B: banner + chips + results fill remaining space
                        Expanded(
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: _expand.value.clamp(0.0, 1.0),
                              child: Opacity(
                                opacity: _expand.value.clamp(0.0, 1.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (widget.bannerTitle != null &&
                                        widget.bannerTitle!.isNotEmpty)
                                      _buildBanner(context, accent),
                                    _buildChips(context, accent, scheme),
                                    Expanded(
                                      child: _buildResults(
                                        context,
                                        accent,
                                        scheme,
                                        groups,
                                        query,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchHeader(
    BuildContext context,
    Color accent,
    ColorScheme scheme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: isDark ? 0.55 : 0.92),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: accent.withValues(alpha: 0.45),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Close search',
              onPressed: _close,
              icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _runLive,
                cursorColor: accent,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: accent.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (_controller.text.isNotEmpty)
              IconButton(
                tooltip: 'Clear',
                onPressed: () {
                  _controller.clear();
                  _runLive('');
                },
                icon: Icon(
                  Icons.clear_rounded,
                  size: 20,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, Color accent) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bannerTitle!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            if (widget.bannerSubtitle != null &&
                widget.bannerSubtitle!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                widget.bannerSubtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChips(
    BuildContext context,
    Color accent,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((category) {
            final selected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedCategory = category),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? accent.withValues(alpha: 0.18)
                          : scheme.surface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? accent
                            : scheme.outline.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? scheme.onSurface
                            : scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    Color accent,
    ColorScheme scheme,
    Map<String, List<CommandItem>> groups,
    String query,
  ) {
    if (_loading && _filtered.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            query.isEmpty ? 'Start typing to search' : 'No matches for "$query"',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              entry.key,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: accent.withValues(alpha: 0.8),
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
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, size: 18, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.subtitle.isNotEmpty)
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Left→right reveal clip (wave front).
class _WaveRevealClipper extends CustomClipper<Path> {
  _WaveRevealClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    final w = size.width * progress.clamp(0.0, 1.0);
    final path = Path();
    if (w <= 0) return path;
    // Soft leading edge: slight sine bulge
    final bulge = 12.0 * (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0);
    path.moveTo(0, 0);
    path.lineTo(w, 0);
    path.quadraticBezierTo(w + bulge, size.height / 2, w, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _WaveRevealClipper oldClipper) =>
      oldClipper.progress != progress;
}
