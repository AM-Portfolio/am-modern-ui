import 'package:dio/dio.dart';

import '../../../../core/constants/auth_endpoints.dart';
import '../models/login_session_model.dart';
import '../models/security_event_model.dart';

abstract class SecurityEventsApi {
  Future<List<SecurityEventModel>> listSecurityEvents({double? since});

  Future<SecurityEventModel> acknowledgeSecurityEvent(String eventId);
}

abstract class LoginSessionsApi extends SecurityEventsApi {
  Future<List<LoginSessionModel>> listSessions();

  Future<void> revokeSession(String sessionId);

  Future<void> revokeAllSessions();
}

class LoginSessionsRemoteDataSource implements LoginSessionsApi {
  LoginSessionsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<LoginSessionModel>> listSessions() async {
    final response = await _dio.get<List<dynamic>>(
      AuthEndpoints.identityLoginSessions,
    );
    final rows = response.data ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(LoginSessionModel.fromJson)
        .toList();
  }

  Future<void> revokeSession(String sessionId) async {
    await _dio.delete(AuthEndpoints.identityLoginSessionRevoke(sessionId));
  }

  Future<void> revokeAllSessions() async {
    await _dio.delete(AuthEndpoints.identityLoginSessionsRevokeAll);
  }

  Future<List<SecurityEventModel>> listSecurityEvents({double? since}) async {
    final response = await _dio.get<List<dynamic>>(
      AuthEndpoints.identitySecurityEvents,
      queryParameters: since != null ? {'since': since} : null,
    );
    final rows = response.data ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(SecurityEventModel.fromJson)
        .toList();
  }

  Future<SecurityEventModel> acknowledgeSecurityEvent(String eventId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AuthEndpoints.identitySecurityEventAck(eventId),
    );
    return SecurityEventModel.fromJson(response.data ?? const {});
  }
}
