import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../basket_navigation.dart';
import '../../shared/basket_panel_styles.dart';
import 'discover_view_mode.dart';

export 'discover_view_mode.dart';

/// Discover / My Baskets segmented control (portfolio sticky header + explorer).
class BasketModeToggle extends StatelessWidget {
  const BasketModeToggle({
    super.key,
    this.compact = true,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BasketViewMode>(
      valueListenable: BasketNavigation.viewMode,
      builder: (context, mode, _) {
        return Theme(
          data: BasketPanelStyles.accentTheme(context),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? AppSpacing.md : 0,
              compact ? 0 : 0,
              compact ? AppSpacing.md : 0,
              compact ? 4 : 0,
            ),
            child: SizedBox(
              width: compact ? double.infinity : null,
              child: SegmentedButton<BasketViewMode>(
                segments: const [
                  ButtonSegment(
                    value: BasketViewMode.discover,
                    label: Text('Discover'),
                  ),
                  ButtonSegment(
                    value: BasketViewMode.myBaskets,
                    label: Text('My Baskets'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (Set<BasketViewMode> next) {
                  BasketNavigation.setViewMode(next.first);
                },
                showSelectedIcon: false,
              ),
            ),
          ),
        );
      },
    );
  }
}
