import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/subscription_cubit.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/subscription.dart';

const Map<String, String> _stripePaymentLinks = {
  'am_pro': 'https://buy.stripe.com/test_am_pro',
  'am_pro_annual': 'https://buy.stripe.com/test_am_pro_annual',
  'am_premium': 'https://buy.stripe.com/test_am_premium',
  'am_premium_annual': 'https://buy.stripe.com/test_am_premium_annual',
};

/// Compact, Bumble-style subscription paywall for mobile.
class SubscriptionMobilePaywall extends StatefulWidget {
  const SubscriptionMobilePaywall({this.onClose, super.key});

  /// Soft exit (Bumble-style). Prefer GoRouter pop/go from the host shell.
  final VoidCallback? onClose;

  @override
  State<SubscriptionMobilePaywall> createState() =>
      _SubscriptionMobilePaywallState();
}

class _SubscriptionMobilePaywallState extends State<SubscriptionMobilePaywall> {
  bool _isAnnual = true;
  /// `pro` | `premium`
  String _selectedTier = 'pro';

  static const _accent = Color(0xFFFF4458);
  static const _accentSoft = Color(0xFFFFE8EB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SubscriptionCubit>().loadPlansAndSubscription();
      }
    });
  }

  Plan? _findPlan(List<Plan> plans, String type, bool isAnnual) {
    final targetInterval = isAnnual ? 'yearly' : 'monthly';
    final matched = plans.where(
      (p) => p.code.contains(type) && p.interval == targetInterval,
    );
    if (matched.isNotEmpty) return matched.first;
    final fallback = plans.where((p) => p.code.contains(type));
    return fallback.isEmpty ? null : fallback.first;
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _handlePlanAction(
    BuildContext context,
    SubscriptionState state,
    Plan plan,
  ) {
    final subscription = (state is SubscriptionLoaded)
        ? state.subscription
        : (state is SubscriptionActionInProgress ? state.subscription : null);

    if (subscription != null && subscription.planCode == plan.code) return;

    if (plan.code != 'am_free') {
      final paymentLink = _stripePaymentLinks[plan.code];
      if (paymentLink != null) {
        final userId = subscription?.userId ?? '';
        final urlString = userId.isNotEmpty
            ? '$paymentLink?client_reference_id=$userId'
            : paymentLink;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirecting to secure payment checkout...'),
            backgroundColor: _accent,
          ),
        );
        _launchUrl(urlString);
        return;
      }
    }

    if (subscription != null) {
      context
          .read<SubscriptionCubit>()
          .upgrade(subscription.id, plan.code, plan.interval);
    } else {
      context.read<SubscriptionCubit>().subscribe(plan.code, plan.interval);
    }
  }

  int _displayMonthly(Plan plan) {
    if (plan.interval == 'monthly') return plan.amountInr;
    return (plan.amountInr / 12).round();
  }

  int _displayTotal(Plan plan) {
    if (plan.interval == 'yearly') return plan.amountInr;
    return plan.amountInr * 12;
  }

  String _formatInr(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(s[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }

  void _onClose() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1120) : const Color(0xFFFFF8F9);
    final onSurface = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final muted = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: onSurface),
          onPressed: _onClose,
        ),
        centerTitle: true,
        title: Text(
          'Subscription',
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: BlocConsumer<SubscriptionCubit, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green.shade600,
              ),
            );
            if (state.subscription.planCode.contains('premium')) {
              setState(() => _selectedTier = 'premium');
            } else if (state.subscription.planCode.contains('pro')) {
              setState(() => _selectedTier = 'pro');
            }
          } else if (state is SubscriptionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is SubscriptionLoaded && state.subscription != null) {
            final code = state.subscription!.planCode;
            if (code.contains('premium')) {
              setState(() => _selectedTier = 'premium');
            } else if (code.contains('pro')) {
              setState(() => _selectedTier = 'pro');
            }
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoading || state is SubscriptionInitial) {
            return const Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }

          List<Plan> plans = const [];
          Subscription? current;

          if (state is SubscriptionLoaded) {
            plans = state.plans;
            current = state.subscription;
          } else if (state is SubscriptionActionInProgress) {
            plans = state.plans;
            current = state.subscription;
          } else if (state is SubscriptionActionSuccess) {
            plans = state.plans;
            current = state.subscription;
          } else if (state is SubscriptionError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Couldn’t load plans',
                      style: TextStyle(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _accent),
                      onPressed: () => context
                          .read<SubscriptionCubit>()
                          .loadPlansAndSubscription(),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final proPlan = _findPlan(plans, 'pro', _isAnnual);
          final premiumPlan = _findPlan(plans, 'premium', _isAnnual);
          final selectedPlan =
              _selectedTier == 'premium' ? premiumPlan : proPlan;

          final isBusy = state is SubscriptionActionInProgress;
          final isCurrent = current != null &&
              selectedPlan != null &&
              current.planCode == selectedPlan.code;
          final hasPaid =
              current != null && !current.planCode.contains('free');

          final benefits = <String>[
            ...(selectedPlan?.features ?? const <String>[]).take(5),
          ];
          if (benefits.isEmpty) {
            benefits.addAll(const [
              'Live market data & indices',
              'Advanced portfolio analytics',
              'AI document intelligence',
              'Priority support',
            ]);
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                _accent.withValues(alpha: 0.9),
                                const Color(0xFFFF7A8A),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        hasPaid ? 'Your Premium Access' : 'Unlock more with Premium',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hasPaid
                            ? 'You’re on ${current!.planName}. Manage or switch plans below.'
                            : 'See more, move faster — analytics, live data, and AI tools in one upgrade.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: muted,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      if (hasPaid) ...[
                        const SizedBox(height: 20),
                        _CurrentPlanBanner(
                          subscription: current!,
                          isDark: isDark,
                        ),
                      ],
                      const SizedBox(height: 28),
                      _DurationChips(
                        isAnnual: _isAnnual,
                        isDark: isDark,
                        onChanged: (annual) =>
                            setState(() => _isAnnual = annual),
                      ),
                      const SizedBox(height: 20),
                      _PlanPicker(
                        isDark: isDark,
                        selectedTier: _selectedTier,
                        proPlan: proPlan,
                        premiumPlan: premiumPlan,
                        formatInr: _formatInr,
                        displayMonthly: _displayMonthly,
                        onSelect: (tier) =>
                            setState(() => _selectedTier = tier),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'What you get',
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...benefits.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? _accent.withValues(alpha: 0.2)
                                      : _accentSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: _accent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  b,
                                  style: TextStyle(
                                    color: onSurface,
                                    fontSize: 15,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cancel anytime. Secure checkout via Stripe.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _BottomCtaBar(
                isDark: isDark,
                isBusy: isBusy,
                isCurrent: isCurrent,
                selectedPlan: selectedPlan,
                isAnnual: _isAnnual,
                formatInr: _formatInr,
                displayMonthly: _displayMonthly,
                displayTotal: _displayTotal,
                onContinue: selectedPlan == null || isBusy || isCurrent
                    ? null
                    : () => _handlePlanAction(context, state, selectedPlan),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CurrentPlanBanner extends StatelessWidget {
  const _CurrentPlanBanner({
    required this.subscription,
    required this.isDark,
  });

  final Subscription subscription;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final end = subscription.currentPeriodEnd;
    final endLabel = end == null
        ? subscription.state
        : 'Renews ${end.day}/${end.month}/${end.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFFFD0D6),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFFFF4458), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.planName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  endLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationChips extends StatelessWidget {
  const _DurationChips({
    required this.isAnnual,
    required this.isDark,
    required this.onChanged,
  });

  final bool isAnnual;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: _chip(
              label: '1 month',
              selected: !isAnnual,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _chip(
              label: '12 months',
              badge: 'Save',
              selected: isAnnual,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
                color: isDark
                    ? (selected ? Colors.white : Colors.white70)
                    : (selected ? Colors.black87 : Colors.black54),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4458).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFFFF4458),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanPicker extends StatelessWidget {
  const _PlanPicker({
    required this.isDark,
    required this.selectedTier,
    required this.proPlan,
    required this.premiumPlan,
    required this.formatInr,
    required this.displayMonthly,
    required this.onSelect,
  });

  final bool isDark;
  final String selectedTier;
  final Plan? proPlan;
  final Plan? premiumPlan;
  final String Function(int) formatInr;
  final int Function(Plan) displayMonthly;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (proPlan != null)
          _PlanOption(
            title: 'Pro',
            subtitle: proPlan!.description,
            priceLabel:
                '₹${formatInr(displayMonthly(proPlan!))}/mo',
            selected: selectedTier == 'pro',
            isDark: isDark,
            popular: true,
            onTap: () => onSelect('pro'),
          ),
        if (proPlan != null && premiumPlan != null) const SizedBox(height: 10),
        if (premiumPlan != null)
          _PlanOption(
            title: 'Premium',
            subtitle: premiumPlan!.description,
            priceLabel:
                '₹${formatInr(displayMonthly(premiumPlan!))}/mo',
            selected: selectedTier == 'premium',
            isDark: isDark,
            popular: false,
            onTap: () => onSelect('premium'),
          ),
      ],
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    required this.selected,
    required this.isDark,
    required this.popular,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String priceLabel;
  final bool selected;
  final bool isDark;
  final bool popular;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                  ? const Color(0xFFFF4458).withValues(alpha: 0.12)
                  : const Color(0xFFFFE8EB))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF4458)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06)),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFFFF4458) : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFF4458)
                      : (isDark ? Colors.white38 : Colors.black26),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (popular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4458),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Popular',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              priceLabel,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCtaBar extends StatelessWidget {
  const _BottomCtaBar({
    required this.isDark,
    required this.isBusy,
    required this.isCurrent,
    required this.selectedPlan,
    required this.isAnnual,
    required this.formatInr,
    required this.displayMonthly,
    required this.displayTotal,
    required this.onContinue,
  });

  final bool isDark;
  final bool isBusy;
  final bool isCurrent;
  final Plan? selectedPlan;
  final bool isAnnual;
  final String Function(int) formatInr;
  final int Function(Plan) displayMonthly;
  final int Function(Plan) displayTotal;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final plan = selectedPlan;
    final priceLine = plan == null
        ? ''
        : isAnnual
            ? '₹${formatInr(displayTotal(plan))} billed yearly'
            : '₹${formatInr(displayMonthly(plan))} per month';

    return Material(
      elevation: 12,
      color: isDark ? const Color(0xFF121A2A) : Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (plan != null && !isCurrent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    priceLine,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4458),
                    disabledBackgroundColor: isDark
                        ? Colors.white12
                        : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  child: Text(
                    isBusy
                        ? 'Processing…'
                        : isCurrent
                            ? 'Current plan'
                            : 'Continue',
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
