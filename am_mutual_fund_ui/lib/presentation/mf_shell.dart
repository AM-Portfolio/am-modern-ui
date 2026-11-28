import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'widgets/mf_nav_config.dart';

/// Host layout for Mutual Funds — peer chrome via [UnifiedSidebarScaffold].
class MfShell extends StatelessWidget {
  const MfShell({required this.child, super.key});

  final Widget child;

  SecondarySidebarItem _item(
    BuildContext context, {
    required MfNavDest dest,
    required String selectedId,
    required Color accent,
  }) {
    return SecondarySidebarItem(
      title: dest.label,
      shortTitle: dest.shortLabel,
      icon: dest.icon,
      isSelected: selectedId == dest.id,
      accentColor: accent,
      onTap: () {
        if (GoRouterState.of(context).uri.path != dest.path) {
          context.go(dest.path);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedId = mfSelectedDestId(path);
    final accent = ModuleColors.mutualFund;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    VoidCallback? onThemeToggle;
    try {
      final cubit = context.read<ThemeCubit>();
      onThemeToggle = () => cubit.toggleTheme();
    } catch (_) {
      onThemeToggle = null;
    }

    return ModuleColorProvider(
      module: ModuleType.mutualFund,
      child: UnifiedSidebarScaffold(
        module: ModuleType.mutualFund,
        title: null,
        subtitle: null,
        accentColor: accent,
        isDark: isDark,
        showModuleBottomNavigation: false,
        onThemeToggle: onThemeToggle,
        onBackToGlobal: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/app');
          }
        },
        sections: [
          SecondarySidebarSection(
            title: 'Browse',
            items: [
              for (final d in mfBrowseDests)
                _item(
                  context,
                  dest: d,
                  selectedId: selectedId,
                  accent: accent,
                ),
            ],
          ),
          SecondarySidebarSection(
            title: 'Account',
            items: [
              for (final d in mfAccountDests)
                _item(
                  context,
                  dest: d,
                  selectedId: selectedId,
                  accent: accent,
                ),
            ],
          ),
        ],
        body: child,
      ),
    );
  }
}
