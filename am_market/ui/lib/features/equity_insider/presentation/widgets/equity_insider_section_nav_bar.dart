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
    final activeColor = ModuleColors.market;

    Widget buildTabs() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(sections.length, (index) {
          final isActive = index == activeIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: InkWell(
              onTap: () => onTabSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? activeColor : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  sections[index],
                  style: TextStyle(
                    color: isActive ? activeColor : context.colors.textSecondary,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        }),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colors.border,
            width: 1,
          ),
        ),
      ),
      child: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: buildTabs(),
            )
          : buildTabs(),
    );
  }
}
