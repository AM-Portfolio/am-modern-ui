import 'package:am_library/am_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Stream of accumulated telemetry events for the UI
final telemetryHistoryProvider = StreamProvider<List<TelemetryEvent>>((ref) {
  final telemetry = ServiceRegistry.telemetry;
  
  // Return a stream that accumulates events for the UI
  return telemetry.events.transform(
    StreamTransformer.fromHandlers(
      handleData: (event, sink) {
        // This is a bit tricky with manual providers to keep state.
        // Usually, we'd use a StateNotifier or a custom class.
      },
    ),
  );
});

/// Refined Diagnostic Provider using standard Riverpod syntax to avoid version conflicts
final sdkHealthMetricsProvider = Provider<Map<String, HealthMetric>>((ref) {
  final history = ref.watch(telemetryHistoryProvider).value ?? [];
  
  final metrics = <String, HealthMetric>{};
  
  for (var event in history) {
    final metric = metrics.putIfAbsent(event.category, () => HealthMetric(category: event.category));
    metric.addEvent(event);
  }
  
  return metrics;
});

/// Simplified Telemetry History Provider using a StateProvider approach for easier accumulation
final telemetryLogProvider = NotifierProvider<TelemetryLogNotifier, List<TelemetryEvent>>(TelemetryLogNotifier.new);

class TelemetryLogNotifier extends Notifier<List<TelemetryEvent>> {
  StreamSubscription<TelemetryEvent>? _subscription;
  
  @override
  List<TelemetryEvent> build() {
    final telemetry = ServiceRegistry.telemetry;
    _subscription = telemetry.events.listen((event) {
      state = [event, ...state].take(100).toList();
    });
    
    ref.onDispose(() => _subscription?.cancel());
    return [];
  }
}

/// Provider for Mock Data Toggle
final mockDataEnabledProvider = NotifierProvider<MockDataEnabledNotifier, bool>(MockDataEnabledNotifier.new);

class MockDataEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void set(bool value) => state = value;
}

class HealthMetric {
  final String category;
  int requests = 0;
  int successes = 0;
  int errors = 0;
  List<Duration> latencies = [];

  HealthMetric({required this.category});

  void addEvent(TelemetryEvent event) {
    requests++;
    if (event.type == TelemetryType.apiError) {
      errors++;
    } else if (event.type == TelemetryType.apiResponse) {
      successes++;
    }
    
    if (event.duration != null) {
      latencies.add(event.duration!);
    }
  }

  double get successRate => requests == 0 ? 100 : (successes / requests) * 100;
  
  Duration get avgLatency {
    if (latencies.isEmpty) return Duration.zero;
    final total = latencies.fold(Duration.zero, (prev, next) => prev + next);
    return total ~/ latencies.length;
  }
}
