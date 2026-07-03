import 'package:am_common/shared/enums/timeframe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide timeframe shared by Dashboard, Portfolio, Market, and Trade.
final appTimeFrameProvider =
    NotifierProvider<AppTimeFrameNotifier, TimeFrame>(
  AppTimeFrameNotifier.new,
);

class AppTimeFrameNotifier extends Notifier<TimeFrame> {
  @override
  TimeFrame build() => TimeFrame.oneDay;

  void setTimeFrame(TimeFrame timeFrame) => state = timeFrame;
}

String appTimeFrameCode(WidgetRef ref) =>
    ref.watch(appTimeFrameProvider).code;
