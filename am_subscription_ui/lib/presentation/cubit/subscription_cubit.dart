import 'dart:async';

import 'package:am_library/am_library.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/subscription_remote_datasource.dart';
import '../../data/subscription_browser_cache.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/subscription.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final List<Plan> plans;
  final Subscription? subscription;
  final bool refreshing;

  const SubscriptionLoaded({
    required this.plans,
    this.subscription,
    this.refreshing = false,
  });

  @override
  List<Object?> get props => [plans, subscription, refreshing];
}

class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
}

class SubscriptionActionInProgress extends SubscriptionState {
  final List<Plan> plans;
  final Subscription? subscription;

  const SubscriptionActionInProgress({
    required this.plans,
    this.subscription,
  });

  @override
  List<Object?> get props => [plans, subscription];
}

class SubscriptionActionSuccess extends SubscriptionState {
  final List<Plan> plans;
  final Subscription subscription;
  final String message;

  const SubscriptionActionSuccess({
    required this.plans,
    required this.subscription,
    required this.message,
  });

  @override
  List<Object?> get props => [plans, subscription, message];
}

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(
    this._dataSource, {
    SubscriptionBrowserCache? browserCache,
  })  : _browserCache = browserCache,
        super(SubscriptionInitial());

  final SubscriptionRemoteDataSource _dataSource;
  final SubscriptionBrowserCache? _browserCache;

  static const Duration _plansTtl = Duration(seconds: 90);
  static const Duration _meTtl = Duration(seconds: 45);

  List<Plan>? _cachedPlans;
  DateTime? _plansCachedAt;
  Subscription? _cachedSubscription;
  DateTime? _meCachedAt;
  bool _diskHydrated = false;

  bool get _plansFresh =>
      _cachedPlans != null &&
      _plansCachedAt != null &&
      DateTime.now().difference(_plansCachedAt!) < _plansTtl;

  bool get _meFresh =>
      _meCachedAt != null &&
      DateTime.now().difference(_meCachedAt!) < _meTtl;

  /// Status label for Profile (e.g. "Pro · Active"). Null if unknown.
  String? get statusLabel {
    final sub = _cachedSubscription;
    if (sub == null) return null;
    final name = sub.planName.trim().isNotEmpty
        ? sub.planName.trim()
        : _planNameFromCode(sub.planCode);
    final state = _titleCase(sub.state);
    return state.isEmpty ? name : '$name · $state';
  }

  bool get isPaidSubscription {
    final sub = _cachedSubscription;
    if (sub == null) return false;
    return !_isFreePlan(sub.planCode);
  }

  Future<void> invalidateCache() async {
    final userId = UserContext.instance.cachedUserId;
    _cachedPlans = null;
    _plansCachedAt = null;
    _cachedSubscription = null;
    _meCachedAt = null;
    _diskHydrated = false;
    await _browserCache?.clear(userId: userId);
  }

  Future<void> loadPlansAndSubscription({bool force = false}) async {
    await _hydrateFromBrowserIfNeeded();

    if (!force && _plansFresh && _meFresh && _cachedPlans != null) {
      emit(SubscriptionLoaded(
        plans: _cachedPlans!,
        subscription: _cachedSubscription,
      ));
      unawaited(_refreshInBackground());
      return;
    }

    if (_cachedPlans != null) {
      emit(SubscriptionLoaded(
        plans: _cachedPlans!,
        subscription: _cachedSubscription,
        refreshing: true,
      ));
    } else {
      emit(SubscriptionLoading());
    }

    try {
      await _fetchAndEmit();
    } catch (e) {
      if (_cachedPlans != null) {
        emit(SubscriptionLoaded(
          plans: _cachedPlans!,
          subscription: _cachedSubscription,
        ));
      } else {
        emit(SubscriptionError(e.toString()));
      }
    }
  }

  /// Ensures `/me` is warm for Profile without requiring plans UI.
  Future<void> ensureSubscriptionStatus() async {
    await _hydrateFromBrowserIfNeeded();
    if (_meFresh) return;
    try {
      final sub = await _dataSource.getCurrentSubscription();
      await _rememberMe(sub);
      if (_cachedPlans != null && state is! SubscriptionLoading) {
        emit(SubscriptionLoaded(
          plans: _cachedPlans!,
          subscription: sub,
        ));
      }
    } catch (_) {
      _meCachedAt = DateTime.now();
      _cachedSubscription = null;
    }
  }

  Future<void> _hydrateFromBrowserIfNeeded() async {
    if (_diskHydrated || _browserCache == null) {
      _diskHydrated = true;
      return;
    }
    _diskHydrated = true;

    if (_cachedPlans == null) {
      final plans = await _browserCache!.readPlans();
      if (plans != null && plans.isNotEmpty) {
        _cachedPlans = plans;
        // Disk hit is slightly stale so we still SWR, but skip full-screen load.
        _plansCachedAt =
            DateTime.now().subtract(const Duration(seconds: 1));
      }
    }

    if (_cachedSubscription == null) {
      final userId = UserContext.instance.cachedUserId ??
          await UserContext.instance.userId;
      if (userId != null && userId.isNotEmpty) {
        final me = await _browserCache!.readMe(userId);
        if (me != null) {
          _cachedSubscription = me;
          _meCachedAt =
              DateTime.now().subtract(const Duration(seconds: 1));
        }
      }
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      await _fetchAndEmit();
    } catch (_) {
      // Keep showing cached data.
    }
  }

  Future<void> _fetchAndEmit() async {
    final results = await Future.wait<Object?>([
      _dataSource.getPlans(),
      () async {
        try {
          return await _dataSource.getCurrentSubscription();
        } catch (_) {
          return null;
        }
      }(),
    ]);
    final plans = results[0]! as List<Plan>;
    final sub = results[1] as Subscription?;
    await _rememberPlans(plans);
    await _rememberMe(sub);
    emit(SubscriptionLoaded(plans: plans, subscription: sub));
  }

  Future<void> _rememberPlans(List<Plan> plans) async {
    _cachedPlans = plans;
    _plansCachedAt = DateTime.now();
    await _browserCache?.writePlans(plans);
  }

  Future<void> _rememberMe(Subscription? sub) async {
    _cachedSubscription = sub;
    _meCachedAt = DateTime.now();
    final userId = UserContext.instance.cachedUserId ??
        await UserContext.instance.userId;
    if (userId != null && userId.isNotEmpty) {
      await _browserCache?.writeMe(userId, sub);
    }
  }

  Future<void> subscribe(String planCode, String billingInterval) async {
    final currentState = state;
    if (currentState is! SubscriptionLoaded) return;

    emit(SubscriptionActionInProgress(
      plans: currentState.plans,
      subscription: currentState.subscription,
    ));

    try {
      final sub =
          await _dataSource.createSubscription(planCode, billingInterval);
      await invalidateCache();
      await _rememberPlans(currentState.plans);
      await _rememberMe(sub);
      emit(SubscriptionActionSuccess(
        plans: currentState.plans,
        subscription: sub,
        message: 'Successfully subscribed to ${sub.planName}!',
      ));
      emit(SubscriptionLoaded(plans: currentState.plans, subscription: sub));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
      emit(SubscriptionLoaded(
        plans: currentState.plans,
        subscription: currentState.subscription,
      ));
    }
  }

  Future<void> upgrade(
    String subscriptionId,
    String planCode,
    String billingInterval,
  ) async {
    final currentState = state;
    if (currentState is! SubscriptionLoaded) return;

    emit(SubscriptionActionInProgress(
      plans: currentState.plans,
      subscription: currentState.subscription,
    ));

    try {
      final sub = await _dataSource.upgradeSubscription(
        subscriptionId,
        planCode,
        billingInterval,
      );
      await invalidateCache();
      await _rememberPlans(currentState.plans);
      await _rememberMe(sub);
      emit(SubscriptionActionSuccess(
        plans: currentState.plans,
        subscription: sub,
        message: 'Successfully upgraded to ${sub.planName}!',
      ));
      emit(SubscriptionLoaded(plans: currentState.plans, subscription: sub));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
      emit(SubscriptionLoaded(
        plans: currentState.plans,
        subscription: currentState.subscription,
      ));
    }
  }

  static bool _isFreePlan(String planCode) {
    final code = planCode.toLowerCase();
    return code.contains('free') || code == 'am_free';
  }

  static String _planNameFromCode(String planCode) {
    final code = planCode.toLowerCase();
    if (code.contains('premium')) return 'Premium';
    if (code.contains('pro')) return 'Pro';
    if (code.contains('free')) return 'Free';
    return planCode;
  }

  static String _titleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }
}
