import 'dart:ui' as ui;

import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Horizontal All | You | family persona cards.
///
/// Shows **2.5 cards** in the viewport so the next card peeks, and scrolls
/// horizontally on both mobile and web.
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
    this.onAddFamily,
    this.compact = false,
    this.showRoleIcon = true,
    this.sizeToContent = false,
    this.householdTotalValue,
    this.householdXirrPct,
    this.householdAccountCount = 0,
    this.primaryTotalValue,
    this.primaryXirrPct,
    this.primaryAccountCount = 0,
    this.memberAccountCounts = const {},
  });

  /// How many cards fit in the viewport (fractional peek of the next card).
  static const double visibleCards = 2.5;

  final List<FamilyMemberRow> members;
  final String? selectedId;
  final String primaryLabel;

  /// Store key currently favorited (`__all__` / `__you__` / member id).
  final String? favoriteKey;
  final ValueChanged<String?> onSelected;
  final ValueChanged<String> onFavorite;

  /// Family-member delete; omitted when null (read-only strip).
  final ValueChanged<FamilyMemberRow>? onDelete;

  /// Opens add-family when the filler card is tapped.
  final VoidCallback? onAddFamily;
  final bool compact;

  /// When false (dashboard hub), hide the leading role icon so the name can breathe.
  final bool showRoleIcon;

  /// When true (dashboard hub), card width follows the persona name length.
  final bool sizeToContent;

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

  static String _countLabel(int count) {
    if (count <= 0) return '0 accounts';
    if (count == 1) return '1 account';
    return '$count accounts';
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

  /// Card width from measured name / account-count text (hub density mode).
  static double widthForLabel({
    required String label,
    required String accountCountLabel,
    required bool showRoleIcon,
    required bool compact,
    required bool hasDelete,
  }) {
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: ui.TextDirection.ltr,
      )..layout();
      return painter.width;
    }

    final nameStyle = TextStyle(
      fontSize: compact ? 10 : 12,
      fontWeight: FontWeight.w700,
      height: 1.1,
    );
    final countStyle = TextStyle(
      fontSize: compact ? 8 : 10,
      height: 1.1,
    );
    final identityW = [
      measure(label, nameStyle),
      measure(accountCountLabel, countStyle),
    ].reduce((a, b) => a > b ? a : b);
    final iconW = showRoleIcon ? (compact ? 30.0 : 36.0) : 0.0;
    final metricsW = compact ? 88.0 : 104.0;
    final actionsW = hasDelete ? 26.0 : 26.0;
    final pad = compact ? 18.0 : 26.0;
    final gaps = compact ? 16.0 : 22.0;
    return (pad + iconW + identityW + gaps + metricsW + actionsW)
        .clamp(compact ? 140.0 : 160.0, 320.0);
  }

  List<({Widget child, double width})> _buildEntries({
    required double equalWidth,
  }) {
    ({Widget child, double width}) entry({
      required String label,
      required String accountCountLabel,
      required _PersonaRole role,
      required double? balance,
      required double? xirrPct,
      required bool selected,
      required bool favorited,
      required VoidCallback onTap,
      required VoidCallback onFavorite,
      VoidCallback? onDelete,
    }) {
      final width = sizeToContent
          ? widthForLabel(
              label: label,
              accountCountLabel: accountCountLabel,
              showRoleIcon: showRoleIcon,
              compact: compact,
              hasDelete: onDelete != null,
            )
          : equalWidth;
      return (
        width: width,
        child: _PersonaCard(
          width: width,
          label: label,
          accountCountLabel: accountCountLabel,
          role: role,
          balance: balance,
          xirrPct: xirrPct,
          selected: selected,
          favorited: favorited,
          compact: compact,
          showRoleIcon: showRoleIcon,
          sizeToContent: sizeToContent,
          onTap: onTap,
          onFavorite: onFavorite,
          onDelete: onDelete,
        ),
      );
    }

    final cards = <({Widget child, double width})>[
      entry(
        label: 'All',
        accountCountLabel: _countLabel(householdAccountCount),
        role: _PersonaRole.all,
        balance: householdTotalValue,
        xirrPct: householdXirrPct,
        selected: selectedId == FavoritePersonaStore.kAll,
        favorited: favoriteKey == FavoritePersonaStore.kAll,
        onTap: () => onSelected(FavoritePersonaStore.kAll),
        onFavorite: () => onFavorite(FavoritePersonaStore.kAll),
      ),
      entry(
        label: primaryLabel,
        accountCountLabel: _countLabel(primaryAccountCount),
        role: _PersonaRole.primary,
        balance: primaryTotalValue,
        xirrPct: primaryXirrPct,
        selected: selectedId == null,
        favorited: favoriteKey == FavoritePersonaStore.kYou,
        onTap: () => onSelected(null),
        onFavorite: () => onFavorite(FavoritePersonaStore.kYou),
      ),
      for (final m in members)
        if (m.id != null && m.id!.trim().isNotEmpty)
          entry(
            label: m.name?.trim().isNotEmpty == true
                ? m.name!.trim()
                : 'Family member',
            accountCountLabel: _countLabel(memberAccountCounts[m.id!] ?? 0),
            role: _PersonaRole.member,
            balance: m.totalValue,
            xirrPct: m.xirrPct,
            selected: selectedId == m.id,
            favorited: favoriteKey == m.id,
            onTap: () => onSelected(m.id),
            onFavorite: () => onFavorite(m.id!),
            onDelete: onDelete == null ? null : () => onDelete!(m),
          ),
    ];

    while (cards.length < 3) {
      final addWidth = sizeToContent
          ? widthForLabel(
              label: 'Add family',
              accountCountLabel: ' ',
              showRoleIcon: true,
              compact: compact,
              hasDelete: false,
            )
          : equalWidth;
      cards.add((
        width: addWidth,
        child: _AddFamilyCard(
          width: addWidth,
          compact: compact,
          enabled: onAddFamily != null,
          onTap: onAddFamily,
        ),
      ));
    }
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 6.0 : 8.0;
    final stripHeight = compact ? 96.0 : 86.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 360.0;
        // Two gaps sit between the three card slots that make up 2.5 visible.
        final equalWidth =
            ((maxW - gap * 2) / visibleCards).clamp(96.0, 320.0);
        final cards = _buildEntries(equalWidth: equalWidth);
        final cacheHint = cards.isEmpty ? equalWidth : cards.first.width;

        return SizedBox(
          height: stripHeight,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: ListView.separated(
              key: const Key('persona-card-strip-scroll'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: cards.length,
              separatorBuilder: (_, __) => SizedBox(width: gap),
              itemBuilder: (context, index) {
                final entry = cards[index];
                return SizedBox(width: entry.width, child: entry.child);
              },
              cacheExtent: cacheHint * 2,
              primary: false,
              keyboardDismissBehavior: kIsWeb
                  ? ScrollViewKeyboardDismissBehavior.onDrag
                  : ScrollViewKeyboardDismissBehavior.manual,
            ),
          ),
        );
      },
    );
  }
}

enum _PersonaRole { all, primary, member }

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({
    required this.width,
    required this.label,
    required this.accountCountLabel,
    required this.role,
    required this.selected,
    required this.favorited,
    required this.onTap,
    required this.onFavorite,
    this.balance,
    this.xirrPct,
    this.onDelete,
    this.compact = false,
    this.showRoleIcon = true,
    this.sizeToContent = false,
  });

  final double width;
  final String label;
  final String accountCountLabel;
  final _PersonaRole role;
  final double? balance;
  final double? xirrPct;
  final bool selected;
  final bool favorited;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback? onDelete;
  final bool compact;
  final bool showRoleIcon;
  final bool sizeToContent;

  IconData get _roleIcon {
    switch (role) {
      case _PersonaRole.all:
        return Icons.layers_rounded;
      case _PersonaRole.primary:
        return Icons.groups_rounded;
      case _PersonaRole.member:
        return Icons.work_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    final colors = context.colors;
    final border = selected
        ? accent.withValues(alpha: 0.85)
        : colors.border.withValues(alpha: 0.4);
    final iconColor = selected ? accent : colors.textSecondary;
    final avatar = compact ? 24.0 : 28.0;
    final gap = compact ? 4.0 : 6.0;
    final starColor = favorited
        ? colors.statusWarning
        : colors.textSecondary;

    final avatarWidget = Container(
      width: avatar,
      height: avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? accent.withValues(alpha: 0.1)
            : colors.border.withValues(alpha: 0.12),
      ),
      child: Icon(
        _roleIcon,
        size: compact ? 13 : 15,
        color: iconColor,
      ),
    );

    final nameStyle = context.text.label().copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          fontSize: compact ? 10 : 12,
          height: 1.1,
          color: selected ? accent : null,
        );
    final countStyle = context.text.caption().copyWith(
          color: context.colors.textSecondary,
          fontSize: compact ? 8 : 10,
          height: 1.1,
        );
    final identityChild = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Tooltip(
          message: label,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: nameStyle,
          ),
        ),
        Text(
          accountCountLabel,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: countStyle,
        ),
      ],
    );
    // Always flex identity so a slightly-tight width never overflows metrics/actions.
    final identity = Expanded(child: identityChild);

    final divider = Container(
      width: 1,
      height: compact ? 28 : 34,
      margin: EdgeInsets.symmetric(horizontal: gap),
      color: colors.border.withValues(alpha: 0.35),
    );

    final metricsChild = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            PersonaCardStrip.formatBalance(balance),
            maxLines: 1,
            textAlign: TextAlign.right,
            style: context.text.label().copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 11 : 13,
                  height: 1.1,
                ),
          ),
        ),
        const SizedBox(height: 2),
        _XirrTrendPill(xirrPct: xirrPct, compact: compact),
      ],
    );
    final metrics = sizeToContent
        ? SizedBox(
            width: compact ? 78 : 92,
            child: metricsChild,
          )
        : Flexible(child: metricsChild);

    final actions = SizedBox(
      width: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              onPressed: onFavorite,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              icon: Icon(
                favorited ? Icons.star_rounded : Icons.star_outline_rounded,
                size: compact ? 16 : 17,
                color: starColor,
              ),
              tooltip: favorited ? 'Unfavorite' : 'Favorite',
            ),
          ),
          if (onDelete != null)
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints.tightFor(width: 24, height: 24),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: compact ? 15 : 16,
                  color: context.colors.textSecondary,
                ),
                tooltip: 'Delete',
              ),
            ),
        ],
      ),
    );

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          width: width,
          padding: EdgeInsets.fromLTRB(
            compact ? 6 : 8,
            compact ? 6 : 8,
            compact ? 4 : 6,
            compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.06 : 0.03),
                blurRadius: selected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showRoleIcon) ...[
                avatarWidget,
                SizedBox(width: gap),
              ],
              identity,
              divider,
              metrics,
              SizedBox(width: compact ? 2 : 4),
              actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _AddFamilyCard extends StatelessWidget {
  const _AddFamilyCard({
    required this.width,
    required this.compact,
    required this.enabled,
    this.onTap,
  });

  final double width;
  final bool compact;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    final muted = context.colors.textSecondary;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          width: width,
          padding: EdgeInsets.all(compact ? 8 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: context.colors.border.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 26 : 30,
                height: compact ? 26 : 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.border.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  size: compact ? 14 : 16,
                  color: enabled ? accent : muted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add family',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.label().copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 11 : 12,
                        color: enabled ? muted : muted.withValues(alpha: 0.7),
                      ),
                ),
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

    final label = compact
        ? PersonaCardStrip.formatXirr(xirrPct)
        : 'XIRR ${PersonaCardStrip.formatXirr(xirrPct)}';

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 10 : 11, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: context.text.caption().copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 9 : 10,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
