import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/core/theme/cubit/theme_cubit.dart';

/// Theme toggle widget for switching between light and dark modes
class ThemeToggleWidget extends StatelessWidget {
  final bool showLabel;
  final double iconSize;
  
  const ThemeToggleWidget({
    super.key,
    this.showLabel = false,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final isDark = state.isDarkMode;
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<ThemeCubit>().toggleTheme();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: Theme.of(context).primaryColor,
                    size: iconSize,
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 8),
                    Text(
                      isDark ? 'Light' : 'Dark',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
