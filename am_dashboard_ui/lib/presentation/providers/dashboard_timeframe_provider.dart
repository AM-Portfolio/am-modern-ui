import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardTimeFrameProvider =
    NotifierProvider<DashboardTimeFrameNotifier, TimeFrame>(
  DashboardTimeFrameNotifier.new,
);

class DashboardTimeFrameNotifier extends Notifier<TimeFrame> {
  @override
  TimeFrame build() => TimeFrame.oneDay;

  void setTimeFrame(TimeFrame timeFrame) => state = timeFrame;
}

String dashboardTimeFrameCode(WidgetRef ref) =>
    ref.watch(dashboardTimeFrameProvider).code;

void onDashboardTimeFrameChanged(WidgetRef ref, String userId, TimeFrame tf) {
  ref.read(dashboardTimeFrameProvider.notifier).setTimeFrame(tf);
  ref.invalidate(dashboardPerformanceProvider(userId, timeFrame: tf.code));
  ref.invalidate(moversStreamProvider(userId, timeFrame: tf.code));
  ref.invalidate(historyStreamProvider(userId, timeFrame: tf.code));
}
