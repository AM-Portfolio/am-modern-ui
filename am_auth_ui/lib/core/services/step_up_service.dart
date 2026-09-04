import 'package:dio/dio.dart';

import '../constants/auth_endpoints.dart';

class StepUpResult {
  const StepUpResult({
    required this.stepUpToken,
    required this.expiresAt,
  });

  final String stepUpToken;
  final double expiresAt;

  factory StepUpResult.fromJson(Map<String, dynamic> json) {
    return StepUpResult(
      stepUpToken: json['step_up_token'] as String,
      expiresAt: (json['expires_at'] as num).toDouble(),
    );
  }
}

class StepUpService {
  StepUpService(this._dio);

  final Dio _dio;

  Future<StepUpResult> requestStepUp() async {
    final response = await _dio.post<Map<String, dynamic>>(
      AuthEndpoints.identityStepUp,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return StepUpResult.fromJson(response.data ?? const {});
  }
}
