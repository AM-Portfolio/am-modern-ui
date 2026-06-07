import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/subscription.dart';

abstract class SubscriptionRemoteDataSource {
  Future<List<Plan>> getPlans();
  Future<Subscription> getCurrentSubscription();
  Future<Subscription> createSubscription(String planCode, String billingInterval);
  Future<Subscription> upgradeSubscription(String subscriptionId, String planCode, String billingInterval);
}

@LazySingleton(as: SubscriptionRemoteDataSource)
class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final Dio _dio;

  SubscriptionRemoteDataSourceImpl(@Named('subscriptionDio') this._dio);

  @override
  Future<List<Plan>> getPlans() async {
    final response = await _dio.get('/subscriptions/plans');
    final data = response.data['data'] as List;
    return data.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Subscription> getCurrentSubscription() async {
    final response = await _dio.get('/subscriptions/me');
    return Subscription.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Subscription> createSubscription(String planCode, String billingInterval) async {
    final response = await _dio.post(
      '/subscriptions',
      data: {
        'plan_code': planCode,
        'billing_interval': billingInterval,
      },
    );
    return Subscription.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Subscription> upgradeSubscription(String subscriptionId, String planCode, String billingInterval) async {
    final response = await _dio.patch(
      '/subscriptions/$subscriptionId/upgrade',
      data: {
        'plan_code': planCode,
        'billing_interval': billingInterval,
      },
    );
    return Subscription.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
