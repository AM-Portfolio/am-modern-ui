import 'dart:async';

import 'package:am_auth_ui/core/services/security_alert_service.dart';
import 'package:am_auth_ui/features/authentication/data/datasources/login_sessions_remote_datasource.dart';
import 'package:am_auth_ui/features/authentication/data/models/security_event_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecurityEventsApi implements SecurityEventsApi {
  List<SecurityEventModel> events = const [];

  @override
  Future<SecurityEventModel> acknowledgeSecurityEvent(String eventId) async {
    return events.firstWhere((event) => event.eventId == eventId);
  }

  @override
  Future<List<SecurityEventModel>> listSecurityEvents({double? since}) async {
    return events;
  }
}

void main() {
  group('SecurityAlertService', () {
    test('pollNow emits unread new_device_login events when tab visible', () async {
      final dataSource = _FakeSecurityEventsApi();
      dataSource.events = const [
        SecurityEventModel(
          eventId: 'evt-1',
          type: 'new_device_login',
          createdAt: 1,
          acknowledged: false,
          deviceLabel: 'Chrome · Windows',
          geoCity: 'Mumbai',
          geoCountry: 'IN',
        ),
      ];

      final service = SecurityAlertService(
        dataSource: dataSource,
        isTabVisible: () => true,
      );

      final completer = Completer<List<SecurityEventModel>>();
      service.events.listen(completer.complete);

      await service.pollNow();
      final emitted = await completer.future.timeout(const Duration(seconds: 1));

      expect(emitted, hasLength(1));
      expect(emitted.first.eventId, 'evt-1');
      service.dispose();
    });

    test('pollNow skips when tab is hidden', () async {
      final dataSource = _FakeSecurityEventsApi();
      dataSource.events = const [
        SecurityEventModel(
          eventId: 'evt-1',
          type: 'new_device_login',
          createdAt: 1,
          acknowledged: false,
        ),
      ];

      final service = SecurityAlertService(
        dataSource: dataSource,
        isTabVisible: () => false,
      );

      var emitted = false;
      service.events.listen((_) => emitted = true);
      await service.pollNow();

      expect(emitted, isFalse);
      service.dispose();
    });
  });
}
