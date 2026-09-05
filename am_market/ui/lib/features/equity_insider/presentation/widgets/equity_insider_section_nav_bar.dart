import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class EquityInsiderSectionNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final bool isMobile;

  const EquityInsiderSectionNavBar({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
    this.isMobile = false,
  });

  static const List<String> sections = [
    'Overview',
    'Charts',
    'Financials',
    'Shareholding',
    'Peers',
  ];

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.colors.cardSurface;
    final borderColor = context.colors.border;
    final activeColor = context.colors.actionPrimaryBg;

    Widget buildTabs() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(sections.length, (index) {
          final isActive = index == activeIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: InkWell(
              onTap: () => onTabSelected(index),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? activeColor.withValues(alpha: 0.6)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  sections[index],
                  style: TextStyle(
                    color: isActive ? activeColor : context.colors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: surfaceColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: isMobile
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: buildTabs(),
                )
              : buildTabs(),
        ),
      ),
    );
  }
}
