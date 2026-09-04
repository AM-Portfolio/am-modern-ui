import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/constants/auth_endpoints.dart';
import '../models/device_link_models.dart';
import '../services/device_link_poll_service.dart';

class DeviceLinkRemoteDataSource implements DeviceLinkApi {
  DeviceLinkRemoteDataSource(this._dio);

  final Dio _dio;

  Future<DeviceLinkStartResult> start({
    required String codeChallenge,
    String redirectHint = 'am.asrax.in',
    String? browser,
    String? os,
  }) async {
    final response = await _dio.post(
      AuthEndpoints.identityDeviceLinkStart,
      data: {
        'client': 'web',
        'redirect_hint': redirectHint,
        'code_challenge': codeChallenge,
        if (browser != null) 'browser': browser,
        if (os != null) 'os': os,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
        extra: const {'withCredentials': true},
      ),
    );
    return DeviceLinkStartResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<DeviceLinkPollResult> pollStatus({
    required String deviceLinkId,
    required String codeVerifier,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      AuthEndpoints.identityDeviceLinkStatus(deviceLinkId),
      queryParameters: {'code_verifier': codeVerifier},
      options: Options(extra: const {'withCredentials': true}),
    );
    final data = response.data ?? const {};
    DeviceLinkPollUser? user;
    final userJson = data['user'];
    if (userJson is Map<String, dynamic>) {
      user = DeviceLinkPollUser.fromJson(userJson);
    }
    WebSessionTokens? tokens;
    final tokensJson = data['tokens'];
    if (tokensJson is Map<String, dynamic>) {
      tokens = WebSessionTokens.fromJson(tokensJson);
    }
    return DeviceLinkPollResult(
      status: data['status'] as String? ?? 'pending',
      user: user,
      tokens: tokens,
    );
  }

  Future<void> cancel(String deviceLinkId) async {
    await _dio.post(AuthEndpoints.identityDeviceLinkCancel(deviceLinkId));
  }

  Future<DeviceLinkPreview> preview(String deviceLinkId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      AuthEndpoints.identityDeviceLinkPreview(deviceLinkId),
    );
    return DeviceLinkPreview.fromJson(response.data ?? const {});
  }

  Future<void> approve({
    required String deviceLinkId,
    required String confirmationCode,
    String? deviceName,
    String? machineLabel,
  }) async {
    await _dio.post(
      AuthEndpoints.identityDeviceLinkApprove(deviceLinkId),
      data: {
        'confirmation_code': confirmationCode,
        if (deviceName != null) 'device_name': deviceName,
        if (machineLabel != null) 'machine_label': machineLabel,
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  Future<void> deny(String deviceLinkId, {String? reason}) async {
    await _dio.post(
      AuthEndpoints.identityDeviceLinkDeny(deviceLinkId),
      data: {if (reason != null) 'reason': reason},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  String? parseDeviceLinkIdFromPayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed) as Map<String, dynamic>;
        if (decoded['type'] == 'am_device_link') {
          return decoded['id']?.toString();
        }
      } catch (_) {
        return null;
      }
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    final id = uri.queryParameters['id'];
    if (id != null && id.isNotEmpty) return id;
    return null;
  }
}
