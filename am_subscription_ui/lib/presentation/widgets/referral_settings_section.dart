import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../data/datasources/subscription_remote_datasource.dart';
import '../../domain/entities/referral.dart';

/// Settings → Referral panel (inject into Profile Account section).
class ReferralSettingsSection extends StatefulWidget {
  const ReferralSettingsSection({super.key});

  @override
  State<ReferralSettingsSection> createState() =>
      _ReferralSettingsSectionState();
}

class _ReferralSettingsSectionState extends State<ReferralSettingsSection> {
  bool _loading = true;
  String? _error;
  ReferralSummary? _summary;
  List<ReferralHistoryItem> _history = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!GetIt.instance.isRegistered<SubscriptionRemoteDataSource>()) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Referral unavailable';
        });
        return;
      }
      final ds = GetIt.instance<SubscriptionRemoteDataSource>();
      final summary = await ds.getReferralSummary();
      final history = await ds.getReferralHistory(limit: 20);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _history = history;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load referral details';
      });
    }
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.card_giftcard_outlined, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Loading referral…',
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null || _summary == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.card_giftcard_outlined, color: colors.textSecondary),
        title: Text('Referral', style: TextStyle(color: colors.textPrimary)),
        subtitle: Text(
          _error ?? 'Unavailable',
          style: TextStyle(color: colors.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _load,
        ),
      );
    }

    final s = _summary!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.card_giftcard_outlined, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Referral',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.qualifiedCount} of ${s.lifetimeCap} successful · '
                    '${s.remaining} left',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your invite code',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      s.code,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _copy('Code', s.code),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                s.shareUrl,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _copy('Invite link', s.shareUrl),
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Copy link'),
                ),
              ),
              Text(
                'Friends get 1 month Pro free. You get 14 days Pro per '
                'successful invite (max ${s.lifetimeCap}, fair-use limits apply).',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (_history.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Recent invites',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._history.take(8).map((item) {
            final when = item.qualifiedAt ?? item.createdAt;
            final dateLabel = when == null
                ? '—'
                : '${when.toUtc().year}-'
                    '${when.toUtc().month.toString().padLeft(2, '0')}-'
                    '${when.toUtc().day.toString().padLeft(2, '0')}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    item.status,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
