
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_glassmorphism_v2.dart';
import 'package:am_design_system/core/theme/app_glassmorphism.dart';
import 'package:am_design_system/core/utils/conditional_mouse_region.dart';





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
/// Supports both a structured list of [items]/[sections] or a custom [child] widget.
/// Includes responsive modes: Compact (Icon-only), Condensed, and Full.
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
    this.width = 280,
    this.accentColor = const Color(0xFF6C5DD3), // Default Purple
    this.icon = Icons.analytics_rounded,
    this.showDividers = false,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: width,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveWidth = constraints.maxWidth.isInfinite ? width : constraints.maxWidth;
          
          final isCompact = effectiveWidth < 100;
          final isCondensed = effectiveWidth >= 100 && effectiveWidth < 200;
          final isFull = effectiveWidth >= 200;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF1a1a2e),
                        const Color(0xFF16213e),
                        const Color(0xFF0f1419),
                      ]
                    : [
                        const Color(0xFFF8F9FA),
                        const Color(0xFFE9ECEF),
                        const Color(0xFFDEE2E6),
                      ],
              ),
            ),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.05),
                              Colors.white.withValues(alpha: 0.02),
                            ]
                          : [
                              Colors.black.withValues(alpha: 0.02),
                              Colors.black.withValues(alpha: 0.01),
                            ],
                    ),
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeader(context, isFull, isCondensed, isCompact, isDark),
                    
                    if (showDividers)
                      Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),

                    // Content Section
                    // Content Section
                    Builder(
                      builder: (context) {
                        final hasBoundedHeight = constraints.maxHeight.isFinite;
                        final listWidget = child ?? (sections != null 
                            ? _buildSectionsList(context, isFull, isCondensed, isCompact, isDark, shrinkWrap: !hasBoundedHeight)
                            : _buildItemsList(context, items!, isFull, isCondensed, isCompact, isDark, shrinkWrap: !hasBoundedHeight));
                        
                        if (hasBoundedHeight) {
                          return Expanded(child: listWidget);
                        }
                        return listWidget;
                      },
                    ),

                    // Footer Section (Visible in Full and Condensed modes)
                    if (footer != null && !isCompact)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: footer!,
                      ),
                  ],
                ),
              ),
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isFull, bool isCondensed, bool isCompact, bool isDark) {
    if (header != null) return header!;

    // Default Premium Header
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: AppGlassmorphismV2.iconGlassContainer(
              color: accentColor,
              isDark: isDark,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
        ),
      );
    }

    final colors = [accentColor, accentColor.withOpacity(0.5)];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomPaint(
        painter: isDark ? GradientBorderPainter(
          colors: colors,
          borderWidth: 2.0,
          borderRadius: 16,
        ) : null,
        child: Container(
          padding: EdgeInsets.all(isFull ? 16 : 12),
          decoration: AppGlassmorphismV2.gradientBorderCard(
            borderColors: colors,
            borderRadius: 16,
            isDark: isDark,
          ),
          child: Row(
            mainAxisAlignment: isFull ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, color: accentColor, size: 24),
              if (!isCompact) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title ?? 'Menu',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<SecondarySidebarItem> itemList, bool isFull, bool isCondensed, bool isCompact, bool isDark, {bool shrinkWrap = false}) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const ClampingScrollPhysics() : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: itemList.length,
      separatorBuilder: (context, index) => SizedBox(height: showDividers ? 0 : 8),
      itemBuilder: (context, index) {
        final item = itemList[index];
        return _SecondarySidebarTile(
          item: item,
          isFull: isFull,
          isCondensed: isCondensed,
          isCompact: isCompact,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildSectionsList(BuildContext context, bool isFull, bool isCondensed, bool isCompact, bool isDark, {bool shrinkWrap = false}) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const ClampingScrollPhysics() : null,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sections!.length,
      itemBuilder: (context, index) {
        final section = sections![index];
        return _SecondarySidebarSectionWidget(
          section: section,
          isFull: isFull,
          isCondensed: isCondensed,
          isCompact: isCompact,
          isDark: isDark,
          accentColor: accentColor,
        );
      },
    );
  }
}

class _SecondarySidebarSectionWidget extends StatefulWidget {
  final SecondarySidebarSection section;
  final bool isFull;
  final bool isCondensed;
  final bool isCompact;
  final bool isDark;
  final Color accentColor;

  const _SecondarySidebarSectionWidget({
    required this.section,
    required this.isFull,
    required this.isCondensed,
    required this.isCompact,
    required this.isDark,
    required this.accentColor,
  });

  @override
  State<_SecondarySidebarSectionWidget> createState() => _SecondarySidebarSectionWidgetState();
}

class _SecondarySidebarSectionWidgetState extends State<_SecondarySidebarSectionWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.section.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return Column(
        children: [
          if (widget.section.customWidget != null)
            widget.section.customWidget!,
          if (widget.section.items != null)
            ...widget.section.items!.map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: _SecondarySidebarTile(
                item: item,
                isFull: widget.isFull,
                isCondensed: widget.isCondensed,
                isCompact: widget.isCompact,
                isDark: widget.isDark,
              ),
            )),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  if (widget.section.icon != null) ...[
                    Icon(widget.section.icon, color: widget.accentColor.withOpacity(0.5), size: 16),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      widget.section.title,
                      style: TextStyle(
                        color: widget.isDark ? Colors.white.withOpacity(0.4) : Colors.black45,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  if (!widget.isCompact)
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white.withOpacity(0.3),
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Section Items or Custom Widget
        if (_isExpanded) ...[
          if (widget.section.customWidget != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: widget.section.customWidget!,
            ),
          if (widget.section.items != null)
            ...widget.section.items!.map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _SecondarySidebarTile(
                item: item,
                isFull: widget.isFull,
                isCondensed: widget.isCondensed,
                isCompact: widget.isCompact,
                isDark: widget.isDark,
              ),
            )),
        ],
      ],
    );
  }
}

class _SecondarySidebarTile extends StatefulWidget {
  final SecondarySidebarItem item;
  final bool isFull;
  final bool isCondensed;
  final bool isCompact;
  final bool isDark;

  const _SecondarySidebarTile({
    required this.item,
    required this.isFull,
    required this.isCondensed,
    required this.isCompact,
    required this.isDark,
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
    
    // Determine colors
    final colors = AppGlassmorphismV2.colorSchemes[item.colorScheme ?? 'primary']!;
    final color = item.accentColor ?? colors[0];
    
    return ConditionalMouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.transparent, // Handled by manual hover logic
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale((_isHovered && !isSelected) ? 1.02 : 1.0),
            child: CustomPaint(
              painter: (isSelected || _isHovered)
                  ? GradientBorderPainter(
                      colors: [color, color.withOpacity(0.5)],
                      borderWidth: isSelected ? 2.0 : 1.5,
                      borderRadius: 12,
                    )
                  : null,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isFull ? 16 : 8,
                  vertical: 12,
                ),
                decoration: isSelected
                    ? AppGlassmorphismV2.finDashActiveItem(
                        accentColor: color,
                        isDark: isDark,
                      )
                    : AppGlassmorphismV2.finDashInactiveItem(isDark: isDark),
                child: Row(
                mainAxisAlignment: widget.isFull ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: AppGlassmorphismV2.iconGlassContainer(
                      color: (!isDark || isSelected || _isHovered) ? color : Colors.transparent,
                      isDark: isDark,
                    ),
                    child: Icon(
                      item.icon,
                      color: (!isDark || isSelected || _isHovered) ? color : (isDark ? Colors.white70 : Colors.black54),
                      size: 18,
                    ),
                  ),
                  if (!widget.isCompact) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: (!isDark || isSelected || _isHovered) 
                                ? (isDark ? Colors.white : Colors.black) 
                                : (isDark ? Colors.white70 : Colors.black54),
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.subtitle != null && widget.isFull)
                            Text(
                              item.subtitle!,
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (item.trailing != null && widget.isFull) item.trailing!,
                    if (isSelected && isDark)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
