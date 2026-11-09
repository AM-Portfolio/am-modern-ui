import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    this.householdTotalValue,
    this.householdXirrPct,
    this.householdAccountCount = 0,
    this.primaryTotalValue,
    this.primaryXirrPct,
    this.primaryAccountCount = 0,
    this.memberAccountCounts = const {},
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

  /// Metrics for the All / Household card (from hub stats).
  final double? householdTotalValue;
  final double? householdXirrPct;
  final int householdAccountCount;

  /// Metrics for the You card (from hub stats).
  final double? primaryTotalValue;
  final double? primaryXirrPct;
  final int primaryAccountCount;

  /// Valued account counts keyed by family member id.
  final Map<String, int> memberAccountCounts;

  static final _currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _PersonaCard(
        label: 'All',
        accountCountLabel: _countLabel(householdAccountCount),
        initials: '∀',
        balance: householdTotalValue,
        xirrPct: householdXirrPct,
        selected: selectedId == FavoritePersonaStore.kAll,
        favorited: favoriteKey == FavoritePersonaStore.kAll,
        compact: compact,
        onTap: () => onSelected(FavoritePersonaStore.kAll),
        onFavorite: () => onFavorite(FavoritePersonaStore.kAll),
      ),
      _PersonaCard(
        label: primaryLabel,
        accountCountLabel: _countLabel(primaryAccountCount),
        initials: _initials(primaryLabel),
        balance: primaryTotalValue,
        xirrPct: primaryXirrPct,
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
            accountCountLabel: _countLabel(memberAccountCounts[m.id!] ?? 0),
            initials: _initials(
              m.name?.trim().isNotEmpty == true
                  ? m.name!.trim()
                  : 'Family member',
            ),
            balance: m.totalValue,
            xirrPct: m.xirrPct,
            selected: selectedId == m.id,
            favorited: favoriteKey == m.id,
            compact: compact,
            onTap: () => onSelected(m.id),
            onFavorite: () => onFavorite(m.id!),
            onDelete: onDelete == null ? null : () => onDelete!(m),
          ),
    ];

    return SizedBox(
      height: compact ? 72 : 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => SizedBox(width: compact ? 6 : 8),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }

  static String _countLabel(int count) {
    if (count <= 0) return '0 accounts';
    if (count == 1) return '1 account';
    return '$count accounts';
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

  static String formatBalance(double? value) {
    if (value == null) return '—';
    return _currency.format(value);
  }

  static String formatXirr(double? pct) {
    if (pct == null) return '—';
    final sign = pct > 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }
}

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({
    required this.label,
    required this.accountCountLabel,
    required this.initials,
    required this.selected,
    required this.favorited,
    required this.onTap,
    required this.onFavorite,
    this.balance,
    this.xirrPct,
    this.onDelete,
    this.compact = false,
  });

  final String label;
  final String accountCountLabel;
  final String initials;
  final double? balance;
  final double? xirrPct;
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
    final width = compact ? 260.0 : 292.0;
    final avatar = compact ? 26.0 : 30.0;
    final starColor = favorited
        ? context.colors.statusWarning
        : context.colors.textSecondary;

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
            compact ? 6 : 8,
            compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: avatar,
                height: avatar,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: accent.withValues(alpha: 0.16),
                ),
                child: Text(
                  initials,
                  style: context.text.caption().copyWith(
                        fontSize: compact ? 9 : 10,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: label,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.label().copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: compact ? 11 : 12,
                              height: 1.1,
                            ),
                      ),
                    ),
                    Text(
                      accountCountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption().copyWith(
                            color: context.colors.textSecondary,
                            fontSize: compact ? 9 : 10,
                            height: 1.1,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          PersonaCardStrip.formatBalance(balance),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.label().copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: compact ? 12 : 13,
                                height: 1.1,
                              ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: onFavorite,
                            customBorder: const CircleBorder(),
                            child: Icon(
                              favorited
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: compact ? 15 : 16,
                              color: starColor,
                            ),
                          ),
                          if (onDelete != null)
                            InkWell(
                              onTap: onDelete,
                              customBorder: const CircleBorder(),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: compact ? 14 : 15,
                                color: context.colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _XirrTrendPill(xirrPct: xirrPct, compact: compact),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XirrTrendPill extends StatelessWidget {
  const _XirrTrendPill({
    required this.xirrPct,
    this.compact = false,
  });

  final double? xirrPct;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.textSecondary;
    final positive = xirrPct != null && xirrPct! > 0;
    final Color color;
    final IconData icon;
    if (xirrPct == null) {
      color = muted;
      icon = Icons.remove_rounded;
    } else if (positive) {
      color = context.colors.statusSuccess;
      icon = Icons.north_east_rounded;
    } else {
      color = context.colors.statusError;
      icon = Icons.south_east_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 11, color: color),
          const SizedBox(width: 3),
          Text(
            'XIRR ${PersonaCardStrip.formatXirr(xirrPct)}',
            style: context.text.caption().copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 9 : 10,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
