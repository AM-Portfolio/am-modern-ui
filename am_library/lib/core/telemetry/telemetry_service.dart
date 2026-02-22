import 'dart:async';
import 'package:rxdart/rxdart.dart';

/// Types of telemetry events
enum TelemetryType { apiRequest, apiResponse, apiError, wsMessage, wsStatus }

/// Model for a technical telemetry event
class TelemetryEvent {
  final DateTime timestamp;
  final TelemetryType type;
  final String category; // e.g., 'Analysis', 'Market', 'Auth'
  final String label;    // e.g., 'GET /summary'
  final Map<String, dynamic>? metadata;
  final Duration? duration;
  final int? statusCode;

  TelemetryEvent({
    required this.type,
    required this.category,
    required this.label,
    DateTime? timestamp,
    this.metadata,
    this.duration,
    this.statusCode,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => '[$type] $category: $label (${statusCode ?? ""})';
}

/// Service to collect and broadcast technical telemetry across the ecosystem
class TelemetryService {
  // Use ReplaySubject to allow late-arriving diagnostic UIs to see recent history
  final _eventSubject = ReplaySubject<TelemetryEvent>(maxSize: 100);

  Stream<TelemetryEvent> get events => _eventSubject.stream;

  /// Record an event
  void record(TelemetryEvent event) {
    _eventSubject.add(event);
  }

  /// Convenience method for API metrics
  void recordApi(
    String category,
    String method,
    String path,
    int statusCode, {
    Duration? duration,
    Map<String, dynamic>? extra,
  }) {
    record(TelemetryEvent(
      type: statusCode >= 400 ? TelemetryType.apiError : TelemetryType.apiResponse,
      category: category,
      label: '$method $path',
      statusCode: statusCode,
      duration: duration,
      metadata: extra,
    ));
  }

  void dispose() {
    _eventSubject.close();
  }
}
