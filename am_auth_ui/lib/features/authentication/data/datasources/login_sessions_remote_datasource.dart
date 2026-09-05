import 'package:dio/dio.dart';

import '../../../../core/constants/auth_endpoints.dart';
import '../../../../core/services/secure_storage_service.dart';
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
  LoginSessionsRemoteDataSource(
    this._dio, {
    required SecureStorageService storage,
    required Dio cookieDio,
  })  : _storage = storage,
        _cookieDio = cookieDio;

  final Dio _dio;
  final SecureStorageService _storage;
  final Dio _cookieDio;

  static const _cookieSessionToken = 'bff_cookie_session';

  Future<Dio> _client() async {
    final token = await _storage.getAccessToken();
    if (token == _cookieSessionToken || token?.startsWith('web-access-') == true) {
      return _cookieDio;
    }
    return _dio;
  }

  Options _requestOptions(Dio client) => Options(
        extra: client == _cookieDio ? const {'withCredentials': true} : null,
      );

  Future<List<LoginSessionModel>> listSessions() async {
    final client = await _client();
    final response = await client.get<List<dynamic>>(
      AuthEndpoints.identityLoginSessions,
      options: _requestOptions(client),
    );
    final rows = response.data ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(LoginSessionModel.fromJson)
        .toList();
  }

  Future<void> revokeSession(String sessionId) async {
    final client = await _client();
    await client.delete(
      AuthEndpoints.identityLoginSessionRevoke(sessionId),
      options: _requestOptions(client),
    );
  }

  Future<void> revokeAllSessions() async {
    final client = await _client();
    await client.delete(
      AuthEndpoints.identityLoginSessionsRevokeAll,
      options: _requestOptions(client),
    );
  }

  Future<List<SecurityEventModel>> listSecurityEvents({double? since}) async {
    final client = await _client();
    final response = await client.get<List<dynamic>>(
      AuthEndpoints.identitySecurityEvents,
      queryParameters: since != null ? {'since': since} : null,
      options: _requestOptions(client),
    );
    final rows = response.data ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(SecurityEventModel.fromJson)
        .toList();
  }

  Future<SecurityEventModel> acknowledgeSecurityEvent(String eventId) async {
    final client = await _client();
    final response = await client.post<Map<String, dynamic>>(
      AuthEndpoints.identitySecurityEventAck(eventId),
      options: _requestOptions(client),
    );
    return SecurityEventModel.fromJson(response.data ?? const {});
  }
}
