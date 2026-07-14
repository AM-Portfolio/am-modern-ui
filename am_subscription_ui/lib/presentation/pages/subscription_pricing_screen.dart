import 'package:flutter/material.dart';

import 'subscription_mobile_paywall.dart';
import 'subscription_web_pricing_screen.dart';

/// Entry point for subscription UI.
///
/// - **Mobile** (&lt; 900px): compact Bumble-style paywall
/// - **Web / wide**: classic multi-card pricing page
class SubscriptionPricingScreen extends StatelessWidget {
  const SubscriptionPricingScreen({this.onClose, super.key});

  final VoidCallback? onClose;

  static const double _webBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isWebLayout = width >= _webBreakpoint;

        if (isWebLayout) {
          return SubscriptionWebPricingScreen(onClose: onClose);
        }
        return SubscriptionMobilePaywall(onClose: onClose);
      },
    );
  }
}
