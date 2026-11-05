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
  final Widget Function(BuildContext, int currentIndex, int itemCount)?
      customIndicator;

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
  late int _itemsSignature;

  static int _signatureFor(SwipeNavigationController controller) {
    // itemsRevision bumps on updateItems; ignore index-only notifyListeners.
    return Object.hash(controller.items.length, controller.itemsRevision);
  }

  @override
  void initState() {
    super.initState();
    _itemsSignature = _signatureFor(widget.controller);
    widget.controller.addListener(_onControllerChanged);
    _checkPageSync();
  }

  @override
  void didUpdateWidget(SwipeablePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _itemsSignature = _signatureFor(widget.controller);
      widget.controller.addListener(_onControllerChanged);
    }
    _checkPageSync();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    // Skip index-only notifies (sidebar highlight uses AnimatedBuilder).
    if (!mounted) return;
    final next = _signatureFor(widget.controller);
    if (next != _itemsSignature) {
      setState(() => _itemsSignature = next);
    }
  }

  void _checkPageSync() {
    if (widget.controller.isProgrammaticNavigation) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.controller.isProgrammaticNavigation) return;
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
        if (widget.showIndicator &&
            widget.indicatorPosition == IndicatorPosition.top)
          _buildIndicator(),
        Expanded(
          // Keep PageView stable across index notifyListeners — only itemCount
          // changes (via setState from _onControllerChanged) rebuild it.
          child: PageView.builder(
            key: ValueKey<int>(_itemsSignature),
            scrollDirection: widget.scrollDirection,
            controller: widget.controller.pageController,
            // Higher motion threshold so tiny pans do not commit a tab change.
            physics: const _DeliberatePageScrollPhysics(),
            onPageChanged: (index) {
              HapticFeedback.lightImpact();
              widget.controller.onPageChanged(index);
              widget.onPageChanged?.call(index);
            },
            itemCount: widget.controller.items.length,
            itemBuilder: (context, index) =>
                widget.controller.items[index].page,
          ),
        ),
        if (widget.showIndicator &&
            widget.indicatorPosition == IndicatorPosition.bottom)
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
      onTap: () => widget.controller.navigateTo(index, animate: false),
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

/// Page physics that ignores micro horizontal jitter before starting a drag.
class _DeliberatePageScrollPhysics extends PageScrollPhysics {
  const _DeliberatePageScrollPhysics({super.parent});

  @override
  _DeliberatePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _DeliberatePageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get dragStartDistanceMotionThreshold => 24;
}
