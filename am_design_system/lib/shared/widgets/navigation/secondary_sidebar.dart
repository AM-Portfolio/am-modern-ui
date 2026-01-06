
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_glassmorphism_v2.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
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
    
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
        border: Border(
           right: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section (Workspace / Title)
          _buildHeader(context, isDark),
          
          if (showDividers)
            Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),

          // Scrollable Content
          Expanded(
            child: child ?? (sections != null 
                ? _buildSectionsList(context, isDark)
                : _buildItemsList(context, items!, isDark)),
          ),

          // Footer Section (New Trade Button)
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: footer!,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    if (header != null) return header!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor, // Brand color background
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
          ),
          const SizedBox(width: 12),
          
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title?.toUpperCase() ?? 'WORKSPACE',
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

          // Trailing Settings/Filter Icon
          Icon(
            Icons.tune_rounded,
            color: isDark ? Colors.white24 : Colors.black26,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<SecondarySidebarItem> itemList, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: itemList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        return _SecondarySidebarTile(
          item: itemList[index],
          isDark: isDark,
          accentColor: accentColor,
        );
      },
    );
  }

  Widget _buildSectionsList(BuildContext context, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sections!.length,
      itemBuilder: (context, index) {
        final section = sections![index];
        return _SecondarySidebarSectionWidget(
          section: section,
          isDark: isDark,
          accentColor: accentColor,
        );
      },
    );
  }
}

class _SecondarySidebarSectionWidget extends StatefulWidget {
  final SecondarySidebarSection section;
  final bool isDark;
  final Color accentColor;

  const _SecondarySidebarSectionWidget({
    required this.section,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (Title + Collapser)
        if (widget.section.title.isNotEmpty)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  if (widget.section.items != null) // Only show arrow if expandable items exist
                    AnimatedRotation(
                      turns: _isExpanded ? 0 : -0.25, // 0 is down, -0.25 is right
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

        // Section Items or Custom Widget
        if (_isExpanded || widget.section.title.isEmpty) ...[ // Always show if no title (e.g. top section)
          if (widget.section.customWidget != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: widget.section.customWidget!,
            ),
          if (widget.section.items != null)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.section.items!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (_, index) => _SecondarySidebarTile(
                item: widget.section.items![index],
                isDark: widget.isDark,
                accentColor: widget.accentColor,
              ),
            ),
        ],
        const SizedBox(height: 8), 
      ],
    );
  }
}

class _SecondarySidebarTile extends StatefulWidget {
  final SecondarySidebarItem item;
  final bool isDark;
  final Color accentColor;

  const _SecondarySidebarTile({
    required this.item,
    required this.isDark,
    required this.accentColor,
  });

  @override
  State<_SecondarySidebarTile> createState() => _SecondarySidebarTileState();
}

class _SecondarySidebarTileState extends State<_SecondarySidebarTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;    // Determine colors
    final isSelected = item.isSelected;
    
    // Icon Color: Accent if selected or hovered
    final iconColor = isSelected || _isHovered
        ? (widget.item.accentColor ?? widget.accentColor)
        : (isDark ? Colors.white54 : Colors.black87);

    // Text Color: White if selected/hovered (or black in light mode), grey otherwise
    final textColor = isSelected || _isHovered
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? Colors.white54 : Colors.black87);
    
    // Background Color: Accent opacity if selected/hovered
    final bgColor = isSelected 
        ? (widget.item.accentColor ?? widget.accentColor).withOpacity(0.15)
        : _isHovered 
            ? (widget.item.accentColor ?? widget.accentColor).withOpacity(0.08)
            : Colors.transparent;

    return ConditionalMouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.transparent, // Placeholder for potential border
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: iconColor,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.trailing != null) 
                  item.trailing!
                else if (item.subtitle != null) // e.g. "Coming Soon" badge
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (isSelected && isDark) // Optional selection dot
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: item.accentColor ?? widget.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
