import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_widget_id.dart';

typedef DashboardWidgetBuilder = Widget Function(
  BuildContext context,
  WidgetRef ref,
  DashboardWidgetContext ctx,
);

class DashboardWidgetDescriptor {
  const DashboardWidgetDescriptor({
    required this.id,
    required this.title,
    required this.module,
    required this.defaultVisible,
    required this.defaultOrder,
    required this.defaultSize,
    required this.build,
  });

  final DashboardWidgetId id;
  final String title;
  final String module;
  final bool defaultVisible;
  final int defaultOrder;
  final DashboardWidgetSize defaultSize;
  final DashboardWidgetBuilder build;
}
