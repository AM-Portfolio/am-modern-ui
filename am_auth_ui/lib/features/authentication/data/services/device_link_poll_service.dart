import 'dart:async';

import 'package:dio/dio.dart';

import '../models/device_link_models.dart';

abstract class DeviceLinkApi {
  Future<DeviceLinkStartResult> start({
    required String codeChallenge,
    String redirectHint,
    String? browser,
    String? os,
  });

  Future<DeviceLinkPollResult> pollStatus({
    required String deviceLinkId,
    required String codeVerifier,
  });

  Future<void> cancel(String deviceLinkId);
}

enum DeviceLinkPollState {
  waiting,
  approved,
  expired,
  error,
}

class DeviceLinkPollSession {
  DeviceLinkPollSession({
    required this.deviceLinkId,
    required this.codeVerifier,
    required this.confirmationCode,
    required this.qrPayload,
    required this.expiresAt,
    required this.pollIntervalMs,
  });

  final String deviceLinkId;
  final String codeVerifier;
  final String confirmationCode;
  final Map<String, dynamic> qrPayload;
  final double expiresAt;
  final int pollIntervalMs;
}

class DeviceLinkPollService {
  DeviceLinkPollService(this._dataSource);

  final DeviceLinkApi _dataSource;

  Timer? _pollTimer;
  String? _activeDeviceLinkId;
  bool _pollInFlight = false;

  Future<DeviceLinkPollSession> startSession({
    required String codeVerifier,
    required String codeChallenge,
    String? browser,
    String? os,
  }) async {
    final result = await _dataSource.start(
      codeChallenge: codeChallenge,
      browser: browser,
      os: os,
    );
    return DeviceLinkPollSession(
      deviceLinkId: result.deviceLinkId,
      codeVerifier: codeVerifier,
      confirmationCode: result.confirmationCode,
      qrPayload: result.qrPayload,
      expiresAt: result.expiresAt,
      pollIntervalMs: result.pollIntervalMs,
    );
  }

  void startPolling({
    required DeviceLinkPollSession session,
    required void Function(
      DeviceLinkPollState state,
      DeviceLinkPollUser? user, {
      WebSessionTokens? tokens,
    }) onUpdate,
    void Function(Object error)? onError,
  }) {
    stopPolling();
    _activeDeviceLinkId = session.deviceLinkId;
    final interval = Duration(milliseconds: session.pollIntervalMs);

    _pollTimer = Timer.periodic(interval, (_) {
      unawaited(_pollOnce(session, onUpdate, onError));
    });
    unawaited(_pollOnce(session, onUpdate, onError));
  }

  Future<void> _pollOnce(
    DeviceLinkPollSession session,
    void Function(
      DeviceLinkPollState state,
      DeviceLinkPollUser? user, {
      WebSessionTokens? tokens,
    }) onUpdate,
    void Function(Object error)? onError,
  ) async {
    if (_activeDeviceLinkId != session.deviceLinkId || _pollInFlight) return;

    final nowSeconds = DateTime.now().millisecondsSinceEpoch / 1000;
    if (nowSeconds >= session.expiresAt) {
      stopPolling();
      onUpdate(DeviceLinkPollState.expired, null);
      return;
    }

    _pollInFlight = true;
    try {
      final result = await _dataSource.pollStatus(
        deviceLinkId: session.deviceLinkId,
        codeVerifier: session.codeVerifier,
      );
      switch (result.status) {
        case 'approved':
          stopPolling();
          onUpdate(
            DeviceLinkPollState.approved,
            result.user,
            tokens: result.tokens,
          );
        case 'expired':
        case 'cancelled':
          stopPolling();
          onUpdate(DeviceLinkPollState.expired, null);
        default:
          onUpdate(DeviceLinkPollState.waiting, null);
      }
    } catch (error) {
      if (_isTransientPollError(error)) {
        onUpdate(DeviceLinkPollState.waiting, null);
        return;
      }
      stopPolling();
      onError?.call(error);
      onUpdate(DeviceLinkPollState.error, null);
    } finally {
      _pollInFlight = false;
    }
  }

  Future<void> cancelActiveSession() async {
    final id = _activeDeviceLinkId;
    stopPolling();
    if (id != null) {
      await _dataSource.cancel(id);
    }
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _activeDeviceLinkId = null;
    _pollInFlight = false;
  }

  void dispose() {
    stopPolling();
  }
}

bool _isTransientPollError(Object error) {
  if (error is! DioException) return false;
  final status = error.response?.statusCode;
  return status == 429 || status == 502 || status == 503 || status == 504;
}
