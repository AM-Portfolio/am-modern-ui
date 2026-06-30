import 'package:am_common/am_common.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'time_frame_selector.dart';

/// App-wide timeframe control — one selector for Dashboard, Portfolio, Market, and Trade.
class GlobalTimeFrameBar extends ConsumerWidget {
  const GlobalTimeFrameBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFrame = ref.watch(appTimeFrameProvider);

    return TimeFrameSelector(
      selectedTimeFrame: timeFrame,
      availableTimeFrames: TimeFrame.appTimeFrames,
      compact: true,
      primaryColor: AppColors.primary,
      onTimeFrameChanged: (tf) =>
          ref.read(appTimeFrameProvider.notifier).setTimeFrame(tf),
    );
  }
}
