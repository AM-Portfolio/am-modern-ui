import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/navigation/swipe_navigation_controller.dart';


/// A swipeable PageView widget that works with SwipeNavigationController
/// Supports horizontal swiping, haptic feedback, and page indicators
class SwipeablePageView extends StatefulWidget {
  /// The navigation controller
  final SwipeNavigationController controller;

  /// Whether to show page indicator dots
  final bool showIndicator;

  /// Position of indicator (top or bottom)
  final IndicatorPosition indicatorPosition;

  /// Custom indicator widget (overrides default dots)
  final Widget Function(BuildContext, int currentIndex, int itemCount)? customIndicator;

  /// Callback when page changes
  final void Function(int index)? onPageChanged;

  /// The scroll direction of the page view
  final Axis scrollDirection;

  const SwipeablePageView({
    required this.controller,
    this.showIndicator = true,
    this.indicatorPosition = IndicatorPosition.bottom,
    this.customIndicator,
    this.onPageChanged,
    this.scrollDirection = Axis.horizontal,
    super.key,
  });

  @override
  State<SwipeablePageView> createState() => _SwipeablePageViewState();
}

class _SwipeablePageViewState extends State<SwipeablePageView> {
  @override
  void initState() {
    super.initState();
    _checkPageSync();
  }

  @override
  void didUpdateWidget(SwipeablePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkPageSync();
  }

  void _checkPageSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pageController = widget.controller.pageController;
      final targetIndex = widget.controller.currentIndex;
      if (pageController.hasClients) {
        final currentPos = pageController.page?.round();
        if (currentPos != targetIndex) {
          pageController.jumpToPage(targetIndex);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showIndicator && widget.indicatorPosition == IndicatorPosition.top)
          _buildIndicator(),

        Expanded(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              return PageView.builder(
                scrollDirection: widget.scrollDirection,
                controller: widget.controller.pageController,
                onPageChanged: (index) {
                  HapticFeedback.lightImpact();
                  widget.controller.onPageChanged(index);
                  widget.onPageChanged?.call(index);
                },
                itemCount: widget.controller.items.length,
                // Wrap each page in SingleChildScrollView for vertical scrolling
                itemBuilder: (context, index) => widget.controller.items[index].page,
              );
            },
          ),
        ),

        if (widget.showIndicator && widget.indicatorPosition == IndicatorPosition.bottom)
          _buildIndicator(),
      ],
    );
  }

  Widget _buildIndicator() {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.customIndicator != null) {
          return widget.customIndicator!(
            context,
            widget.controller.currentIndex,
            widget.controller.items.length,
          );
        }
        return _buildDefaultIndicator();
      },
    );
  }

  Widget _buildDefaultIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.controller.items.length,
          (index) => _buildDot(index, widget.controller.currentIndex == index),
        ),
      ),
    );
  }

  Widget _buildDot(int index, bool isActive) {
    final item = widget.controller.items[index];
    final color = item.accentColor;

    return GestureDetector(
      onTap: () => widget.controller.navigateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// Indicator position enum
enum IndicatorPosition {
  top,
  bottom,
}
