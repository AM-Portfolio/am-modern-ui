import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_extensions.dart';
import 'advanced_account_row.dart';

/// Card grid layout for [AdvancedAccountsTemplate].
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
        const maxCardWidth = 360.0;
        final narrow = constraints.maxWidth < 720;
        final spacing = narrow ? AppSpacing.sm : 12.0;
        final usable = constraints.maxWidth - 24;
        var crossAxisCount = (usable / (maxCardWidth + spacing)).floor();
        if (crossAxisCount < 1) crossAxisCount = 1;
        final cardWidth =
            (usable - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            12,
            narrow ? AppSpacing.sm : 12,
            12,
            narrow ? AppSpacing.sm : 16,
          ),
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
    final nomineeLabel = account.displayNominee;
    final showNomineeChip = !account.nomineeMissing &&
        nomineeLabel != '—' &&
        nomineeLabel != 'No nominee';
    final nomineeColor = context.statusSuccess;
    final statusDot = switch (account.statusKind) {
      AccountStatusKind.active => context.statusSuccess,
      AccountStatusKind.inactive => context.textTertiary,
      AccountStatusKind.frozen => context.statusWarning,
      AccountStatusKind.unknown => muted,
    };

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
                color: context.shadow(isDarkChrome ? 0.28 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Band 1: type + status | value + weight
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            account.displayType,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            account.displayStatus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        account.displayValue,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
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
                            height: 1.2,
                            color: muted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Band 2: title + subtitle
              Text(
                account.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: accent.withValues(alpha: 0.95),
                ),
              ),
              if (account.displaySubtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  account.displaySubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, height: 1.2, color: muted),
                ),
              ],
              // Band 3: named nominee only
              if (showNomineeChip) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: nomineeColor.withValues(alpha: 0.7),
                      ),
                      color: nomineeColor.withValues(alpha: 0.08),
                    ),
                    child: Text(
                      nomineeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: nomineeColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
