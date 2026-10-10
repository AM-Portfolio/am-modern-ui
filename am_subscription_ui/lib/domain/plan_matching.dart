import 'entities/subscription.dart';

/// Plan tier for matching "current plan" across monthly/annual SKUs.
enum PlanTier { free, pro, premium, other }

/// Resolves billing + grant expiry fields on a [Subscription].
extension SubscriptionEffectivePeriod on Subscription {
  DateTime? get effectivePeriodEnd => effectiveSubscriptionPeriodEnd(
    currentPeriodEnd: currentPeriodEnd,
    referralProExpiresAt: referralProExpiresAt,
    trialProExpiresAt: trialProExpiresAt,
  );
}

/// Resolves a catalog / subscription plan code into a coarse tier.
PlanTier planTierFromCode(String? planCode) {
  if (planCode == null || planCode.trim().isEmpty) return PlanTier.other;
  final code = planCode.toLowerCase();
  if (code.contains('free') || code == 'am_free') return PlanTier.free;
  if (code.contains('premium')) return PlanTier.premium;
  if (code.contains('pro')) return PlanTier.pro;
  return PlanTier.other;
}

/// True when [subscriptionPlanCode] is the same product family as [cardTier]
/// (e.g. `am_pro` matches Pro annual card).
bool isCurrentTier(String? subscriptionPlanCode, PlanTier cardTier) {
  if (cardTier == PlanTier.other) return false;
  return planTierFromCode(subscriptionPlanCode) == cardTier;
}

/// Convenience for pricing cards keyed by type string (`free` / `pro` / `premium`).
bool isCurrentPlanType(String? subscriptionPlanCode, String type) {
  switch (type.toLowerCase()) {
    case 'free':
      return isCurrentTier(subscriptionPlanCode, PlanTier.free);
    case 'pro':
      return isCurrentTier(subscriptionPlanCode, PlanTier.pro);
    case 'premium':
      return isCurrentTier(subscriptionPlanCode, PlanTier.premium);
    default:
      return false;
  }
}

/// Best-known Pro end among billing period and grant expiries.
///
/// Paid Stripe uses [currentPeriodEnd]; referral/trial grants store
/// [referralProExpiresAt] / [trialProExpiresAt] instead. When several are
/// present, the latest wins (stacked runway).
DateTime? effectiveSubscriptionPeriodEnd({
  DateTime? currentPeriodEnd,
  DateTime? referralProExpiresAt,
  DateTime? trialProExpiresAt,
}) {
  DateTime? latest;
  for (final candidate in [
    currentPeriodEnd,
    referralProExpiresAt,
    trialProExpiresAt,
  ]) {
    if (candidate == null) continue;
    if (latest == null || candidate.isAfter(latest)) {
      latest = candidate;
    }
  }
  return latest;
}

/// Remaining time until [periodEnd], or null if unknown / already ended.
Duration? remainingSubscriptionDuration(DateTime? periodEnd, {DateTime? now}) {
  if (periodEnd == null) return null;
  final remaining = periodEnd.difference(now ?? DateTime.now());
  if (remaining.isNegative) return Duration.zero;
  return remaining;
}

/// Human-readable countdown, e.g. `12d 04h 22m` or `Expired`.
String formatSubscriptionCountdown(Duration? remaining) {
  if (remaining == null) return 'End date unavailable';
  if (remaining <= Duration.zero) return 'Expired';
  final days = remaining.inDays;
  final hours = remaining.inHours.remainder(24);
  final minutes = remaining.inMinutes.remainder(60);
  if (days > 0) {
    return '${days}d ${hours.toString().padLeft(2, '0')}h '
        '${minutes.toString().padLeft(2, '0')}m';
  }
  if (remaining.inHours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  final seconds = remaining.inSeconds.remainder(60);
  return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
}

/// Whole days left (ceil-ish UX: at least 1 if any positive time remains under 24h).
int subscriptionDaysRemaining(Duration? remaining) {
  if (remaining == null || remaining <= Duration.zero) return 0;
  final days = remaining.inDays;
  if (days > 0) return days;
  return 1;
}
