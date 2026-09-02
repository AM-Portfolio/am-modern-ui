import 'dart:async';

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
    required void Function(DeviceLinkPollState state, DeviceLinkPollUser? user)
        onUpdate,
    void Function(Object error)? onError,
  }) {
    stopPolling();
    _activeDeviceLinkId = session.deviceLinkId;
    final interval = Duration(milliseconds: session.pollIntervalMs);

    unawaited(_pollOnce(session, onUpdate, onError));

    _pollTimer = Timer.periodic(interval, (_) {
      unawaited(_pollOnce(session, onUpdate, onError));
    });
  }

  Future<void> _pollOnce(
    DeviceLinkPollSession session,
    void Function(DeviceLinkPollState state, DeviceLinkPollUser? user) onUpdate,
    void Function(Object error)? onError,
  ) async {
    if (_activeDeviceLinkId != session.deviceLinkId) return;

    final nowSeconds = DateTime.now().millisecondsSinceEpoch / 1000;
    if (nowSeconds >= session.expiresAt) {
      onUpdate(DeviceLinkPollState.expired, null);
      return;
    }

    try {
      final result = await _dataSource.pollStatus(
        deviceLinkId: session.deviceLinkId,
        codeVerifier: session.codeVerifier,
      );
      switch (result.status) {
        case 'approved':
          stopPolling();
          onUpdate(DeviceLinkPollState.approved, result.user);
        case 'expired':
        case 'cancelled':
          onUpdate(DeviceLinkPollState.expired, null);
        default:
          onUpdate(DeviceLinkPollState.waiting, null);
      }
    } catch (error) {
      onError?.call(error);
      onUpdate(DeviceLinkPollState.error, null);
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
  }

  void dispose() {
    stopPolling();
  }
}
