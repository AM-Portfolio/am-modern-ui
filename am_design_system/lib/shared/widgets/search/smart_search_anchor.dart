import 'dart:async';
import 'package:flutter/material.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import 'typewriter_hint_controller.dart';

/**
 * Reusable, high-speed Smart Search & Recommendation widget.
 * 
 * <p>Key Features:
 * <ul>
 *   <li>180ms debounced keystroke dispatch to /v1/securities/search?smartRecommendations=true.</li>
 *   <li>Clean dropdown menu showing company name and trading symbol.</li>
 *   <li>Circular initial badge displaying the capitalized first letter (e.g., 'H', 'T', 'A').</li>
 *   <li>Passes the clean trading symbol (e.g. 'HDFCBANK') to onSelected callback.</li>
 *   <li>Supports both full-width center search and compact top-header search mode.</li>
 *   <li>Optional animated ghost hints with smooth typewriter effect.</li>
 * </ul>
 */
class SmartSearchAnchor extends StatefulWidget {
  const SmartSearchAnchor({
    super.key,
    this.controller,
    required this.onSelected,
    this.onSubmit,
    this.hintText,
    this.animatedHints,
    this.compact = false,
    this.category = 'STOCKS',
    this.searchHandler,
    this.recentSearches = const [],
  });

  final TextEditingController? controller;
  final ValueChanged<String> onSelected;
  final VoidCallback? onSubmit;
  final String? hintText;
  final List<String>? animatedHints;
  final bool compact;
  final String category;
  final Future<List<SecurityDocument>?> Function(String query)? searchHandler;
  final List<String> recentSearches;

  @override
  State<SmartSearchAnchor> createState() => _SmartSearchAnchorState();
}

class _SmartSearchAnchorState extends State<SmartSearchAnchor> {
  late final TextEditingController _controller;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  List<SecurityDocument> _recommendations = [];
  bool _isLoading = false;

  final SecurityExplorerApi _searchApi = SecurityExplorerApi();
  TypewriterHintController? _typewriterController;
  String _currentAnimatedHint = '';
  bool _isAnimatingHint = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChanged);

    if (widget.animatedHints != null && widget.animatedHints!.isNotEmpty) {
      _typewriterController = TypewriterHintController(
        hints: widget.animatedHints!,
        onHintChanged: (text, isAnimating) {
          if (mounted) {
            setState(() {
              _currentAnimatedHint = text;
              _isAnimatingHint = isAnimating;
            });
          }
        },
      );
      _typewriterController!.start();
    }
  }

  @override
  void dispose() {
    _typewriterController?.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _typewriterController?.pause();
      if (_controller.text.trim().isNotEmpty) {
        _onQueryChanged(_controller.text);
      } else if (widget.recentSearches.isNotEmpty) {
        _showOverlay();
      }
    } else {
      if (_controller.text.isEmpty) {
        _typewriterController?.resume();
      }
      // Delay removal so tap/click events in overlay execute completely
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _handleSelection(String symbol) {
    _controller.text = symbol;
    _removeOverlay();
    _focusNode.unfocus();
    widget.onSelected(symbol);
    widget.onSubmit?.call();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      if (widget.recentSearches.isNotEmpty && _focusNode.hasFocus) {
        setState(() => _recommendations = []);
        _showOverlay();
      } else {
        _removeOverlay();
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 180), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        final List<SecurityDocument>? results;
        if (widget.searchHandler != null) {
          results = await widget.searchHandler!(trimmed);
        } else {
          results = await _searchApi.search(
            trimmed,
            smartRecommendations: true,
            category: widget.category,
            limit: 8,
          );
        }

        if (!mounted) return;
        setState(() {
          _recommendations = results ?? [];
          _isLoading = false;
        });

        if ((_recommendations.isNotEmpty || widget.recentSearches.isNotEmpty) && _focusNode.hasFocus) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final isQueryEmpty = _controller.text.trim().isEmpty;

    if (isQueryEmpty && widget.recentSearches.isEmpty) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: widget.compact ? 320 : size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(widget.compact ? -(320 - size.width) : 0, size.height + 6),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: context.colors.cardSurface,
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 280),
              child: isQueryEmpty
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                          child: Row(
                            children: [
                              Icon(Icons.history_rounded, size: 14, color: context.colors.textTertiary),
                              const SizedBox(width: 6),
                              Text(
                                'RECENTLY VIEWED',
                                style: TextStyle(
                                  color: context.colors.textTertiary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: context.colors.divider, height: 1),
                        ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: widget.recentSearches.length,
                          separatorBuilder: (context, index) => Divider(
                            color: context.colors.divider,
                            height: 1,
                            indent: 48,
                          ),
                          itemBuilder: (context, index) {
                            final sym = widget.recentSearches[index];
                            final initial = sym.isNotEmpty ? sym[0] : '?';
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _handleSelection(sym),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: context.colors.surface,
                                        border: Border.all(color: context.colors.border, width: 1),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          color: context.colors.actionPrimaryBg,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        sym,
                                        style: TextStyle(
                                          color: context.colors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.north_west_rounded, size: 14, color: context.colors.textTertiary),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: _recommendations.length,
                separatorBuilder: (context, index) => Divider(
                  color: context.colors.divider,
                  height: 1,
                  indent: 48,
                ),
                itemBuilder: (context, index) {
                  final item = _recommendations[index];
                  final symbol = item.key?.symbol ?? '';
                  final name = item.metadata?.companyName ?? symbol;
                  final initial = (name.isNotEmpty ? name[0] : (symbol.isNotEmpty ? symbol[0] : '?')).toUpperCase();

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => _handleSelection(symbol),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _handleSelection(symbol),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Row(
                          children: [
                            // Circular Initial Avatar Badge (e.g. 'H', 'T', 'A')
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.colors.surface,
                                border: Border.all(
                                  color: context.colors.border,
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: TextStyle(
                                  color: context.colors.actionPrimaryBg,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Company Name & Symbol
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    symbol,
                                    style: TextStyle(
                                      color: context.colors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Subtle Stock pill tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: context.colors.border, width: 0.5),
                              ),
                              child: Text(
                                'STOCK',
                                style: TextStyle(
                                  color: context.colors.textTertiary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.colors.actionPrimaryBg;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onQueryChanged,
        onSubmitted: (val) {
          _removeOverlay();
          final text = val.trim().toUpperCase();
          if (text.isNotEmpty) {
            widget.onSelected(text);
          }
          widget.onSubmit?.call();
        },
        textCapitalization: TextCapitalization.characters,
        style: TextStyle(
          color: context.colors.textPrimary,
          fontSize: widget.compact ? 13 : 15,
        ),
        decoration: InputDecoration(
          hintText: _typewriterController != null
              ? _currentAnimatedHint
              : (widget.hintText ?? (widget.compact ? 'Symbol…' : 'e.g. HDFC, TCS, RELIANCE')),
          hintStyle: TextStyle(
            color: context.colors.textTertiary,
            fontStyle: _typewriterController != null ? FontStyle.italic : FontStyle.normal,
          ),
          filled: true,
          fillColor: context.colors.scaffoldBackground,
          prefixIcon: Icon(Icons.search, color: accentColor, size: widget.compact ? 18 : 22),
          suffixIcon: _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  ),
                )
              : _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: context.colors.textTertiary, size: widget.compact ? 16 : 18),
                      onPressed: () {
                        _controller.clear();
                        _removeOverlay();
                        setState(() {});
                      },
                    )
                  : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 16,
            vertical: widget.compact ? 8 : 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 8 : 12),
            borderSide: BorderSide(color: context.colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 8 : 12),
            borderSide: BorderSide(color: context.colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 8 : 12),
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}
