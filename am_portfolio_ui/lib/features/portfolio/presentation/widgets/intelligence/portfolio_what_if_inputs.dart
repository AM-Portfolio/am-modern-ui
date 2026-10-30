import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import 'intelligence_glass_card.dart';

/// Horizontal quick-pick chip matching Add shortcuts chrome.
class WhatIfShortcutChip extends StatelessWidget {
  const WhatIfShortcutChip({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.subtitleColor,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.button,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: AppRadii.button,
          border: Border.all(
            color: selected
                ? ModuleColors.portfolio
                : context.colors.border.withValues(alpha: 0.6),
            width: selected ? 1.4 : 1,
          ),
          color: selected
              ? ModuleColors.portfolio.withValues(alpha: 0.12)
              : context.colors.cardSurface.withValues(alpha: 0.35),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? ModuleColors.portfolio
                        : context.colors.textPrimary,
                  ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: subtitleColor ?? context.colors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Labeled preset chips + numeric field (Amount / weight / move %).
class WhatIfPresetFieldBlock extends StatelessWidget {
  const WhatIfPresetFieldBlock({
    required this.label,
    required this.presets,
    required this.selectedPreset,
    required this.onPreset,
    required this.controller,
    required this.focusNode,
    required this.scrollPadding,
    required this.hint,
    required this.onFieldChanged,
    this.onCleared,
    super.key,
  });

  final String label;
  final List<(String, double)> presets;
  final double? selectedPreset;
  final ValueChanged<double> onPreset;
  final TextEditingController controller;
  final FocusNode focusNode;
  final EdgeInsets scrollPadding;
  final String hint;
  final ValueChanged<String> onFieldChanged;
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final preset in presets) ...[
                AmToggleChip(
                  label: preset.$1,
                  selected: selectedPreset == preset.$2,
                  compact: true,
                  accentColor: ModuleColors.portfolio,
                  borderRadius: AppRadii.button,
                  onTap: () => onPreset(preset.$2),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              scrollPadding: scrollPadding,
              onChanged: onFieldChanged,
              decoration: intelligenceFieldDecoration(
                context,
                label: label,
                hint: hint,
                compact: true,
              ).copyWith(
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 16,
                          color: context.colors.textTertiary,
                        ),
                        onPressed: () {
                          controller.clear();
                          onCleared?.call();
                        },
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Horizontal list of [WhatIfShortcutChip]s; returns shrink if [children] empty.
class WhatIfShortcutStrip extends StatelessWidget {
  const WhatIfShortcutStrip({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => children[i],
      ),
    );
  }
}
