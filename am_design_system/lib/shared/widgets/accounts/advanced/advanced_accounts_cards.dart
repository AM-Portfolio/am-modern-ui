import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/color_extensions.dart';
import 'advanced_account_row.dart';

String advancedAccountTileLetter(AdvancedAccountRow account) {
  if (account.displayBroker != '—') {
    return account.displayBroker[0].toUpperCase();
  }
  final title = account.displayTitle.trim();
  if (title.isNotEmpty) return title[0].toUpperCase();
  return '?';
}

/// Card grid layout for [AdvancedAccountsTemplate] — horizontal density.
class AdvancedAccountsCards extends StatelessWidget {
  const AdvancedAccountsCards({
    required this.accounts,
    required this.isDarkChrome,
    required this.accent,
    super.key,
    this.onRowTap,
  });

  final List<AdvancedAccountRow> accounts;
  final bool isDarkChrome;
  final Color accent;
  final ValueChanged<AdvancedAccountRow>? onRowTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const maxCardWidth = 360.0;
        final usable = constraints.maxWidth - 24;
        var crossAxisCount = (usable / (maxCardWidth + spacing)).floor();
        if (crossAxisCount < 1) crossAxisCount = 1;

        if (crossAxisCount == 1) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: spacing),
            itemBuilder: (context, i) => _Card(
              account: accounts[i],
              isDarkChrome: isDarkChrome,
              accent: accent,
              onRowTap: onRowTap,
            ),
          );
        }

        final cardWidth =
            (usable - spacing * (crossAxisCount - 1)) / crossAxisCount;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: 100,
          ),
          itemCount: accounts.length,
          itemBuilder: (context, i) => SizedBox(
            width: cardWidth,
            child: _Card(
              account: accounts[i],
              isDarkChrome: isDarkChrome,
              accent: accent,
              onRowTap: onRowTap,
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.account,
    required this.isDarkChrome,
    required this.accent,
    this.onRowTap,
  });

  final AdvancedAccountRow account;
  final bool isDarkChrome;
  final Color accent;
  final ValueChanged<AdvancedAccountRow>? onRowTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final muted = context.textSecondary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final statusDot = switch (account.statusKind) {
      AccountStatusKind.active => context.statusSuccess,
      AccountStatusKind.inactive => context.textTertiary,
      AccountStatusKind.frozen => context.statusWarning,
      AccountStatusKind.unknown => muted,
    };
    final brokerTint =
        AdvancedAccountRow.brokerTint(account.broker, accent);
    final mutedValue = account.isInactive || !account.hasValue;
    final glowAlpha = mutedValue ? 0.06 : 0.14;
    final showStatus = account.statusKind != AccountStatusKind.unknown;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRowTap != null ? () => onRowTap!(account) : null,
        borderRadius: AppRadii.card,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardSurface,
            borderRadius: AppRadii.card,
            border: Border.all(color: theme.border),
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.centerLeft,
              colors: [
                brokerTint.withValues(alpha: glowAlpha),
                theme.cardSurface.withValues(alpha: 0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: context.shadow(isDarkChrome ? 0.35 : 0.08),
                blurRadius: isDarkChrome ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: brokerTint.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      advancedAccountTileLetter(account),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: brokerTint,
                      ),
                    ),
                  ),
                  if (showStatus) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardSurface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.border.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            account.displayStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        account.displayType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: onSurface,
                      ),
                    ),
                    if (account.displaySubtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        account.displaySubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: theme.border.withValues(alpha: 0.7),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    account.displayValue,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: mutedValue ? muted : onSurface,
                    ),
                  ),
                  if (account.displayWeightPct.isNotEmpty)
                    Text(
                      account.displayWeightPct,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: muted,
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
