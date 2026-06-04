import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/billing_toggle.dart';
import '../widgets/pricing_card.dart';
import '../cubit/subscription_cubit.dart';
import '../../domain/entities/plan.dart';

class SubscriptionPricingScreen extends StatefulWidget {
  const SubscriptionPricingScreen({super.key});

  @override
  State<SubscriptionPricingScreen> createState() => _SubscriptionPricingScreenState();
}

class _SubscriptionPricingScreenState extends State<SubscriptionPricingScreen> {
  bool _isAnnual = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SubscriptionCubit>().loadPlansAndSubscription();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    final matched = plans.where((p) => p.code.contains(type) && p.interval == targetInterval);
    if (matched.isNotEmpty) {
      return matched.first;
    }
    final fallback = plans.where((p) => p.code.contains(type));
    if (fallback.isNotEmpty) {
      return fallback.first;
    }
    return null;
  }

  void _scrollToActivePlan(String planCode) {
    int activeIndex = 0;
    if (planCode.contains('pro')) {
      activeIndex = 1;
    } else if (planCode.contains('premium')) {
      activeIndex = 2;
    } else if (planCode.contains('enterprise')) {
      activeIndex = 3;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Delay slightly to allow layout calculations to finish
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          final screenWidth = MediaQuery.of(context).size.width;
          const cardWidth = 300.0; // card width is 280 + margins (10 * 2) = 300
          
          final targetOffset = (activeIndex * cardWidth) - (screenWidth - cardWidth) / 2;
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

  void _handlePlanAction(BuildContext context, SubscriptionState state, Plan plan) {
    final subscription = (state is SubscriptionLoaded)
        ? state.subscription
        : (state is SubscriptionActionInProgress
            ? (state as SubscriptionActionInProgress).subscription
            : null);

    if (subscription != null && subscription.planCode == plan.code) {
      return;
    }

    if (subscription != null) {
      // Upgrade existing subscription
      context.read<SubscriptionCubit>().upgrade(subscription.id, plan.code, plan.interval);
    } else {
      // Create new subscription
      context.read<SubscriptionCubit>().subscribe(plan.code, plan.interval);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Pricing & Subscriptions',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
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
          } else if (state is SubscriptionLoaded && state.subscription != null) {
            _scrollToActivePlan(state.subscription!.planCode);
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoading || state is SubscriptionInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Plan> plans = [];
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
                    onPressed: () =>
                        context.read<SubscriptionCubit>().loadPlansAndSubscription(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final freePlan = _findPlan(plans, 'free', _isAnnual);
          final proPlan = _findPlan(plans, 'pro', _isAnnual);
          final premiumPlan = _findPlan(plans, 'premium', _isAnnual);

          final bool isActionInProgress = state is SubscriptionActionInProgress;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (currentSubscription != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Active Subscription: ${currentSubscription.planName}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'State: ${currentSubscription.state.toUpperCase()} • Interval: ${currentSubscription.billingInterval}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  BillingToggle(
                    isAnnual: _isAnnual,
                    onChanged: (value) => setState(() => _isAnnual = value),
                  ),
                  const SizedBox(height: 40),
                  // Lay out all 4 cards in one scrollable row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Free Card
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
                            isCurrentPlan: currentSubscription?.planCode == freePlan.code,
                          ),

                        // Pro Card
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

                        // Premium Card
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
                            isCurrentPlan: currentSubscription?.planCode == premiumPlan.code,
                          ),

                        // Enterprise Card
                        PricingCard(
                          title: 'Enterprise',
                          description: 'Custom solutions and unlimited usage for scaling teams.',
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
                            'On-premise Deployment'
                          ],
                        ),
                      ],
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
