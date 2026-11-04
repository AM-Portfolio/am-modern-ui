import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_extensions.dart';
import 'advanced_account_row.dart';

/// Card grid layout for [AdvancedAccountsTemplate] — mock density.
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
        const spacing = 16.0;
        const maxCardWidth = 360.0;
        final usable = constraints.maxWidth - 24;
        var crossAxisCount = (usable / (maxCardWidth + spacing)).floor();
        if (crossAxisCount < 1) crossAxisCount = 1;
        final cardWidth =
            (usable - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: SizedBox(
            width: constraints.maxWidth,
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var i = 0; i < accounts.length; i++)
                  SizedBox(
                    width: cardWidth,
                    child: _Card(
                      account: accounts[i],
                      index: i,
                      isDarkChrome: isDarkChrome,
                      accent: accent,
                      onRowTap: onRowTap,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.account,
    required this.index,
    required this.isDarkChrome,
    required this.accent,
    this.onRowTap,
  });

  final AdvancedAccountRow account;
  final int index;
  final bool isDarkChrome;
  final Color accent;
  final ValueChanged<AdvancedAccountRow>? onRowTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final muted = context.textSecondary;
    final missing =
        account.nomineeMissing || account.displayNominee == 'No nominee';
    final nomineeColor =
        missing ? context.statusError : context.statusSuccess;
    final statusDot = switch (account.statusKind) {
      AccountStatusKind.active => context.statusSuccess,
      AccountStatusKind.inactive => context.textTertiary,
      AccountStatusKind.frozen => context.statusWarning,
      AccountStatusKind.unknown => muted,
    };
    final brokerTint =
        AdvancedAccountRow.brokerTint(account.broker, accent);

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
            boxShadow: [
              BoxShadow(
                color: context.shadow(isDarkChrome ? 0.35 : 0.08),
                blurRadius: isDarkChrome ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      account.displayType,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        account.displayValue,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: account.isInactive
                              ? muted
                              : Theme.of(context).colorScheme.onSurface,
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                account.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent.withValues(alpha: 0.95),
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
              const SizedBox(height: 6),
              Row(
                children: [
                  if (account.displayBroker != '—') ...[
                    Container(
                      width: 14,
                      height: 14,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: brokerTint.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        account.displayBroker[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: brokerTint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        account.displayBroker,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (account.showNomineeBadge ||
                      account.displayNominee != '—')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: nomineeColor.withValues(alpha: 0.7),
                        ),
                        color: nomineeColor.withValues(alpha: 0.08),
                      ),
                      child: Text(
                        account.displayNominee,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: nomineeColor,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusDot,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        account.displayStatus,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
