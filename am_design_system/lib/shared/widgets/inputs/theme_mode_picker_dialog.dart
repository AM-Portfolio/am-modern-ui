import 'package:flutter/material.dart';

import '../../../core/theme/color_extensions.dart';
import '../../../core/theme/cubit/theme_cubit.dart';

/// Catalog entry for the Profile "Select Theme" picker.
class ThemeModeOption {
  const ThemeModeOption({
    required this.mode,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final AppThemeMode mode;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}

/// Default picker catalog (matches product mock labels).
List<ThemeModeOption> defaultThemeModeOptions({
  required bool includeWhiteIfSelected,
  required AppThemeMode currentMode,
}) {
  final options = <ThemeModeOption>[
    const ThemeModeOption(
      mode: AppThemeMode.system,
      title: 'System Default',
      description: 'Adaptive to device settings.',
      icon: Icons.settings_suggest_rounded,
      accent: Color(0xFF94A3B8),
    ),
    const ThemeModeOption(
      mode: AppThemeMode.light,
      title: 'Minimal Light',
      description: 'Clean, bright illumination.',
      icon: Icons.wb_sunny_rounded,
      accent: Color(0xFFFBBF24),
    ),
    const ThemeModeOption(
      mode: AppThemeMode.dark,
      title: 'Midnight OLED',
      description: 'Pure black for OLED displays.',
      icon: Icons.nightlight_round,
      accent: Color(0xFF8B5CF6),
    ),
    const ThemeModeOption(
      mode: AppThemeMode.skyBlue,
      title: 'Sky Blue Breeze',
      description: 'Fresh, calming azure tones.',
      icon: Icons.cloud_rounded,
      accent: Color(0xFF38BDF8),
    ),
    const ThemeModeOption(
      mode: AppThemeMode.imperialGold,
      title: 'Imperial Gold',
      description: 'Gin-golden champagne amber.',
      icon: Icons.workspace_premium_rounded,
      accent: Color(0xFFC9A84C),
    ),
    const ThemeModeOption(
      mode: AppThemeMode.cyberNeon,
      title: 'Cyber Neon / Rose Quartz',
      description: 'Dynamic magenta & purple fusion.',
      icon: Icons.blur_circular_rounded,
      accent: Color(0xFFE879F9),
    ),
  ];

  if (includeWhiteIfSelected && currentMode == AppThemeMode.white) {
    options.insert(
      2,
      const ThemeModeOption(
        mode: AppThemeMode.white,
        title: 'Pure White',
        description: 'Maximum brightness surfaces.',
        icon: Icons.circle_outlined,
        accent: Color(0xFFE2E8F0),
      ),
    );
  }
  return options;
}

/// Glass-style Select Theme dialog with hover highlight matching selection.
Future<void> showThemeModePickerDialog({
  required BuildContext context,
  required AppThemeMode currentMode,
  required ValueChanged<AppThemeMode> onSelected,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ThemeModePickerPanel(
          currentMode: currentMode,
          onSelected: (mode) {
            onSelected(mode);
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    },
  );
}

class ThemeModePickerPanel extends StatelessWidget {
  const ThemeModePickerPanel({
    required this.currentMode,
    required this.onSelected,
    super.key,
    this.options,
  });

  final AppThemeMode currentMode;
  final ValueChanged<AppThemeMode> onSelected;
  final List<ThemeModeOption>? options;

  @override
  Widget build(BuildContext context) {
    final catalog = options ??
        defaultThemeModeOptions(
          includeWhiteIfSelected: true,
          currentMode: currentMode,
        );
    final accent = Theme.of(context).colorScheme.primary;
    final surface = context.colors.cardSurface;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 28,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Theme',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                child: Column(
                  children: [
                    for (final option in catalog)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _ThemeOptionRow(
                          option: option,
                          selected: option.mode == currentMode,
                          liveAccent: accent,
                          onTap: () => onSelected(option.mode),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOptionRow extends StatefulWidget {
  const _ThemeOptionRow({
    required this.option,
    required this.selected,
    required this.liveAccent,
    required this.onTap,
  });

  final ThemeModeOption option;
  final bool selected;
  final Color liveAccent;
  final VoidCallback onTap;

  @override
  State<_ThemeOptionRow> createState() => _ThemeOptionRowState();
}

class _ThemeOptionRowState extends State<_ThemeOptionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.selected || _hovered;
    final switchActive = widget.liveAccent;
    final textPrimary = context.colors.textPrimary;
    final textSecondary = context.colors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: highlighted
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: switchActive.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(8, 0),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.option.accent.withValues(alpha: 0.35),
                      widget.option.accent.withValues(alpha: 0.12),
                    ],
                  ),
                  border: Border.all(
                    color: widget.option.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  widget.option.icon,
                  color: widget.option.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.option.description,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: widget.selected,
                activeThumbColor: switchActive,
                activeTrackColor: switchActive.withValues(alpha: 0.45),
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white24,
                onChanged: (_) => widget.onTap(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
