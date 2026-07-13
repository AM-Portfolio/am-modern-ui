import 'package:am_common/am_common.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/shared/widgets/inputs/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact mobile timeframe dropdown bound to [appTimeFrameProvider].
///
/// Shows ~3 options at a time; remaining options scroll.
class MobileTimeFrameDropdown extends ConsumerWidget {
  const MobileTimeFrameDropdown({
    super.key,
    this.width = 84,
    this.availableTimeFrames,
  });

  final double width;
  final List<TimeFrame>? availableTimeFrames;

  /// Height that fits approximately 3 menu rows.
  static const double menuMaxHeightForThreeItems = 148;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFrame = ref.watch(appTimeFrameProvider);
    final options = availableTimeFrames ?? TimeFrame.appTimeFrames;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selected = options.contains(timeFrame) ? timeFrame : options.first;

    return SizedBox(
      width: width,
      child: CustomDropdown<TimeFrame>(
        value: selected,
        height: 36,
        isExpanded: true,
        fontSize: 13,
        iconSize: 18,
        borderRadius: 10,
        menuMaxHeight: menuMaxHeightForThreeItems,
        primaryColor: AppColors.primary,
        backgroundColor:
            isDark ? Colors.white.withValues(alpha: 0.06) : null,
        borderColor: isDark ? Colors.white.withValues(alpha: 0.1) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        items: options
            .map((tf) => tf.toSimpleDropdownItem(text: tf.code, fontSize: 13))
            .toList(),
        onChanged: (tf) {
          if (tf != null) {
            ref.read(appTimeFrameProvider.notifier).setTimeFrame(tf);
          }
        },
      ),
    );
  }
}
