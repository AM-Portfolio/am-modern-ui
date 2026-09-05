import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/core/utils/device_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mobile_time_frame_dropdown.dart';
import 'time_frame_selector.dart';

/// Display style for the global timeframe control.
enum GlobalTimeFrameVariant {
  /// Pills on desktop/tablet, dropdown on mobile.
  auto,

  /// Horizontal compact pills (web/desktop).
  pills,

  /// Compact dropdown with ~3 visible scrollable options (mobile).
  dropdown,
}

/// App-wide timeframe control — one selector for Dashboard, Portfolio, Market, and Trade.
class GlobalTimeFrameBar extends ConsumerWidget {
  const GlobalTimeFrameBar({
    super.key,
    this.variant = GlobalTimeFrameVariant.auto,
    this.availableTimeFrames,
    this.dropdownWidth = 72,
    this.primaryColor,
  });

  final GlobalTimeFrameVariant variant;
  final List<TimeFrame>? availableTimeFrames;

  /// Width of the compact mobile dropdown (default tighter than before).
  final double dropdownWidth;

  /// Accent for pills/dropdown; defaults to theme [actionPrimaryBg].
  final Color? primaryColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = primaryColor ?? context.colors.actionPrimaryBg;
    final useDropdown = switch (variant) {
      GlobalTimeFrameVariant.dropdown => true,
      GlobalTimeFrameVariant.pills => false,
      GlobalTimeFrameVariant.auto => DeviceUtils.isMobile(context),
    };

    if (useDropdown) {
      return MobileTimeFrameDropdown(
        width: dropdownWidth,
        availableTimeFrames: availableTimeFrames,
        primaryColor: accent,
      );
    }

    final timeFrame = ref.watch(appTimeFrameProvider);
    final options = availableTimeFrames ?? TimeFrame.appTimeFrames;

    return TimeFrameSelector(
      selectedTimeFrame: timeFrame,
      availableTimeFrames: options,
      compact: true,
      primaryColor: accent,
      onTimeFrameChanged: (tf) =>
          ref.read(appTimeFrameProvider.notifier).setTimeFrame(tf),
    );
  }
}
