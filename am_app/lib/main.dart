import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:am_common/am_common.dart';

import 'core/di/injection.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    usePathUrlStrategy();
  }
  
  // Initialize ConfigService (required by am_design_system)
  await ConfigService.initialize();
  
  // Initialize dependency injection
  await configureDependencies();
  
  runApp(
    const ProviderScope(
      child: AMApp(),
    ),
  );
}
