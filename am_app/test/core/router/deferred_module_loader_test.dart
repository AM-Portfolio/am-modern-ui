import 'dart:async';
import 'package:am_app/core/router/deferred_module_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DeferredModuleLoader displays loading state then builder on success',
      (tester) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeferredModuleLoader(
            load: () => completer.future,
            loadingMessage: 'Loading test module…',
            builder: () => const Text('Module Content'),
          ),
        ),
      ),
    );

    expect(find.text('Loading test module…'), findsOneWidget);
    expect(find.text('Module Content'), findsNothing);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.text('Module Content'), findsOneWidget);
    expect(find.text('Loading test module…'), findsNothing);
  });

  testWidgets('DeferredModuleLoader shows error and retries upon tapping Retry button',
      (tester) async {
    var attempts = 0;
    Future<void> loadFn() async {
      attempts++;
      if (attempts == 1) {
        throw Exception('Network chunk timeout');
      }
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeferredModuleLoader(
            load: loadFn,
            builder: () => const Text('Loaded Successfully'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Network chunk timeout'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Loaded Successfully'), findsNothing);

    // Tap retry button
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Loaded Successfully'), findsOneWidget);
  });
}

