import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class EquityInsiderSectionNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final bool isMobile;
  final bool showPeers;

  const EquityInsiderSectionNavBar({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
    this.isMobile = false,
    this.showPeers = true,
  });

  static const List<String> _allSections = [
    'Overview',
    'Charts',
    'Financials',
    'Shareholding',
    'Peers',
    'News',
  ];

  List<String> get sections {
    if (showPeers) return _allSections;
    // Skip Peers; keep News last.
    return [..._allSections.sublist(0, 4), _allSections.last];
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = ModuleColors.market;
    final gap = isMobile ? 12.0 : 24.0;
    final fontSize = isMobile ? 13.0 : 15.0;
    final vPad = isMobile ? 8.0 : 12.0;

    Widget buildTabs() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(sections.length, (index) {
          final isActive = index == activeIndex;
          return Padding(
            padding: EdgeInsets.only(right: gap),
            child: InkWell(
              onTap: () => onTabSelected(index),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: vPad),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? activeColor : Colors.transparent,
                      width: isMobile ? 2.5 : 3,
                    ),
                  ),
                ),
                child: Text(
                  sections[index],
                  style: TextStyle(
                    color: isActive ? activeColor : context.colors.textSecondary,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: fontSize,
                    letterSpacing: 0.2,
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
