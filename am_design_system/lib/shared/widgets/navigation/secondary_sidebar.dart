import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/core/theme/app_colors_theme.dart';
import 'package:am_design_system/core/utils/conditional_mouse_region.dart';
import 'package:am_design_system/shared/widgets/navigation/sidebar_layout_metrics.dart';

/// Secondary sidebar item model for structured navigation
class SecondarySidebarItem {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? accentColor;
  final String? colorScheme; // For AppGlassmorphismV2 schemes
  final bool isSelected;
  final String? subtitle;

  SecondarySidebarItem({
    required this.title,
    required this.icon,
    this.onTap,
    this.trailing,
    this.accentColor,
    this.colorScheme,
    this.isSelected = false,
    this.subtitle,
  });
}

/// A collapsible section in the sidebar
class SecondarySidebarSection {
  final String title;
  final IconData? icon;
  final List<SecondarySidebarItem>? items;
  final Widget? customWidget; // For embedding complex widgets like selectors
  final bool initiallyExpanded;

  SecondarySidebarSection({
    required this.title,
    this.icon,
    this.items,
    this.customWidget,
    this.initiallyExpanded = true,
  });
}

/// A premium glassmorphic secondary sidebar component.
/// Displays context-specific navigation (Workspace, Market, etc.).
class SecondarySidebar extends StatelessWidget {
  const SecondarySidebar({
    super.key,
    this.title,
    this.subtitle,
    this.child,
    this.items,
    this.sections,
    this.header,
    this.footer,
    this.width = 250, // Standard width for secondary panel
    this.accentColor = const Color(0xFF6C5DD3),
    this.icon = Icons.grid_view_rounded,
    this.showDividers = false,
    this.isCompact = false,
    this.onToggleCollapse,
  }) : assert(child != null || items != null || sections != null, 'Either child, items, or sections must be provided');

  final String? title;
  final String? subtitle;
  final Widget? child;
  final List<SecondarySidebarItem>? items;
  final List<SecondarySidebarSection>? sections;
  final Widget? header;
  final Widget? footer;
  final double width;
  final Color accentColor;
  final IconData icon;
  final bool showDividers;
  final bool isCompact;
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).extension<AppColorsTheme>();
    final bg = isDark
        ? (colors?.scaffoldBackground ?? AppColors.darkBackground)
        : (colors?.scaffoldBackground ?? const Color(0xFFF9FAFB));
    final borderColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);

    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          right: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark),

          if (showDividers)
            Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),

          Expanded(
            child: child ??
                (sections != null
                    ? _buildSectionsList(context, isDark)
                    : _buildItemsList(context, items!, isDark)),
          ),

          if (footer != null && !isCompact)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SidebarLayoutMetrics.contentInset,
                16,
                SidebarLayoutMetrics.contentInset,
                24,
              ),
              child: footer!,
            ),
        ],
      ),
    );
  }

  Widget? _buildToggle(bool isDark) {
    if (onToggleCollapse == null) return null;
    return _SecondaryCollapseToggle(
      isCompact: isCompact,
      isDark: isDark,
      accentColor: accentColor,
      onToggle: onToggleCollapse!,
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final toggle = _buildToggle(isDark);
    final hasTitle = title != null && title!.trim().isNotEmpty;
    final hasCustomHeader = header != null;

    // Compact: single << / >> tile aligned with primary logo band.
    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.only(
          top: SidebarLayoutMetrics.topInset,
          bottom: SidebarLayoutMetrics.afterHeaderGap,
        ),
        child: SizedBox(
          height: SidebarLayoutMetrics.headerBandHeight,
          width: double.infinity,
          child: Center(child: toggle ?? const SizedBox.shrink()),
        ),
      );
    }

    // Expanded with no title/custom header: toggle-only band (Trade/Portfolio).
    if (!hasCustomHeader && !hasTitle && subtitle == null) {
      return Padding(
        padding: const EdgeInsets.only(
          top: SidebarLayoutMetrics.topInset,
          left: SidebarLayoutMetrics.contentInset,
          right: SidebarLayoutMetrics.contentInset,
          bottom: SidebarLayoutMetrics.afterHeaderGap,
        ),
        child: SizedBox(
          height: SidebarLayoutMetrics.headerBandHeight,
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerRight,
            child: toggle,
          ),
        ),
      );
    }

    if (hasCustomHeader) {
      return Padding(
        padding: const EdgeInsets.only(
          top: SidebarLayoutMetrics.topInset,
          left: SidebarLayoutMetrics.contentInset,
          right: SidebarLayoutMetrics.contentInset,
          bottom: SidebarLayoutMetrics.afterHeaderGap,
        ),
        child: SizedBox(
          height: SidebarLayoutMetrics.headerBandHeight,
          child: Row(
            children: [
              Expanded(child: header!),
              if (toggle != null) ...[
                const SizedBox(width: 8),
                toggle,
              ],
            ],
          ),
        ),
      );
    }

    final iconBox = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );

    return Padding(
      padding: const EdgeInsets.only(
        top: SidebarLayoutMetrics.topInset,
        left: SidebarLayoutMetrics.contentInset,
        right: SidebarLayoutMetrics.contentInset,
        bottom: SidebarLayoutMetrics.afterHeaderGap,
      ),
      child: SizedBox(
        height: SidebarLayoutMetrics.headerBandHeight,
        child: Row(
          children: [
            iconBox,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title!.toUpperCase(),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black87,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (toggle != null) toggle,
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    List<SecondarySidebarItem> itemList,
    bool isDark,
  ) {
    final gap = isCompact ? SidebarLayoutMetrics.navTileGap : 2.0;
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : SidebarLayoutMetrics.contentInset,
        vertical: isCompact ? 0 : 8,
      ),
      itemCount: itemList.length,
      separatorBuilder: (context, index) => SizedBox(height: gap),
      itemBuilder: (context, index) {
        return _SecondarySidebarTile(
          item: itemList[index],
          isDark: isDark,
          accentColor: accentColor,
          isCompact: isCompact,
        );
      },
    );
  }

  Widget _buildSectionsList(BuildContext context, bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 0 : 8),
      itemCount: sections!.length,
      itemBuilder: (context, index) {
        final section = sections![index];
        return _SecondarySidebarSectionWidget(
          section: section,
          isDark: isDark,
          accentColor: accentColor,
          isCompact: isCompact,
        );
      },
    );
  }
}

/// Collapse/expand control — inactive by default; FinDash highlight only while pressed.
class _SecondaryCollapseToggle extends StatefulWidget {
  const _SecondaryCollapseToggle({
    required this.isCompact,
    required this.isDark,
    required this.accentColor,
    required this.onToggle,
  });

  final bool isCompact;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onToggle;

  @override
  State<_SecondaryCollapseToggle> createState() =>
      _SecondaryCollapseToggleState();
}

class _SecondaryCollapseToggleState extends State<_SecondaryCollapseToggle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final iconColor = _pressed
        ? accent
        : (widget.isDark ? Colors.white54 : Colors.black87);

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: SidebarFinDashTile(
        isActive: _pressed,
        isDark: widget.isDark,
        accentColor: accent,
        size: SidebarLayoutMetrics.headerBandHeight,
        tooltip:
            widget.isCompact ? 'Expand sidebar' : 'Collapse sidebar',
        onTap: widget.onToggle,
        child: Icon(
          widget.isCompact
              ? Icons.keyboard_double_arrow_right
              : Icons.keyboard_double_arrow_left,
          size: 22,
          color: iconColor,
        ),
      ),
    );
  }
}

class _SecondarySidebarSectionWidget extends StatefulWidget {
  final SecondarySidebarSection section;
  final bool isDark;
  final Color accentColor;
  final bool isCompact;

  const _SecondarySidebarSectionWidget({
    required this.section,
    required this.isDark,
    required this.accentColor,
    this.isCompact = false,
  });

  @override
  State<_SecondarySidebarSectionWidget> createState() =>
      _SecondarySidebarSectionWidgetState();
}

class _SecondarySidebarSectionWidgetState
    extends State<_SecondarySidebarSectionWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.section.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final gap = widget.isCompact ? SidebarLayoutMetrics.navTileGap : 2.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.section.title.isNotEmpty && !widget.isCompact)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SidebarLayoutMetrics.contentInset,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.section.title.toUpperCase(),
                      style: TextStyle(
                        color: widget.isDark ? Colors.white38 : Colors.black54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  if (widget.section.items != null)
                    AnimatedRotation(
                      turns: _isExpanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.isDark ? Colors.white24 : Colors.black54,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (_isExpanded || widget.section.title.isEmpty) ...[
          if (widget.section.customWidget != null && !widget.isCompact)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SidebarLayoutMetrics.contentInset,
                vertical: 4,
              ),
              child: widget.section.customWidget!,
            ),
          if (widget.section.items != null)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal:
                    widget.isCompact ? 8 : SidebarLayoutMetrics.contentInset,
              ),
              itemCount: widget.section.items!.length,
              separatorBuilder: (_, __) => SizedBox(height: gap),
              itemBuilder: (_, index) => _SecondarySidebarTile(
                item: widget.section.items![index],
                isDark: widget.isDark,
                accentColor: widget.accentColor,
                isCompact: widget.isCompact,
              ),
            ),
        ],
        SizedBox(height: widget.isCompact ? 0 : 8),
      ],
    );
  }
}

class _SecondarySidebarTile extends StatefulWidget {
  final SecondarySidebarItem item;
  final bool isDark;
  final Color accentColor;
  final bool isCompact;

  const _SecondarySidebarTile({
    required this.item,
    required this.isDark,
    required this.accentColor,
    this.isCompact = false,
  });

  @override
  State<_SecondarySidebarTile> createState() => _SecondarySidebarTileState();
}

class _SecondarySidebarTileState extends State<_SecondarySidebarTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;
    final isSelected = item.isSelected;
    final accent = item.accentColor ?? widget.accentColor;

    final iconColor = isSelected || _isHovered
        ? accent
        : (isDark ? Colors.white54 : Colors.black87);

    final textColor = isSelected || _isHovered
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? Colors.white54 : Colors.black87);

    final bgColor = isSelected
        ? accent.withOpacity(0.15)
        : _isHovered
            ? accent.withOpacity(0.08)
            : Colors.transparent;

    if (widget.isCompact) {
      final tile = SidebarFinDashTile(
        isActive: isSelected,
        isDark: isDark,
        accentColor: accent,
        size: SidebarLayoutMetrics.navTileSize,
        tooltip: item.title,
        onTap: item.onTap,
        child: Icon(item.icon, color: iconColor, size: 22),
      );
      return ConditionalMouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Center(child: tile),
      );
    }

    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(0, 10, 8, 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? accent.withOpacity(0.45) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(item.icon, color: iconColor, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.trailing != null)
                item.trailing!
              else if (item.subtitle != null)
                Text(
                  item.subtitle!,
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else if (isSelected && isDark)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return ConditionalMouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: tile,
    );
  }
}
