import 'dart:async';
import 'dart:convert';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/am_market_common.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'journal_workflow_field_theme.dart';

/// One hit from market securities / instruments search.
class JournalSymbolSuggestion {
  const JournalSymbolSuggestion({
    required this.symbol,
    required this.name,
    this.exchange,
    this.category,
  });

  final String symbol;
  final String name;
  final String? exchange;
  final String? category;
}

/// Debounced symbol search with stocks / ETFs / other recommendations.
///
/// Used by Pre-Trade Symbol and Log Day Pre-Market Watchlist.
class JournalSymbolSuggestField extends StatefulWidget {
  const JournalSymbolSuggestField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Search stocks, ETFs…',
    this.enabled = true,
    this.decoration,
    this.onChanged,
    this.onSelected,
    this.clearOnSelect = false,
    this.textCapitalization = TextCapitalization.characters,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final bool enabled;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;

  /// Called when the user picks a suggestion (symbol is uppercased).
  final ValueChanged<JournalSymbolSuggestion>? onSelected;

  /// When true (watchlist), clear the field after a pick.
  final bool clearOnSelect;
  final TextCapitalization textCapitalization;

  @override
  State<JournalSymbolSuggestField> createState() =>
      _JournalSymbolSuggestFieldState();
}

class _JournalSymbolSuggestFieldState extends State<JournalSymbolSuggestField> {
  late final FocusNode _focusNode;
  var _ownsFocusNode = false;
  final _layerLink = LayerLink();
  final _overlayController = OverlayPortalController();
  Timer? _debounce;
  List<JournalSymbolSuggestion> _hits = const [];
  var _loading = false;
  var _picking = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _syncOverlay() {
    final shouldShow =
        _focusNode.hasFocus && (_hits.isNotEmpty || _loading);
    if (shouldShow) {
      if (!_overlayController.isShowing) _overlayController.show();
    } else if (_overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Delay hide so a pointer-down on a suggestion can set `_picking` first.
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (!mounted || _focusNode.hasFocus || _picking) return;
        setState(() => _hits = const []);
        _syncOverlay();
      });
    } else if (widget.controller.text.trim().isNotEmpty) {
      _scheduleSearch(widget.controller.text);
    }
    _syncOverlay();
  }

  void _onTextChanged() {
    if (_picking) return;
    widget.onChanged?.call(widget.controller.text);
    _scheduleSearch(widget.controller.text);
  }

  void _scheduleSearch(String raw) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.isEmpty) {
      setState(() {
        _hits = const [];
        _loading = false;
      });
      _syncOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    _syncOverlay();
    final hits = await _fetchSuggestions(query);
    if (!mounted) return;
    setState(() {
      _hits = _focusNode.hasFocus ? hits : const [];
      _loading = false;
    });
    _syncOverlay();
  }

  Future<List<JournalSymbolSuggestion>> _fetchSuggestions(String query) async {
    try {
      final fromSecurities = await _searchSecuritiesGet(query);
      if (fromSecurities.isNotEmpty) return fromSecurities;
    } catch (e) {
      AppLogger.warning(
        'Securities GET suggest failed: $e',
        tag: 'JournalSymbolSuggestField',
      );
    }

    try {
      final api = ApiService();
      final instruments = await api.searchInstruments(query, 'UPSTOX');
      final parsed = _parseInstruments(instruments);
      if (parsed.isNotEmpty) return parsed;

      final raw = await api.searchSecurities(query);
      return _parseSecurities(raw);
    } catch (e) {
      AppLogger.warning(
        'Instrument/securities fallback failed: $e',
        tag: 'JournalSymbolSuggestField',
      );
      return const [];
    }
  }

  Future<List<JournalSymbolSuggestion>> _searchSecuritiesGet(
    String query,
  ) async {
    final uri = Uri.parse('${ApiService.baseUrl}/v1/securities/search').replace(
      queryParameters: {
        'query': query,
        'smartRecommendations': 'true',
        'category': 'ALL',
        'limit': '8',
      },
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      if (GetIt.I.isRegistered<SecureStorageService>()) {
        final token = await GetIt.I<SecureStorageService>().getAccessToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (_) {}

    final response = await http.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      AppLogger.warning(
        'Securities search HTTP ${response.statusCode}',
        tag: 'JournalSymbolSuggestField',
      );
      return const [];
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) return _parseSecurities(decoded);
    if (decoded is Map && decoded['data'] is List) {
      return _parseSecurities(decoded['data'] as List);
    }
    if (decoded is Map && decoded['results'] is List) {
      return _parseSecurities(decoded['results'] as List);
    }
    return const [];
  }

  List<JournalSymbolSuggestion> _parseSecurities(List<dynamic> raw) {
    final out = <JournalSymbolSuggestion>[];
    for (final row in raw) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      final key = map['key'];
      String symbol = '';
      if (key is Map) {
        symbol = (key['symbol'] ?? key['tradingSymbol'] ?? '').toString();
      }
      if (symbol.isEmpty) {
        symbol = (map['symbol'] ?? map['tradingSymbol'] ?? '').toString();
      }
      symbol = symbol.trim().toUpperCase();
      if (symbol.isEmpty) continue;

      final meta = map['metadata'];
      String name = symbol;
      String? category;
      if (meta is Map) {
        final company = (meta['companyName'] ?? meta['name'] ?? '').toString();
        if (company.trim().isNotEmpty) name = company.trim();
        category = meta['category']?.toString() ??
            meta['instrumentType']?.toString() ??
            meta['securityType']?.toString();
      }
      category ??= map['category']?.toString();

      out.add(
        JournalSymbolSuggestion(
          symbol: symbol,
          name: name,
          exchange: map['exchange']?.toString() ??
              (key is Map ? key['exchange']?.toString() : null),
          category: category,
        ),
      );
      if (out.length >= 8) break;
    }
    return out;
  }

  List<JournalSymbolSuggestion> _parseInstruments(
    List<Map<String, dynamic>> raw,
  ) {
    final out = <JournalSymbolSuggestion>[];
    for (final map in raw) {
      final symbol = (map['symbol'] ??
              map['tradingSymbol'] ??
              map['tradingsymbol'] ??
              '')
          .toString()
          .trim()
          .toUpperCase();
      if (symbol.isEmpty) continue;
      final name = (map['displayName'] ??
              map['description'] ??
              map['name'] ??
              symbol)
          .toString()
          .trim();
      out.add(
        JournalSymbolSuggestion(
          symbol: symbol,
          name: name.isEmpty ? symbol : name,
          exchange: map['exchange']?.toString(),
          category: map['instrumentType']?.toString() ??
              map['segment']?.toString(),
        ),
      );
      if (out.length >= 8) break;
    }
    return out;
  }

  void _pick(JournalSymbolSuggestion hit) {
    _picking = true;
    _debounce?.cancel();
    if (widget.clearOnSelect) {
      widget.controller.clear();
    } else {
      widget.controller.value = TextEditingValue(
        text: hit.symbol,
        selection: TextSelection.collapsed(offset: hit.symbol.length),
      );
    }
    widget.onSelected?.call(hit);
    if (!widget.clearOnSelect) {
      widget.onChanged?.call(hit.symbol);
    }
    setState(() => _hits = const []);
    _overlayController.hide();
    _focusNode.unfocus();
    // Keep `_picking` true briefly so the focus-loss hide path does not race.
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _picking = false;
    });
  }

  Widget _buildOverlayMenu() {
    final theme = Theme.of(context);
    final colors = context.colors;
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 280;

    return CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      offset: Offset(0, (box?.size.height ?? 48) + 4),
      child: Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 8,
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: SizedBox(
            width: width,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: _loading && _hits.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _hits.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: colors.border.withValues(alpha: 0.25),
                      ),
                      itemBuilder: (context, index) {
                        final hit = _hits[index];
                        final subtitle = [
                          if (hit.name != hit.symbol) hit.name,
                          if (hit.category != null && hit.category!.isNotEmpty)
                            hit.category,
                          if (hit.exchange != null && hit.exchange!.isNotEmpty)
                            hit.exchange,
                        ].join(' · ');
                        // Pointer-down (not tap) — focus loss otherwise removes
                        // this row before mouse-up completes on Flutter web.
                        return Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (_) => _pick(hit),
                          child: ListTile(
                            dense: true,
                            mouseCursor: SystemMouseCursors.click,
                            leading: Icon(
                              Icons.show_chart,
                              size: 18,
                              color: ModuleColors.trade,
                            ),
                            title: Text(
                              hit.symbol,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: subtitle.isEmpty
                                ? null
                                : Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.textSecondary,
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseDecoration = widget.decoration ??
        journalWorkflowDecoration(
          context,
          hintText: widget.hintText,
        );

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) => _buildOverlayMenu(),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          textCapitalization: widget.textCapitalization,
          style: theme.textTheme.bodyLarge,
          decoration: baseDecoration.copyWith(
            prefixIcon: baseDecoration.prefixIcon ??
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: ModuleColors.trade,
                ),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : baseDecoration.suffixIcon,
          ),
          onSubmitted: (_) {
            final t = widget.controller.text.trim();
            if (t.isNotEmpty) {
              _pick(
                JournalSymbolSuggestion(symbol: t.toUpperCase(), name: t),
              );
            }
          },
        ),
      ),
    );
  }
}
