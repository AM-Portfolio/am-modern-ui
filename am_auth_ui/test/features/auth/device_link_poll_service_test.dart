import 'dart:async';

import 'package:am_auth_ui/features/authentication/data/models/device_link_models.dart';
import 'package:am_auth_ui/features/authentication/data/services/device_link_poll_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDeviceLinkApi implements DeviceLinkApi {
  _FakeDeviceLinkApi({this.pollError});

  int pollCount = 0;
  DeviceLinkPollResult pollResult = const DeviceLinkPollResult(status: 'pending');
  Object? pollError;

  @override
  Future<void> cancel(String deviceLinkId) async {}

  @override
  Future<DeviceLinkPollResult> pollStatus({
    required String deviceLinkId,
    required String codeVerifier,
  }) async {
    pollCount++;
    final error = pollError;
    if (error != null) {
      pollError = null;
      throw error;
    }
    return pollResult;
  }

  @override
  Future<DeviceLinkStartResult> start({
    required String codeChallenge,
    String redirectHint = 'am.asrax.in',
    String? browser,
    String? os,
  }) async {
    return DeviceLinkStartResult(
      deviceLinkId: 'link-1',
      qrPayload: const {'id': 'link-1', 'type': 'am_device_link'},
      confirmationCode: '482913',
      expiresAt: DateTime.now().millisecondsSinceEpoch / 1000 + 120,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceLinkPollService', () {
    test('poll approved invokes callback with user', () async {
      final api = _FakeDeviceLinkApi();
      api.pollResult = DeviceLinkPollResult(
        status: 'approved',
        user: const DeviceLinkPollUser(
          sub: 'user-1',
          email: 'user@example.com',
        ),
      );

      final service = DeviceLinkPollService(api);
      final session = await service.startSession(
        codeVerifier: 'verifier',
        codeChallenge: 'challenge',
      );

      final completer = Completer<DeviceLinkPollUser?>();
      service.startPolling(
        session: session,
        onUpdate: (state, user, {tokens}) {
          if (state == DeviceLinkPollState.approved) {
            completer.complete(user);
          }
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      service.stopPolling();

      final user = await completer.future.timeout(const Duration(seconds: 1));
      expect(user?.sub, 'user-1');
      expect(api.pollCount, greaterThan(0));
    });

    test('expired session triggers expired state before ttl', () async {
      final api = _FakeDeviceLinkApi();
      final service = DeviceLinkPollService(api);
      final session = DeviceLinkPollSession(
        deviceLinkId: 'link-1',
        codeVerifier: 'verifier',
        confirmationCode: '482913',
        qrPayload: const {'id': 'link-1'},
        expiresAt: DateTime.now().millisecondsSinceEpoch / 1000 - 1,
        pollIntervalMs: 20,
      );

      final completer = Completer<DeviceLinkPollState>();
      service.startPolling(
        session: session,
        onUpdate: (state, _, {tokens}) {
          if (!completer.isCompleted) completer.complete(state);
        },
      );

      final state = await completer.future.timeout(const Duration(seconds: 1));
      expect(state, DeviceLinkPollState.expired);
      service.stopPolling();
    });

    test('429 stays waiting and does not invoke onError', () async {
      final api = _FakeDeviceLinkApi(
        pollError: DioException(
          requestOptions: RequestOptions(path: '/status'),
          response: Response(
            requestOptions: RequestOptions(path: '/status'),
            statusCode: 429,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      final service = DeviceLinkPollService(api);
      final session = DeviceLinkPollSession(
        deviceLinkId: 'link-1',
        codeVerifier: 'verifier',
        confirmationCode: '482913',
        qrPayload: const {'id': 'link-1'},
        expiresAt: DateTime.now().millisecondsSinceEpoch / 1000 + 120,
        pollIntervalMs: 20,
      );

      Object? capturedError;
      final states = <DeviceLinkPollState>[];
      service.startPolling(
        session: session,
        onUpdate: (state, _, {tokens}) => states.add(state),
        onError: (error) => capturedError = error,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      service.stopPolling();

      expect(states, contains(DeviceLinkPollState.waiting));
      expect(capturedError, isNull);
    });
  });
}
