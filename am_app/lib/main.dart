import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:am_common/am_common.dart';

import 'core/di/injection.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BootTrace.configure();

  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFF1E1E2E),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              'UI error:\n${details.exceptionAsString()}\n\n${details.stack}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ),
      );

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  runApp(const ProviderScope(child: _BootstrapApp()));
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  Widget? _app;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await ConfigService.initialize();
      await configureCoreDependencies();
      await configureFeatureDependencies();
      if (!mounted) return;
      setState(() => _app = const AMApp());

      SchedulerBinding.instance.addPostFrameCallback((_) {
        BootTrace.instance.mark('first_flutter_frame');
        BootRumCollector.instance.schedulePublish(
          delay: const Duration(seconds: 6),
        );
        BootTrace.instance.scheduleSummary(
          delay: const Duration(seconds: 6),
        );
      });
    } catch (error, stackTrace) {
      debugPrint('AMApp startup failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _error = '$error\n\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF1E1E2E),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                'App failed to start:\n\n$_error',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ),
      );
    }

    if (_app == null) {
      final restoring = Uri.base.path.startsWith('/app/');
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0B1120),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF6366F1)),
                const SizedBox(height: 20),
                Text(
                  restoring
                      ? 'Restoring your session…'
                      : 'Starting AM Investment Platform…',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _app!;
  }
}
