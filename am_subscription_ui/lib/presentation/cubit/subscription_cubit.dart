import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/subscription.dart';
import '../../data/datasources/subscription_remote_datasource.dart';

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

  const SubscriptionLoaded({
    required this.plans,
    this.subscription,
  });

  @override
  List<Object?> get props => [plans, subscription];
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
  final SubscriptionRemoteDataSource _dataSource;

  SubscriptionCubit(this._dataSource) : super(SubscriptionInitial());

  Future<void> loadPlansAndSubscription() async {
    emit(SubscriptionLoading());
    try {
      final plans = await _dataSource.getPlans();
      Subscription? currentSubscription;
      try {
        currentSubscription = await _dataSource.getCurrentSubscription();
      } catch (e) {
        // If no active subscription is found or 404, we log it and keep it null
        print('No active subscription found or failed: $e');
      }
      emit(SubscriptionLoaded(plans: plans, subscription: currentSubscription));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
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
      final sub = await _dataSource.createSubscription(planCode, billingInterval);
      emit(SubscriptionActionSuccess(
        plans: currentState.plans,
        subscription: sub,
        message: 'Successfully subscribed to ${sub.planName}!',
      ));
      emit(SubscriptionLoaded(plans: currentState.plans, subscription: sub));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
      emit(SubscriptionLoaded(plans: currentState.plans, subscription: currentState.subscription));
    }
  }

  Future<void> upgrade(String subscriptionId, String planCode, String billingInterval) async {
    final currentState = state;
    if (currentState is! SubscriptionLoaded) return;

    emit(SubscriptionActionInProgress(
      plans: currentState.plans,
      subscription: currentState.subscription,
    ));

    try {
      final sub = await _dataSource.upgradeSubscription(subscriptionId, planCode, billingInterval);
      emit(SubscriptionActionSuccess(
        plans: currentState.plans,
        subscription: sub,
        message: 'Successfully upgraded to ${sub.planName}!',
      ));
      emit(SubscriptionLoaded(plans: currentState.plans, subscription: sub));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
      emit(SubscriptionLoaded(plans: currentState.plans, subscription: currentState.subscription));
    }
  }
}
