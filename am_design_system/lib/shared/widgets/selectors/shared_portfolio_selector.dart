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
    this.isCompact = false,
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

  /// Whether to show in compact mode (icon only)
  final bool isCompact;

  /// Accent color for the selector (defaults to ModuleColors.portfolio)
  final Color? accentColor;

  /// Whether to render in dark mode (defaults to context theme)
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;
    final effectiveAccent = accentColor ?? ModuleColors.portfolio;

    final textColor = colors.textPrimary;
    final subTextColor = colors.textSecondary;
    final cardBgColor = colors.cardSurface;
    final cardBorderColor = effectiveAccent.withValues(alpha: 0.35);
    final idleFieldBorder = colors.border.withValues(alpha: 0.45);

    String displayName = 'Select Portfolio';
    if (currentPortfolioName != null) {
      displayName = currentPortfolioName!;
    } else if (currentPortfolioId != null && portfolios.isNotEmpty) {
      try {
        final portfolio =
            portfolios.firstWhere((p) => idExtractor(p) == currentPortfolioId);
        displayName = nameExtractor(portfolio);
      } catch (_) {}
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

    List<PopupMenuEntry<String>> buildItems(BuildContext context) => portfolios
        .map((portfolio) {
          final pId = idExtractor(portfolio);
          final isSelected = pId == currentPortfolioId;
          return PopupMenuItem<String>(
            value: pId,
            padding: EdgeInsets.zero,
            child: _HoverablePortfolioMenuRow(
              label: nameExtractor(portfolio),
              isSelected: isSelected,
              accent: effectiveAccent,
              textColor: textColor,
              subTextColor: subTextColor,
              onRename: onRenamePortfolio == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onRenamePortfolio!(pId, nameExtractor(portfolio));
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Theme(
            data: menuTheme(context),
            child: PopupMenuButton<String>(
              tooltip: 'Select Portfolio',
              offset: const Offset(0, 48),
              color: cardBgColor,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cardBorderColor),
              ),
              elevation: 8,
              onSelected: (portfolioId) {
                final portfolio =
                    portfolios.firstWhere((p) => idExtractor(p) == portfolioId);
                onPortfolioSelected(portfolioId, nameExtractor(portfolio));
              },
              itemBuilder: buildItems,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.transparent : colors.cardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: idleFieldBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: subTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu row with module-accent hover text + soft highlight.
class _HoverablePortfolioMenuRow extends StatefulWidget {
  const _HoverablePortfolioMenuRow({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.textColor,
    required this.subTextColor,
    this.onRename,
  });

  final String label;
  final bool isSelected;
  final Color accent;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback? onRename;

  @override
  State<_HoverablePortfolioMenuRow> createState() =>
      _HoverablePortfolioMenuRowState();
}

class _HoverablePortfolioMenuRowState extends State<_HoverablePortfolioMenuRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered
              ? widget.accent.withValues(alpha: 0.16)
              : (widget.isSelected
                  ? widget.accent.withValues(alpha: 0.12)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          boxShadow: _hovered
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
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(
                  color: active ? widget.accent : widget.textColor,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (widget.onRename != null)
              GestureDetector(
                onTap: widget.onRename,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 4.0),
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
