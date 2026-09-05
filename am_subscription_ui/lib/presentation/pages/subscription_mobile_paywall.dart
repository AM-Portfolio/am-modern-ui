import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:am_library/am_library.dart';
import 'package:am_design_system/am_design_system.dart';
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

    ProductTelemetry.instance.featureAction(
      subscription != null ? 'upgrade_attempt' : 'plan_cta_click',
      planCode: plan.code,
      billingInterval: plan.interval,
      tag: 'subscription',
    );

    if (plan.code != 'am_free') {
      final paymentLink = _stripePaymentLinks[plan.code];
      if (paymentLink != null) {
        final userId = subscription?.userId ?? '';
        final urlString = userId.isNotEmpty
            ? '$paymentLink?client_reference_id=$userId'
            : paymentLink;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Redirecting to secure payment checkout...'),
            backgroundColor: context.colors.premiumActionPrimary,
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
    final bg = context.colors.scaffoldBackground;
    final onSurface = context.colors.textPrimary;
    final muted = context.colors.textSecondary;

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
          style: context.text.sectionTitle(compact: true).copyWith(
                color: onSurface,
              ),
        ),
      ),
      body: BlocConsumer<SubscriptionCubit, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: context.colors.statusSuccess,
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
                backgroundColor: context.colors.statusError,
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
            return Center(
              child: CircularProgressIndicator(color: context.colors.premiumActionPrimary),
            );
          }

          List<Plan> plans = const [];
          Subscription? current;
          final isRefreshing =
              state is SubscriptionLoaded && state.refreshing;

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
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Couldn’t load plans',
                      style: context.text.sectionTitle().copyWith(
                            color: onSurface,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMuted().copyWith(color: muted),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: context.colors.premiumActionPrimary),
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
              if (isRefreshing) const LinearProgressIndicator(minHeight: 2),
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
                                context.colors.premiumGradientStart,
                                context.colors.premiumGradientCenter,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.premiumGradientStart.withValues(alpha: 0.35),
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
                        style: context.text.heroTitle(compact: true).copyWith(
                              color: onSurface,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm + 2),
                      Text(
                        hasPaid
                            ? 'You’re on ${current!.planName}. Manage or switch plans below.'
                            : 'See more, move faster — analytics, live data, and AI tools in one upgrade.',
                        textAlign: TextAlign.center,
                        style: context.text.bodyMuted().copyWith(color: muted),
                      ),
                      if (hasPaid) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _CurrentPlanBanner(
                          subscription: current!,
                          isDark: isDark,
                          colors: context.colors,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl - 4),
                      _DurationChips(
                        isAnnual: _isAnnual,
                        isDark: isDark,
                        colors: context.colors,
                        onChanged: (annual) =>
                            setState(() => _isAnnual = annual),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _PlanPicker(
                        isDark: isDark,
                        colors: context.colors,
                        selectedTier: _selectedTier,
                        proPlan: proPlan,
                        premiumPlan: premiumPlan,
                        formatInr: _formatInr,
                        displayMonthly: _displayMonthly,
                        onSelect: (tier) =>
                            setState(() => _selectedTier = tier),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'What you get',
                        style: context.text.sectionTitle(compact: true).copyWith(
                              color: onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...benefits.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: context.colors.premiumActionPrimary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  b,
                                  style: TextStyle(
                                    color: onSurface,
                                    fontSize: 13,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
                colors: context.colors,
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
    required this.colors,
  });

  final Subscription subscription;
  final bool isDark;
  final AppColorsTheme colors;

  @override
  Widget build(BuildContext context) {
    final end = subscription.currentPeriodEnd;
    final endLabel = end == null
        ? subscription.state
        : 'Renews ${end.day}/${end.month}/${end.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: colors.premiumActionPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded,
              color: colors.premiumActionPrimary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: subscription.planName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: colors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' · $endLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    required this.colors,
    required this.onChanged,
  });

  final bool isAnnual;
  final bool isDark;
  final AppColorsTheme colors;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.cardSurface,
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
    final colors = this.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? Colors.white.withValues(alpha: 0.12) : colors.surface)
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
                color: selected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.premiumActionPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: colors.premiumActionPrimary,
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
    required this.colors,
    required this.selectedTier,
    required this.proPlan,
    required this.premiumPlan,
    required this.formatInr,
    required this.displayMonthly,
    required this.onSelect,
  });

  final bool isDark;
  final AppColorsTheme colors;
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
            colors: colors,
            popular: true,
            onTap: () => onSelect('pro'),
          ),
        if (proPlan != null && premiumPlan != null) const SizedBox(height: 8),
        if (premiumPlan != null)
          _PlanOption(
            title: 'Premium',
            subtitle: premiumPlan!.description,
            priceLabel:
                '₹${formatInr(displayMonthly(premiumPlan!))}/mo',
            selected: selectedTier == 'premium',
            isDark: isDark,
            colors: colors,
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
    required this.colors,
    required this.popular,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String priceLabel;
  final bool selected;
  final bool isDark;
  final AppColorsTheme colors;
  final bool popular;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.premiumActionPrimary.withValues(alpha: 0.12)
              : colors.cardSurface,
          borderRadius: AppRadii.card,
          border: Border.all(
            color: selected
                ? colors.premiumActionPrimary
                : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    selected ? colors.premiumActionPrimary : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? colors.premiumActionPrimary
                      : colors.border,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
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
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (popular) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.premiumActionPrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Popular',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              priceLabel,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: colors.textPrimary,
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
    required this.colors,
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
  final AppColorsTheme colors;
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
      color: colors.surface,
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
                      color: colors.textSecondary,
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
                    backgroundColor: colors.premiumActionPrimary,
                    disabledBackgroundColor: colors.divider,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadii.chip,
                    ),
                    textStyle: context.text.button(compact: true),
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
