import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AppZoomPointer.reset);

  testWidgets('150% chrome zoom compensates layout width to 1920',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1280, 720)),
          child: BrowserZoomHost(
            listenToPlatform: false,
            metricsReader: () => const BrowserZoomMetrics(
              innerWidth: 1280,
              innerHeight: 720,
              outerWidth: 1920,
              devicePixelRatio: 1.5,
            ),
            child: Builder(
              builder: (context) {
                final data = BrowserZoomScope.maybeOf(context)!;
                final w = MediaQuery.sizeOf(context).width;
                return Text(
                  'layout=${data.layoutSize.width.round()} mq=${w.round()} p=${data.percent}',
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('layout=1920 mq=1280 p=150'), findsOneWidget);
  });

  testWidgets('does not inflate MediaQuery so centered login stays on-screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1280, 720)),
          child: BrowserZoomHost(
            listenToPlatform: false,
            metricsReader: () => const BrowserZoomMetrics(
              innerWidth: 1280,
              innerHeight: 720,
              outerWidth: 1920,
              devicePixelRatio: 1.5,
            ),
            child: const Scaffold(
              body: Center(child: Text('LOGIN')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('LOGIN'), findsOneWidget);
    final login = tester.getRect(find.text('LOGIN'));
    expect(login.left, greaterThanOrEqualTo(0));
    expect(login.top, greaterThanOrEqualTo(0));
    expect(login.right, lessThanOrEqualTo(1280));
    expect(login.bottom, lessThanOrEqualTo(720));
  });

  testWidgets('chrome percent comes from browser metrics, not in-app storage',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BrowserZoomHost(
          listenToPlatform: false,
          metricsReader: () => const BrowserZoomMetrics(
            innerWidth: 1920,
            innerHeight: 1080,
            outerWidth: 1920,
            devicePixelRatio: 1.0,
          ),
          child: Builder(
            builder: (context) {
              final data = BrowserZoomScope.maybeOf(context)!;
              return Text('p=${data.percent}');
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('p=100'), findsOneWidget);
  });

  testWidgets('metrics change on maximize rebuilds layout size', (tester) async {
    var inner = 1100.0;
    var outer = 1650.0;
    await tester.pumpWidget(
      MaterialApp(
        home: BrowserZoomHost(
          listenToPlatform: false,
          metricsReader: () => BrowserZoomMetrics(
            innerWidth: inner,
            innerHeight: 700,
            outerWidth: outer,
            devicePixelRatio: 1.5,
          ),
          child: Builder(
            builder: (context) {
              final w = BrowserZoomScope.layoutWidthOf(context);
              return Text('layout=${w.round()}');
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('layout=1650'), findsOneWidget);

    inner = 1280;
    outer = 1920;
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('layout=1920'), findsOneWidget);
  });

  testWidgets('does not paint an in-app zoom chip or FittedBox', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return BrowserZoomHost(
            listenToPlatform: false,
            metricsReader: () => const BrowserZoomMetrics(
              innerWidth: 1600,
              innerHeight: 900,
              outerWidth: 1280,
              devicePixelRatio: 0.8,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const Scaffold(body: Text('PAGE')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('PAGE'), findsOneWidget);
    expect(find.byType(FittedBox), findsNothing);
    expect(find.byKey(const Key('am-zoom-percent-badge')), findsNothing);
    expect(find.text('80%'), findsNothing);
  });

  testWidgets('stub platform metrics are null (non-web)', (tester) async {
    expect(BrowserZoomPlatform.readMetrics(), isNull);
    expect(BrowserZoomPlatform.readStoredZoom(), isNull);
  });
}
