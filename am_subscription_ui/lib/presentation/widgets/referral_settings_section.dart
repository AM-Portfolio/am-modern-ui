import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../data/datasources/subscription_remote_datasource.dart';

/// Compact Profile Account row — opens Referral via [onOpen].
///
/// Prefer Profile's native tile + [onOpenReferral] when wiring from the shell.
class ReferralSettingsSection extends StatefulWidget {
  const ReferralSettingsSection({
    required this.onOpen,
    super.key,
  });

  final VoidCallback onOpen;

  @override
  State<ReferralSettingsSection> createState() =>
      _ReferralSettingsSectionState();
}

class _ReferralSettingsSectionState extends State<ReferralSettingsSection> {
  String _subtitle = 'Up to 6 months Pro free';

  @override
  void initState() {
    super.initState();
    _loadSubtitle();
  }

  Future<void> _loadSubtitle() async {
    try {
      if (!GetIt.instance.isRegistered<SubscriptionRemoteDataSource>()) {
        return;
      }
      final summary =
          await GetIt.instance<SubscriptionRemoteDataSource>().getReferralSummary();
      if (!mounted) return;
      final days = summary.qualifiedCount * 14;
      setState(() {
        _subtitle = days > 0
            ? '$days days Pro earned · ${summary.remaining} invites left'
            : 'Up to 6 months Pro · ${summary.remaining} invites left';
      });
    } catch (_) {
      // Keep default invite copy if API fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                color: context.colors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Referral',
                      style: context.text.body().copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: context.text.caption().copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
