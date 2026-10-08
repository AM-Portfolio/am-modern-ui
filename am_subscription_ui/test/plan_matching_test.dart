import 'package:flutter_test/flutter_test.dart';
import 'package:am_subscription_ui/domain/entities/subscription.dart';
import 'package:am_subscription_ui/domain/plan_matching.dart';

void main() {
  group('planTierFromCode', () {
    test('detects free / pro / premium', () {
      expect(planTierFromCode('am_free'), PlanTier.free);
      expect(planTierFromCode('am_pro'), PlanTier.pro);
      expect(planTierFromCode('am_pro_annual'), PlanTier.pro);
      expect(planTierFromCode('am_premium'), PlanTier.premium);
      expect(planTierFromCode('am_premium_annual'), PlanTier.premium);
    });
  });

  group('isCurrentPlanType', () {
    test('monthly Pro matches Pro card while annual toggle selected', () {
      expect(isCurrentPlanType('am_pro', 'pro'), isTrue);
      expect(isCurrentPlanType('am_pro', 'free'), isFalse);
      expect(isCurrentPlanType('am_pro_annual', 'pro'), isTrue);
      expect(isCurrentPlanType('am_free', 'free'), isTrue);
      expect(isCurrentPlanType('am_free', 'pro'), isFalse);
    });
  });

  group('effectiveSubscriptionPeriodEnd', () {
    test('uses referral expiry when billing period end is null', () {
      final referralEnd = DateTime(2026, 11, 5, 12);
      expect(
        effectiveSubscriptionPeriodEnd(referralProExpiresAt: referralEnd),
        referralEnd,
      );
    });

    test('uses trial expiry when billing period end is null', () {
      final trialEnd = DateTime(2026, 10, 20, 12);
      expect(
        effectiveSubscriptionPeriodEnd(trialProExpiresAt: trialEnd),
        trialEnd,
      );
    });

    test('picks the latest among billing and grant ends', () {
      final billing = DateTime(2026, 10, 15);
      final referral = DateTime(2026, 11, 1);
      final trial = DateTime(2026, 10, 12);
      expect(
        effectiveSubscriptionPeriodEnd(
          currentPeriodEnd: billing,
          referralProExpiresAt: referral,
          trialProExpiresAt: trial,
        ),
        referral,
      );
    });

    test('Subscription.effectivePeriodEnd reads grant fields from JSON', () {
      final json = {
        'id': 'sub-1',
        'user_id': 'u1',
        'tenant_id': null,
        'plan_code': 'am_pro',
        'plan_name': 'Pro',
        'state': 'active',
        'billing_interval': 'monthly',
        'current_period_start': null,
        'current_period_end': null,
        'is_paid': false,
        'grant_source': 'referral',
        'trial_pro_expires_at': null,
        'referral_pro_expires_at': '2026-11-05T12:00:00.000Z',
        'trial_starts_at': null,
        'limits': {
          'document_parses': 0,
          'portfolios': 0,
          'ai_portfolio_summaries': 0,
          'api_calls': 0,
        },
        'entitlements': {
          'live_market_data': true,
          'realtime_indices': true,
          'tradingview_charts': true,
          'basket_trading': false,
          'custom_ai_bots': false,
          'predictive_analytics': false,
        },
        'usage': <dynamic>[],
        'created_at': '2026-10-01T00:00:00.000Z',
        'updated_at': '2026-10-08T00:00:00.000Z',
      };
      final sub = Subscription.fromJson(json);
      expect(sub.currentPeriodEnd, isNull);
      expect(sub.referralProExpiresAt, isNotNull);
      expect(sub.effectivePeriodEnd, sub.referralProExpiresAt);

      final now = DateTime.utc(2026, 10, 8, 12);
      final rem = remainingSubscriptionDuration(sub.effectivePeriodEnd, now: now);
      expect(rem, isNotNull);
      expect(formatSubscriptionCountdown(rem), isNot(equals('End date unavailable')));
    });
  });

  group('subscription countdown', () {
    test('formats remaining duration', () {
      expect(
        formatSubscriptionCountdown(const Duration(days: 12, hours: 4, minutes: 22)),
        '12d 04h 22m',
      );
      expect(formatSubscriptionCountdown(Duration.zero), 'Expired');
      expect(formatSubscriptionCountdown(null), 'End date unavailable');
    });

    test('days remaining', () {
      expect(subscriptionDaysRemaining(const Duration(days: 28)), 28);
      expect(subscriptionDaysRemaining(const Duration(hours: 5)), 1);
      expect(subscriptionDaysRemaining(Duration.zero), 0);
      expect(subscriptionDaysRemaining(null), 0);
    });

    test('remainingSubscriptionDuration from period end', () {
      final now = DateTime(2026, 10, 8, 12);
      final end = now.add(const Duration(days: 2, hours: 3));
      final rem = remainingSubscriptionDuration(end, now: now);
      expect(rem?.inDays, 2);
      expect(remainingSubscriptionDuration(null, now: now), isNull);
    });
  });
}
