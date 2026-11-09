import 'package:flutter/material.dart';

import 'package:am_design_system/core/module/module_config.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';

/// A reusable widget for selecting a portfolio, extracted from the Trade Sidebar logic.
/// Designed to be flexible with different portfolio data models via extractors.
class SharedPortfolioSelector<T> extends StatelessWidget {
  const SharedPortfolioSelector({
    super.key,
    required this.currentPortfolioId,
    required this.currentPortfolioName,
    required this.portfolios,
    required this.onPortfolioSelected,
    required this.nameExtractor,
    required this.idExtractor,
    this.onRenamePortfolio,
    this.defaultPortfolioId,
    this.onToggleDefault,
    this.isSelectableExtractor,
    this.showNoHoldingsBadgeExtractor,
    this.subtitleExtractor,
    this.isCompact = false,
    /// Single-line control for toolbars (no "Current Portfolio" title).
    this.dense = false,
    this.accentColor,
    this.isDark,
  });

  /// The ID of the currently selected portfolio
  final String? currentPortfolioId;

  /// The name of the currently selected portfolio
  final String? currentPortfolioName;

  /// List of portfolio objects
  final List<T> portfolios;

  /// Callback when a portfolio is selected
  final Function(String id, String name) onPortfolioSelected;

  /// Function to extract ID from the portfolio object
  final String Function(T) idExtractor;

  /// Function to extract Name from the portfolio object
  final String Function(T) nameExtractor;

  /// Optional callback to trigger when rename is requested
  final void Function(String id, String currentName)? onRenamePortfolio;

  /// Persisted default portfolio id (pinned + starred in menu).
  final String? defaultPortfolioId;

  /// One-tap set/clear default. Does not change the current selection.
  final void Function(String id, String name)? onToggleDefault;

  /// When false, row stays visible but cannot be selected (muted).
  final bool Function(T portfolio)? isSelectableExtractor;

  /// When true, shows a compact "No holdings" badge next to the name.
  final bool Function(T portfolio)? showNoHoldingsBadgeExtractor;

  /// Optional muted subtitle (broker id / PRAN) under the portfolio name.
  final String? Function(T portfolio)? subtitleExtractor;

  /// Whether to show in compact mode (icon only)
  final bool isCompact;

  /// Toolbar-friendly single-line dropdown without the section title.
  final bool dense;

  /// Accent color for the selector (defaults to ModuleColors.portfolio)
  final Color? accentColor;

  /// Whether to render in dark mode (defaults to context theme)
  final bool? isDark;

  List<T> _orderedPortfolios() {
    if (portfolios.isEmpty) return portfolios;
    final all = <T>[];
    final rest = <T>[];
    T? defaultItem;
    for (final p in portfolios) {
      final id = idExtractor(p);
      if (id == 'all') {
        all.add(p);
      } else if (defaultPortfolioId != null && id == defaultPortfolioId) {
        defaultItem = p;
      } else {
        rest.add(p);
      }
    }
    return [
      ...all,
      if (defaultItem != null) defaultItem,
      ...rest,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveAccent = accentColor ?? ModuleColors.portfolio;

    final textColor = colors.textPrimary;
    final subTextColor = colors.textSecondary;
    final cardBgColor = colors.cardSurface;
    final cardBorderColor = effectiveAccent.withValues(alpha: 0.35);
    final idleFieldBorder = colors.border.withValues(alpha: 0.45);
    final ordered = _orderedPortfolios();

    String displayName = 'Select Portfolio';
    String? displaySubtitle;
    T? currentPortfolio;
    if (currentPortfolioId != null && portfolios.isNotEmpty) {
      try {
        currentPortfolio =
            portfolios.firstWhere((p) => idExtractor(p) == currentPortfolioId);
      } catch (_) {}
    }
    if (currentPortfolioName != null) {
      displayName = currentPortfolioName!;
    } else if (currentPortfolio != null) {
      displayName = nameExtractor(currentPortfolio as T);
    }
    if (subtitleExtractor != null && currentPortfolio != null) {
      displaySubtitle = subtitleExtractor!(currentPortfolio as T);
    }

    ThemeData menuTheme(BuildContext context) => Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: effectiveAccent.withValues(alpha: 0.12),
          popupMenuTheme: PopupMenuThemeData(
            color: cardBgColor,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cardBorderColor),
            ),
          ),
        );

    // Items are disabled so star/rename taps do not also fire onSelected;
    // label tap pops with the portfolio id via Navigator.
    List<PopupMenuEntry<String>> buildItems(BuildContext context) => ordered
        .map((portfolio) {
          final pId = idExtractor(portfolio);
          final pName = nameExtractor(portfolio);
          final isSelected = pId == currentPortfolioId;
          final isDefault =
              defaultPortfolioId != null && pId == defaultPortfolioId;
          final canStar = onToggleDefault != null && pId != 'all';
          final selectable = isSelectableExtractor == null ||
              isSelectableExtractor!(portfolio);
          final showEmptyBadge = showNoHoldingsBadgeExtractor != null &&
              showNoHoldingsBadgeExtractor!(portfolio);
          final subtitle = subtitleExtractor?.call(portfolio);
          return PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: _HoverablePortfolioMenuRow(
              label: pName,
              subtitle: subtitle,
              isSelected: isSelected,
              isDefault: isDefault,
              selectable: selectable,
              showNoHoldingsBadge: showEmptyBadge,
              accent: effectiveAccent,
              textColor: textColor,
              subTextColor: subTextColor,
              onSelect:
                  !selectable ? null : () => Navigator.of(context).pop(pId),
              onRename: onRenamePortfolio == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onRenamePortfolio!(pId, pName);
                    },
              onToggleDefault: !canStar
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onToggleDefault!(pId, pName);
                    },
            ),
          );
        })
        .toList();

    if (isCompact) {
      if (portfolios.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Theme(
          data: menuTheme(context),
          child: PopupMenuButton<String>(
            tooltip: 'Select Portfolio',
            offset: const Offset(40, 0),
            color: cardBgColor,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cardBorderColor),
            ),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: effectiveAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.account_balance_wallet,
                  color: effectiveAccent, size: 20),
            ),
            onSelected: (portfolioId) {
              final portfolio =
                  portfolios.firstWhere((p) => idExtractor(p) == portfolioId);
              onPortfolioSelected(portfolioId, nameExtractor(portfolio));
            },
            itemBuilder: buildItems,
          ),
        ),
      );
    }

    // Always use a finite width. Unbounded Row/toolbar parents +
    // CrossAxisAlignment.stretch blanks the Flutter web view.
    return LayoutBuilder(
      builder: (context, outer) {
        const fallbackWidth = 280.0;
        final bounded = outer.maxWidth.isFinite && outer.maxWidth > 0;
        final menuWidth = bounded ? outer.maxWidth : fallbackWidth;
        final trigger = Theme(
          data: menuTheme(context),
          child: PopupMenuButton<String>(
            tooltip: 'Select Portfolio',
            offset: Offset(0, dense ? 40 : 48),
            color: cardBgColor,
            surfaceTintColor: Colors.transparent,
            constraints: BoxConstraints(
              minWidth: menuWidth,
              maxWidth: menuWidth,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cardBorderColor),
            ),
            elevation: 8,
            onSelected: (portfolioId) {
              final portfolio = portfolios
                  .firstWhere((p) => idExtractor(p) == portfolioId);
              onPortfolioSelected(portfolioId, nameExtractor(portfolio));
            },
            itemBuilder: buildItems,
            child: Container(
              width: menuWidth,
              height: dense ? 36 : null,
              padding: EdgeInsets.symmetric(
                horizontal: dense ? 10 : 12,
                vertical: dense ? 0 : 10,
              ),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(dense ? 999 : 8),
                border: Border.all(color: idleFieldBorder),
              ),
              child: Row(
                children: [
                  if (dense) ...[
                    Icon(
                      Icons.business_center_outlined,
                      size: 14,
                      color: effectiveAccent,
                    ),
                    const SizedBox(width: 6),
                  ] else if (defaultPortfolioId != null &&
                      currentPortfolioId == defaultPortfolioId) ...[
                    Icon(Icons.star, size: 14, color: effectiveAccent),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: dense
                        ? Text(
                            displayName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (displaySubtitle != null &&
                                  displaySubtitle.isNotEmpty)
                                Text(
                                  displaySubtitle,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: dense ? 16 : 18,
                    color: effectiveAccent.withValues(alpha: 0.85),
                  ),
                ],
              ),
            ),
          ),
        );

        if (dense) {
          return SizedBox(width: menuWidth, height: 36, child: trigger);
        }

        return Container(
          width: menuWidth,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Portfolio',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              trigger,
            ],
          ),
        );
      },
    );
  }
}

/// Menu row with module-accent hover text + soft highlight.
class _HoverablePortfolioMenuRow extends StatefulWidget {
  const _HoverablePortfolioMenuRow({
    required this.label,
    required this.isSelected,
    required this.isDefault,
    required this.accent,
    required this.textColor,
    required this.subTextColor,
    required this.onSelect,
    this.subtitle,
    this.selectable = true,
    this.showNoHoldingsBadge = false,
    this.onRename,
    this.onToggleDefault,
  });

  final String label;
  final String? subtitle;
  final bool isSelected;
  final bool isDefault;
  final bool selectable;
  final bool showNoHoldingsBadge;
  final Color accent;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback? onSelect;
  final VoidCallback? onRename;
  final VoidCallback? onToggleDefault;

  @override
  State<_HoverablePortfolioMenuRow> createState() =>
      _HoverablePortfolioMenuRowState();
}

class _HoverablePortfolioMenuRowState extends State<_HoverablePortfolioMenuRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || widget.isSelected;
    final muted = !widget.selectable;

    return MouseRegion(
      onEnter: muted ? null : (_) => setState(() => _hovered = true),
      onExit: muted ? null : (_) => setState(() => _hovered = false),
      cursor: muted ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: muted
              ? Colors.transparent
              : (_hovered
                  ? widget.accent.withValues(alpha: 0.16)
                  : (widget.isSelected
                      ? widget.accent.withValues(alpha: 0.12)
                      : Colors.transparent)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: !muted && _hovered
              ? [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.22),
                    blurRadius: 10,
                    spreadRadius: -2,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onSelect,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 160),
                      style: TextStyle(
                        color: muted
                            ? widget.subTextColor
                            : (active ? widget.accent : widget.textColor),
                        fontWeight: active && !muted
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.subtitle != null &&
                        widget.subtitle!.trim().isNotEmpty)
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          color: widget.subTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            if (widget.showNoHoldingsBadge)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.subTextColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'No holdings',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.subTextColor,
                  ),
                ),
              ),
            if (widget.onToggleDefault != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onToggleDefault,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                  child: Icon(
                    widget.isDefault ? Icons.star : Icons.star_border,
                    size: 16,
                    color: widget.isDefault
                        ? widget.accent
                        : (_hovered ? widget.accent : widget.subTextColor),
                  ),
                ),
              ),
            if (widget.onRename != null)
              GestureDetector(
                onTap: widget.onRename,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: _hovered ? widget.accent : widget.subTextColor,
                  ),
                ),
              ),
            if (widget.isSelected)
              Icon(Icons.check, size: 16, color: widget.accent),
          ],
        ),
      ),
    );
  }
}
