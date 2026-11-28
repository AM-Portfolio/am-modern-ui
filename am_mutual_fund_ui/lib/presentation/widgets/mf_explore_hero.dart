import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../data/mf_scheme_view.dart';

/// Explore hero: title, search field, popular AMC chips.
class MfExploreHero extends StatelessWidget {
  const MfExploreHero({
    required this.controller,
    required this.query,
    required this.accent,
    required this.onSubmitted,
    required this.onClear,
    required this.onChipTap,
    this.searchFocusNode,
    super.key,
  });

  final TextEditingController controller;
  final String query;
  final Color accent;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final ValueChanged<String> onChipTap;
  final FocusNode? searchFocusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: context.text.heroTitle().copyWith(color: context.textPrimary),
            children: [
              const TextSpan(text: 'Invest in '),
              TextSpan(
                text: 'Mutual Funds',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'EOD NAV (as-of), not live LTP. Search → filter → invest / SIP.',
          style: context.text.caption().copyWith(
                color: context.textSecondary,
                height: 1.35,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: controller,
          focusNode: searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search by fund name, AMC, or ISIN',
            isDense: true,
            filled: true,
            fillColor: context.surfaceColor,
            prefixIcon: Icon(Icons.search, color: context.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: onClear,
                  ),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: onSubmitted,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Text(
              'Popular',
              style: context.text.caption().copyWith(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final chip in exploreAmcSearchChips)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AmToggleChip(
                          label: chip,
                          selected: query.toLowerCase() == chip.toLowerCase(),
                          compact: true,
                          accentColor: accent,
                          onTap: () => onChipTap(chip),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
