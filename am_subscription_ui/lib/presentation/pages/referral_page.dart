import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../data/datasources/subscription_remote_datasource.dart';
import '../../domain/entities/referral.dart';

/// Pro days credited to the referrer per successful invite.
const int kReferralRewardDaysPerInvite = 14;

/// Marketing ceiling: 12 × 14 ≈ 168 days ≈ “up to 6 months”.
const int kReferralMaxMonthsAdvertised = 6;

int _daysEarned(int qualifiedCount) =>
    qualifiedCount * kReferralRewardDaysPerInvite;

int _daysPossible(int lifetimeCap) =>
    lifetimeCap * kReferralRewardDaysPerInvite;

/// Rough month label for day counts (30-day months for UX copy).
String _monthsLabel(int days) {
  if (days <= 0) return '0 months';
  final months = days / 30.0;
  if (months >= kReferralMaxMonthsAdvertised - 0.2) {
    return 'up to $kReferralMaxMonthsAdvertised months';
  }
  if (months < 1) {
    return '$days days';
  }
  final rounded = months.round();
  return rounded == 1 ? '1 month' : '$rounded months';
}

/// Full-screen Referral experience (opened from Profile like Subscription).
class ReferralPage extends StatefulWidget {
  const ReferralPage({this.onClose, super.key});

  final VoidCallback? onClose;

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
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
          _error = 'Referral is unavailable right now.';
        });
        return;
      }
      final ds = GetIt.instance<SubscriptionRemoteDataSource>();
      final summary = await ds.getReferralSummary();
      final history = await ds.getReferralHistory(limit: 30);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _history = history;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load referral details. Pull to retry.';
      });
    }
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label copied — share it to stack toward '
          '$kReferralMaxMonthsAdvertised months Pro',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, colors),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: ModuleColors.portfolio,
                child: _buildBody(context, colors, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppColorsTheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: _close,
            icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          ),
          Expanded(
            child: Text(
              'Referral',
              style: context.text.sectionTitle().copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (!_loading)
            IconButton(
              tooltip: 'Refresh',
              onPressed: _load,
              icon: Icon(Icons.refresh_rounded, color: colors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppColorsTheme colors,
    bool isDark,
  ) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null || _summary == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.card_giftcard_outlined,
            size: 48,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _error ?? 'Referral unavailable',
            textAlign: TextAlign.center,
            style: context.text.body().copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(
                backgroundColor: ModuleColors.portfolio,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    final s = _summary!;
    final progress = () {
      final maxDays = _daysPossible(s.lifetimeCap);
      if (maxDays <= 0) return 0.0;
      return (_daysEarned(s.qualifiedCount) / maxDays).clamp(0.0, 1.0);
    }();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final horizontal = wide ? 48.0 : AppSpacing.lg;
        final maxWidth = wide ? 720.0 : double.infinity;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(summary: s, progress: progress, isDark: isDark),
                    const SizedBox(height: AppSpacing.xl),
                    _InviteCodeCard(
                      summary: s,
                      isDark: isDark,
                      onCopyCode: () => _copy('Code', s.code),
                      onCopyLink: () => _copy('Invite link', s.shareUrl),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _HowItWorksCard(lifetimeCap: s.lifetimeCap, isDark: isDark),
                    if (_history.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _HistorySection(history: _history, isDark: isDark),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatefulWidget {
  const _HeroCard({
    required this.summary,
    required this.progress,
    required this.isDark,
  });

  final ReferralSummary summary;
  final double progress;
  final bool isDark;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  int? _selectedMilestone;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _onMilestoneTap(int months, String tip) {
    setState(() => _selectedMilestone = months);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tip),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final summary = widget.summary;
    final earnedDays = _daysEarned(summary.qualifiedCount);
    final maxDays = _daysPossible(summary.lifetimeCap);
    final earnedMonthsApprox = (earnedDays / 30.0).clamp(0.0, 6.0);
    final remainingInvites = summary.remaining;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.dialog,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.premiumGradientStart,
            colors.premiumGradientCenter,
            colors.premiumGradientEnd,
          ],
        ),
        border: Border.all(
          color: colors.premiumActionPrimary.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: ModuleColors.portfolio.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_pulse.value);
                  return Transform.scale(
                    scale: 1 + (t * 0.04),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.premiumActionPrimary.withValues(alpha: 0.16),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: ModuleColors.portfolio,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get up to $kReferralMaxMonthsAdvertised months Pro free',
                      style: context.text.sectionTitle().copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invite friends · ${kReferralRewardDaysPerInvite} days Pro each · '
                      'max ${summary.lifetimeCap} invites ≈ $kReferralMaxMonthsAdvertised months. '
                      'They also get 1 month Pro free.',
                      style: context.text.bodyMuted().copyWith(
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'You earned',
                  value: earnedDays == 0
                      ? '0 days'
                      : '$earnedDays days',
                  hint: earnedDays == 0
                      ? 'Start inviting'
                      : '~${_monthsLabel(earnedDays)}',
                  isDark: widget.isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Toward goal',
                  value: '$kReferralMaxMonthsAdvertised mo',
                  hint: '${summary.qualifiedCount}/${summary.lifetimeCap} invites',
                  isDark: widget.isDark,
                  emphasize: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Still open',
                  value: '$remainingInvites',
                  hint: remainingInvites == 1 ? 'invite left' : 'invites left',
                  isDark: widget.isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Pro runway',
                  style: context.text.body().copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                earnedDays > 0
                    ? '$earnedDays / $maxDays days'
                    : 'Tap milestones ↓',
                style: context.text.bodyMuted().copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MilestoneTrack(
            progress: widget.progress,
            earnedMonthsApprox: earnedMonthsApprox,
            selectedMonths: _selectedMilestone,
            isDark: widget.isDark,
            onTap: _onMilestoneTap,
            remainingToSixMonths: () {
              final needDays =
                  (kReferralMaxMonthsAdvertised * 30) - earnedDays;
              if (needDays <= 0) {
                return 'You are at the full ~$kReferralMaxMonthsAdvertised months reward.';
              }
              final invitesNeeded =
                  (needDays / kReferralRewardDaysPerInvite).ceil();
              return 'About $invitesNeeded more successful invite'
                  '${invitesNeeded == 1 ? '' : 's'} to reach ~$kReferralMaxMonthsAdvertised months.';
            }(),
          ),
          if (summary.dailyCap > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Today: ${summary.dailyUsed}/${summary.dailyCap} invites used',
              style: context.text.caption().copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.hint,
    required this.isDark,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final String hint;
  final bool isDark;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: AppRadii.button,
        color: emphasize
            ? ModuleColors.portfolio.withValues(alpha: isDark ? 0.22 : 0.12)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04)),
        border: Border.all(
          color: emphasize
              ? ModuleColors.portfolio.withValues(alpha: 0.45)
              : colors.border.withValues(alpha: isDark ? 0.35 : 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.text.caption().copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.body().copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.caption().copyWith(
              color: emphasize
                  ? ModuleColors.portfolio
                  : colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneTrack extends StatelessWidget {
  const _MilestoneTrack({
    required this.progress,
    required this.earnedMonthsApprox,
    required this.selectedMonths,
    required this.isDark,
    required this.onTap,
    required this.remainingToSixMonths,
  });

  final double progress;
  final double earnedMonthsApprox;
  final int? selectedMonths;
  final bool isDark;
  final void Function(int months, String tip) onTap;
  final String remainingToSixMonths;

  static const _milestones = [1, 3, 6];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trackBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: trackBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 12,
                      width: w * value,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [
                            ModuleColors.portfolio.withValues(alpha: 0.75),
                            ModuleColors.portfolio,
                          ],
                        ),
                      ),
                    ),
                    for (final m in _milestones)
                      Positioned(
                        left: (w * (m / kReferralMaxMonthsAdvertised))
                                .clamp(10.0, w - 10) -
                            10,
                        top: -4,
                        child: _MilestoneDot(
                          months: m,
                          reached: earnedMonthsApprox + 0.05 >= m,
                          selected: selectedMonths == m,
                          onTap: () {
                            final tips = {
                              1: '1 month ≈ ${30 ~/ kReferralRewardDaysPerInvite} successful invites '
                                  '(${kReferralRewardDaysPerInvite} days each).',
                              3: '3 months ≈ ${(90 / kReferralRewardDaysPerInvite).ceil()} invites — keep sharing!',
                              6: remainingToSixMonths,
                            };
                            onTap(m, tips[m]!);
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < _milestones.length; i++) ...[
              if (i > 0) const Spacer(),
              GestureDetector(
                onTap: () {
                  final m = _milestones[i];
                  final tips = {
                    1: 'Hit ~1 month of Pro with a few successful invites.',
                    3: 'Halfway vibe — ~3 months Pro from referrals.',
                    6: remainingToSixMonths,
                  };
                  onTap(m, tips[m]!);
                },
                child: Text(
                  '${_milestones[i]} mo',
                  style: context.text.caption().copyWith(
                    color: selectedMonths == _milestones[i]
                        ? ModuleColors.portfolio
                        : colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MilestoneDot extends StatelessWidget {
  const _MilestoneDot({
    required this.months,
    required this.reached,
    required this.selected,
    required this.onTap,
  });

  final int months;
  final bool reached;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? ModuleColors.portfolio : Colors.transparent,
            border: Border.all(
              color: selected || reached
                  ? ModuleColors.portfolio
                  : Colors.white.withValues(alpha: 0.35),
              width: selected ? 3 : 2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: ModuleColors.portfolio.withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: reached
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({
    required this.summary,
    required this.isDark,
    required this.onCopyCode,
    required this.onCopyLink,
  });

  final ReferralSummary summary;
  final bool isDark;
  final VoidCallback onCopyCode;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: AppRadii.dialog,
        border: Border.all(
          color: colors.border.withValues(alpha: isDark ? 0.35 : 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR INVITE CODE',
            style: context.text.caption().copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Share once — unlock up to $kReferralMaxMonthsAdvertised months Pro',
            style: context.text.bodyMuted().copyWith(
              color: colors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: AppRadii.button,
              color: isDark
                  ? Colors.black.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.85),
              border: Border.all(
                color: ModuleColors.portfolio.withValues(alpha: 0.28),
              ),
            ),
            child: SelectableText(
              summary.code,
              textAlign: TextAlign.center,
              style: context.text.sectionTitle().copyWith(
                color: colors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopyCode,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadii.button,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCopyLink,
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Copy link'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ModuleColors.portfolio,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadii.button,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (summary.shareUrl.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              summary.shareUrl,
              style: context.text.caption().copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({
    required this.lifetimeCap,
    required this.isDark,
  });

  final int lifetimeCap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final steps = [
      (
        Icons.share_outlined,
        'Share your code',
        'Send your invite link or code to friends who are new to Asrax.',
      ),
      (
        Icons.workspace_premium_outlined,
        'They get Pro free',
        'Successful invites unlock 1 month of Pro for your friend.',
      ),
      (
        Icons.auto_awesome_outlined,
        'You stack Pro days',
        'Earn $kReferralRewardDaysPerInvite days Pro per invite — up to '
            '$lifetimeCap invites ≈ $kReferralMaxMonthsAdvertised months free.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: AppRadii.dialog,
        border: Border.all(
          color: colors.border.withValues(alpha: isDark ? 0.35 : 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW IT WORKS',
            style: context.text.caption().copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ModuleColors.portfolio.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    steps[i].$1,
                    size: 18,
                    color: ModuleColors.portfolio,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i].$2,
                        style: context.text.body().copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        steps[i].$3,
                        style: context.text.bodyMuted().copyWith(
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.history,
    required this.isDark,
  });

  final List<ReferralHistoryItem> history;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT INVITES',
          style: context.text.caption().copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: AppRadii.dialog,
            border: Border.all(
              color: colors.border.withValues(alpha: isDark ? 0.35 : 0.6),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < history.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: colors.border.withValues(alpha: 0.5),
                  ),
                _HistoryRow(item: history[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final ReferralHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final when = item.qualifiedAt ?? item.createdAt;
    final dateLabel = when == null
        ? '—'
        : '${when.toLocal().year}-'
            '${when.toLocal().month.toString().padLeft(2, '0')}-'
            '${when.toLocal().day.toString().padLeft(2, '0')}';
    final status = item.status.trim().isEmpty ? 'pending' : item.status.trim();
    final statusColor = _statusColor(status, colors);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: context.text.body().copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.codeHint != null && item.codeHint!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Code · ${item.codeHint}',
                    style: context.text.caption().copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: statusColor.withValues(alpha: 0.14),
            ),
            child: Text(
              status,
              style: context.text.caption().copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status, AppColorsTheme colors) {
    final s = status.toLowerCase();
    if (s.contains('qualif') || s.contains('success') || s == 'active') {
      return colors.statusSuccess;
    }
    if (s.contains('reject') || s.contains('fail') || s.contains('cancel')) {
      return colors.statusError;
    }
    return colors.textSecondary;
  }
}
