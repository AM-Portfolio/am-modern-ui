import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/billing_toggle.dart';
import '../widgets/pricing_card.dart';
import '../cubit/subscription_cubit.dart';
import '../../domain/entities/plan.dart';

const Map<String, String> _stripePaymentLinks = {
  'am_pro': 'https://buy.stripe.com/test_am_pro',
  'am_pro_annual': 'https://buy.stripe.com/test_am_pro_annual',
  'am_premium': 'https://buy.stripe.com/test_am_premium',
  'am_premium_annual': 'https://buy.stripe.com/test_am_premium_annual',
};

/// Classic multi-card pricing layout used on web / wide screens.
class SubscriptionWebPricingScreen extends StatefulWidget {
  const SubscriptionWebPricingScreen({this.onClose, super.key});

  final VoidCallback? onClose;

  @override
  State<SubscriptionWebPricingScreen> createState() =>
      _SubscriptionWebPricingScreenState();
}

class _SubscriptionWebPricingScreenState
    extends State<SubscriptionWebPricingScreen> {
  bool _isAnnual = true;
  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SubscriptionCubit>().loadPlansAndSubscription();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Plan? _findPlan(List<Plan> plans, String type, bool isAnnual) {
    if (type == 'free') {
      return plans.firstWhere(
        (p) => p.code == 'am_free',
        orElse: () => plans.firstWhere(
          (p) => p.code.contains('free'),
          orElse: () => plans.first,
        ),
      );
    }
    final targetInterval = isAnnual ? 'yearly' : 'monthly';
    final matched = plans.where(
      (p) => p.code.contains(type) && p.interval == targetInterval,
    );
    if (matched.isNotEmpty) return matched.first;
    final fallback = plans.where((p) => p.code.contains(type));
    if (fallback.isNotEmpty) return fallback.first;
    return null;
  }

  void _scrollToActivePlan(String planCode) {
    var activeIndex = 0;
    if (planCode.contains('pro')) {
      activeIndex = 1;
    } else if (planCode.contains('premium')) {
      activeIndex = 2;
    } else if (planCode.contains('enterprise')) {
      activeIndex = 3;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        final screenWidth = MediaQuery.of(context).size.width;
        final isNarrow = screenWidth < 768;

        if (isNarrow) {
          if (_pageController.hasClients) {
            setState(() => _currentPage = activeIndex);
            _pageController.animateToPage(
              activeIndex,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
            );
          }
        } else if (_scrollController.hasClients) {
          const cardWidth = 300.0;
          final targetOffset =
              (activeIndex * cardWidth) - (screenWidth - cardWidth) / 2;
          final maxScroll = _scrollController.position.maxScrollExtent;
          _scrollController.animateTo(
            targetOffset.clamp(0.0, maxScroll),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    });
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
        : (state is SubscriptionActionInProgress
            ? state.subscription
            : null);

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
            backgroundColor: Color(0xFF1B64F2),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Pricing & Subscriptions',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        centerTitle: true,
        leading: widget.onClose == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: widget.onClose,
              ),
      ),
      body: BlocConsumer<SubscriptionCubit, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            _scrollToActivePlan(state.subscription.planCode);
          } else if (state is SubscriptionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is SubscriptionLoaded &&
              state.subscription != null) {
            _scrollToActivePlan(state.subscription!.planCode);
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoading || state is SubscriptionInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          var plans = <Plan>[];
          dynamic currentSubscription;

          if (state is SubscriptionLoaded) {
            plans = state.plans;
            currentSubscription = state.subscription;
          } else if (state is SubscriptionActionInProgress) {
            plans = state.plans;
            currentSubscription = state.subscription;
          } else if (state is SubscriptionActionSuccess) {
            plans = state.plans;
            currentSubscription = state.subscription;
          } else if (state is SubscriptionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading plans: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<SubscriptionCubit>()
                        .loadPlansAndSubscription(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (plans.isEmpty) {
            return const Center(child: Text('No plans available'));
          }

          final freePlan = _findPlan(plans, 'free', _isAnnual);
          final proPlan = _findPlan(plans, 'pro', _isAnnual);
          final premiumPlan = _findPlan(plans, 'premium', _isAnnual);

          final isActionInProgress = state is SubscriptionActionInProgress;
          final screenWidth = MediaQuery.of(context).size.width;
          final isNarrow = screenWidth < 1100;

          final cards = <Widget>[
            if (freePlan != null)
              PricingCard(
                title: freePlan.name,
                description: freePlan.description,
                monthlyPrice: freePlan.amountInr,
                annualPrice: freePlan.amountInr,
                isAnnual: _isAnnual,
                ctaText: currentSubscription?.planCode == freePlan.code
                    ? 'Current Plan'
                    : 'Get Started',
                onCtaPressed: (isActionInProgress ||
                        currentSubscription?.planCode == freePlan.code)
                    ? null
                    : () => _handlePlanAction(context, state, freePlan),
                primaryColor: Colors.grey.shade400,
                features: freePlan.features,
                isCurrentPlan:
                    currentSubscription?.planCode == freePlan.code,
              ),
            if (proPlan != null)
              PricingCard(
                title: 'Pro',
                description: proPlan.description,
                monthlyPrice: proPlan.interval == 'monthly'
                    ? proPlan.amountInr
                    : (proPlan.amountInr / 12).round(),
                annualPrice: proPlan.interval == 'yearly'
                    ? proPlan.amountInr
                    : proPlan.amountInr * 12,
                isAnnual: _isAnnual,
                ctaText: currentSubscription?.planCode == proPlan.code
                    ? 'Current Plan'
                    : (isActionInProgress ? 'Processing...' : 'Upgrade to Pro'),
                onCtaPressed: (isActionInProgress ||
                        currentSubscription?.planCode == proPlan.code)
                    ? null
                    : () => _handlePlanAction(context, state, proPlan),
                primaryColor: const Color(0xFF1B64F2),
                isPopular: true,
                features: proPlan.features,
                isCurrentPlan: currentSubscription?.planCode == proPlan.code,
              ),
            if (premiumPlan != null)
              PricingCard(
                title: 'Premium',
                description: premiumPlan.description,
                monthlyPrice: premiumPlan.interval == 'monthly'
                    ? premiumPlan.amountInr
                    : (premiumPlan.amountInr / 12).round(),
                annualPrice: premiumPlan.interval == 'yearly'
                    ? premiumPlan.amountInr
                    : premiumPlan.amountInr * 12,
                isAnnual: _isAnnual,
                ctaText: currentSubscription?.planCode == premiumPlan.code
                    ? 'Current Plan'
                    : (isActionInProgress ? 'Processing...' : 'Get Premium'),
                onCtaPressed: (isActionInProgress ||
                        currentSubscription?.planCode == premiumPlan.code)
                    ? null
                    : () => _handlePlanAction(context, state, premiumPlan),
                primaryColor: const Color(0xFFA824EE),
                features: premiumPlan.features,
                isCurrentPlan:
                    currentSubscription?.planCode == premiumPlan.code,
              ),
            PricingCard(
              title: 'Enterprise',
              description:
                  'Custom solutions and unlimited usage for scaling teams.',
              monthlyPrice: 0,
              annualPrice: 0,
              isAnnual: _isAnnual,
              ctaText: 'Contact Sales',
              onCtaPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact sales triggered!')),
                );
              },
              primaryColor: const Color(0xFFE87C00),
              isCustom: true,
              features: const [
                'Unlimited Portfolios & Analytics',
                'Unlimited AI Document Parsing',
                'Enterprise Custom AI Agents',
                'Dedicated Account Manager',
                'Custom API Access',
                'White-label Reports',
                'Advanced Team Permissions',
                'Priority 24/7 Support',
                'On-premise Deployment',
              ],
            ),
          ];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BillingToggle(
                    isAnnual: _isAnnual,
                    onChanged: (value) => setState(() => _isAnnual = value),
                  ),
                  const SizedBox(height: 40),
                  if (isNarrow) ...[
                    SizedBox(
                      height: 600,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        children: cards,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        cards.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? theme.colorScheme.primary
                                : (isDark ? Colors.white30 : Colors.black12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: screenWidth - 32,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: cards,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
