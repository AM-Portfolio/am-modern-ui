import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/ipo/models/ipo_calendar_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_calendar_providers.dart';
import 'package:am_market_ui/features/ipo/widgets/calendar/ipo_month_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IpoCalendarOverlay extends ConsumerWidget {
  const IpoCalendarOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(ipoCalendarUiProvider);
    final uiNotifier = ref.read(ipoCalendarUiProvider.notifier);

    if (!uiState.isOpen) {
      return const SizedBox.shrink();
    }

    final calendarAsync =
        ref.watch(ipoCalendarMonthProvider(uiState.selectedMonthKey));
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isMobile = screenWidth < AmBreakpoints.mobile;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          uiNotifier.close();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          // Semi-transparent backdrop for outside-tap dismissal
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => uiNotifier.close(),
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),

          // Floating Calendar Panel
          Positioned(
            top: isMobile ? 60 : 72,
            right: isMobile ? 12 : 24,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: isMobile ? (screenWidth - 24) : 425,
                constraints: BoxConstraints(
                  maxHeight: mediaQuery.size.height - (isMobile ? 80 : 100),
                ),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top bar: Month switcher & Close button
                      _buildTopBar(context, ref, uiState, uiNotifier),

                      const SizedBox(height: 10),

                      // Calendar content
                      calendarAsync.when(
                        data: (calendarData) {
                          if (calendarData.dataFreshness ==
                              IpoCalendarDataFreshness.unavailable) {
                            return _buildUnavailableState(
                              context,
                              ref,
                              uiState,
                            );
                          }
                          return IpoMonthGrid(
                            year: uiState.selectedMonthKey.year,
                            month: uiState.selectedMonthKey.month,
                            calendarData: calendarData,
                          );
                        },
                        loading: () => Container(
                          height: 240,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ModuleColors.market,
                          ),
                        ),
                        error: (err, _) => _buildErrorState(
                          context,
                          ref,
                          uiState,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    IpoCalendarUiState uiState,
    IpoCalendarUiNotifier uiNotifier,
  ) {
    return Row(
      children: [
        // Previous month button (visible only when viewing the next month)
        if (uiState.activeMonthIndex == 1)
          IconButton(
            onPressed: () => uiNotifier.setMonthIndex(0),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            tooltip: 'Current month',
            color: context.textPrimary,
            splashRadius: 18,
            visualDensity: VisualDensity.compact,
          )
        else
          const SizedBox(width: 32),

        // Centered Month & Year title
        Expanded(
          child: Center(
            child: Text(
              uiState.selectedMonthLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),

        // Next month button (visible only when viewing current month)
        if (uiState.activeMonthIndex == 0)
          IconButton(
            onPressed: () => uiNotifier.setMonthIndex(1),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            tooltip: 'Upcoming month',
            color: context.textPrimary,
            splashRadius: 18,
            visualDensity: VisualDensity.compact,
          )
        else
          const SizedBox(width: 32),

        const SizedBox(width: 4),

        // Close button
        InkWell(
          onTap: () => uiNotifier.close(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.borderColor, width: 0.8),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: context.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailableState(
    BuildContext context,
    WidgetRef ref,
    IpoCalendarUiState uiState,
  ) {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 32,
            color: context.colors.statusWarning,
          ),
          const SizedBox(height: 10),
          Text(
            'Calendar sync in progress',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Initial synchronization is running. Please try again shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.invalidate(
              ipoCalendarMonthProvider(uiState.selectedMonthKey),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Retry', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: ModuleColors.market,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    IpoCalendarUiState uiState,
  ) {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 32,
            color: context.colors.statusWarning,
          ),
          const SizedBox(height: 10),
          Text(
            'Unable to load calendar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.invalidate(
              ipoCalendarMonthProvider(uiState.selectedMonthKey),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Retry', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: ModuleColors.market,
            ),
          ),
        ],
      ),
    );
  }
}
