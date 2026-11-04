import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Horizontal All | You | family persona cards with favorite star and delete.
class PersonaCardStrip extends StatelessWidget {
  const PersonaCardStrip({
    super.key,
    required this.members,
    required this.selectedId,
    required this.primaryLabel,
    required this.favoriteKey,
    required this.onSelected,
    required this.onFavorite,
    this.onDelete,
    this.compact = false,
  });

  final List<FamilyMemberRow> members;
  final String? selectedId;
  final String primaryLabel;

  /// Store key currently favorited (`__all__` / `__you__` / member id).
  final String? favoriteKey;
  final ValueChanged<String?> onSelected;
  final ValueChanged<String> onFavorite;

  /// Family-member delete; omitted when null (read-only strip).
  final ValueChanged<FamilyMemberRow>? onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _PersonaCard(
        label: 'All',
        subtitle: 'Household',
        initials: '∀',
        selected: selectedId == FavoritePersonaStore.kAll,
        favorited: favoriteKey == FavoritePersonaStore.kAll,
        compact: compact,
        onTap: () => onSelected(FavoritePersonaStore.kAll),
        onFavorite: () => onFavorite(FavoritePersonaStore.kAll),
      ),
      _PersonaCard(
        label: primaryLabel,
        subtitle: 'You',
        initials: _initials(primaryLabel),
        selected: selectedId == null,
        favorited: favoriteKey == FavoritePersonaStore.kYou,
        compact: compact,
        onTap: () => onSelected(null),
        onFavorite: () => onFavorite(FavoritePersonaStore.kYou),
      ),
      for (final m in members)
        if (m.id != null && m.id!.trim().isNotEmpty)
          _PersonaCard(
            label: m.name?.trim().isNotEmpty == true
                ? m.name!.trim()
                : 'Family member',
            subtitle: m.portfolioCount != null
                ? '${m.portfolioCount} demat'
                : 'Family',
            initials: _initials(
              m.name?.trim().isNotEmpty == true
                  ? m.name!.trim()
                  : 'Family member',
            ),
            selected: selectedId == m.id,
            favorited: favoriteKey == m.id,
            compact: compact,
            onTap: () => onSelected(m.id),
            onFavorite: () => onFavorite(m.id!),
            onDelete: onDelete == null ? null : () => onDelete!(m),
          ),
    ];

    return SizedBox(
      height: compact ? 72 : 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => SizedBox(width: compact ? 6 : 8),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }

  static String _initials(String name) {
    final n = name.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return (parts.first.length >= 2
            ? parts.first.substring(0, 2)
            : parts.first)
        .toUpperCase();
  }
}

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({
    required this.label,
    required this.subtitle,
    required this.initials,
    required this.selected,
    required this.favorited,
    required this.onTap,
    required this.onFavorite,
    this.onDelete,
    this.compact = false,
  });

  final String label;
  final String subtitle;
  final String initials;
  final bool selected;
  final bool favorited;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback? onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    final border = selected
        ? accent
        : context.colors.border.withValues(alpha: 0.45);
    final width = compact ? 118.0 : 136.0;
    final avatar = compact ? 28.0 : 34.0;

    return Material(
      color: selected
          ? accent.withValues(alpha: 0.10)
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          width: width,
          padding: EdgeInsets.fromLTRB(
            compact ? 8 : 10,
            compact ? 6 : 8,
            4,
            compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: avatar,
                height: avatar,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.16),
                ),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.label().copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 11 : 12,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption().copyWith(
                            color: context.colors.textSecondary,
                            fontSize: compact ? 10 : 11,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onFavorite,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        favorited ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: compact ? 16 : 18,
                        color: favorited
                            ? const Color(0xFFEAB308)
                            : context.colors.textSecondary,
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    InkWell(
                      onTap: onDelete,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: compact ? 15 : 16,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
