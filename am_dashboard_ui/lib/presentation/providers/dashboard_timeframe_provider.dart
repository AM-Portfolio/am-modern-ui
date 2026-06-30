import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Back-compat alias — prefer [appTimeFrameProvider] from am_common.
final dashboardTimeFrameProvider = appTimeFrameProvider;

String dashboardTimeFrameCode(WidgetRef ref) => appTimeFrameCode(ref);

void onDashboardTimeFrameChanged(WidgetRef ref, String userId, TimeFrame tf) {
  ref.read(appTimeFrameProvider.notifier).setTimeFrame(tf);
  ref.invalidate(dashboardPerformanceProvider(userId, timeFrame: tf.code));
  ref.invalidate(moversStreamProvider(userId, timeFrame: tf.code));
  ref.invalidate(historyStreamProvider(userId, timeFrame: tf.code));
}
