import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class VerticalScrollNavigator extends StatefulWidget {
  final Widget child;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;

  const VerticalScrollNavigator({
    super.key,
    required this.child,
    this.onNextPage,
    this.onPreviousPage,
  });

  @override
  State<VerticalScrollNavigator> createState() => _VerticalScrollNavigatorState();
}

class _VerticalScrollNavigatorState extends State<VerticalScrollNavigator> with AutomaticKeepAliveClientMixin {
  bool _isNavigating = false;
  bool _isAtTop = true;
  bool _isAtBottom = false;

  @override
  bool get wantKeepAlive => true;

  void _handleNavigation(bool isNext) async {
    print('[VerticalScrollNavigator] 🚀 _handleNavigation called: isNext=$isNext, isNavigating=$_isNavigating');
    if (_isNavigating) {
      print('[VerticalScrollNavigator] ⏸️ Navigation blocked - already navigating');
      return;
    }
    if (isNext && widget.onNextPage == null) {
      print('[VerticalScrollNavigator] ⚠️  onNextPage callback is null');
      return;
    }
    if (!isNext && widget.onPreviousPage == null) {
      print('[VerticalScrollNavigator] ⚠️ onPreviousPage callback is null');
      return;
    }

    setState(() => _isNavigating = true);
    
    if (isNext) {
       print('[VerticalScrollNavigator] ✅ Calling onNextPage callback');
       widget.onNextPage?.call();
    } else {
       print('[VerticalScrollNavigator] ✅ Calling onPreviousPage callback');
       widget.onPreviousPage?.call();
    }

    // Debounce navigation to prevent rapid firing
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isNavigating = false);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    print('[VerticalScrollNavigator] 📜 Scroll notification received: ${notification.runtimeType}');
    if (notification.metrics.axis != Axis.vertical) {
      print('[VerticalScrollNavigator] ⚠️ Ignoring non-vertical scroll');
      return false;
    }

    // Update state tracking
    if (notification is ScrollUpdateNotification) {
      // Use a small tolerance
      final metrics = notification.metrics;
      _isAtTop = metrics.pixels <= metrics.minScrollExtent;
      _isAtBottom = metrics.pixels >= metrics.maxScrollExtent;
      print('[VerticalScrollNavigator] 📊 Scroll Update: pixels=${metrics.pixels.toStringAsFixed(1)}, min=${metrics.minScrollExtent}, max=${metrics.maxScrollExtent.toStringAsFixed(1)}, atTop=$_isAtTop, atBottom=$_isAtBottom');
    }

    // Handle Overscroll (Mobile/Touch)
    if (notification is OverscrollNotification) {
      print('[VerticalScrollNavigator] 🔄 Overscroll detected: ${notification.overscroll}, atTop=$_isAtTop, atBottom=$_isAtBottom');
      if (notification.overscroll > 0 && _isAtBottom) {
        print('[VerticalScrollNavigator] ➡️ Triggering NEXT page');
        _handleNavigation(true); // Next
      } else if (notification.overscroll < 0 && _isAtTop) {
        print('[VerticalScrollNavigator] ⬅️ Triggering PREVIOUS page');
        _handleNavigation(false); // Previous
      }
    }
    return false;
  }

  void _onPointerScroll(PointerScrollEvent event) {
    print('[VerticalScrollNavigator] 🖱️ Pointer scroll: dy=${event.scrollDelta.dy}, atTop=$_isAtTop, atBottom=$_isAtBottom');
    // Handle Mouse Wheel (Desktop)
    if (event.scrollDelta.dy > 0 && _isAtBottom) {
      // Scrolling down while at bottom
      print('[VerticalScrollNavigator] ➡️ Mouse wheel down at bottom - Triggering NEXT page');
      _handleNavigation(true);
    } else if (event.scrollDelta.dy < 0 && _isAtTop) {
      // Scrolling up while at top
      print('[VerticalScrollNavigator] ⬅️ Mouse wheel up at top - Triggering PREVIOUS page');
      _handleNavigation(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print('[VerticalScrollNavigator] 🏗️ build() called - Widget is being rendered!');
    return Listener(
      onPointerSignal: (event) {
        print('[VerticalScrollNavigator] 👆 PointerSignal event: ${event.runtimeType}');
        if (event is PointerScrollEvent) {
          _onPointerScroll(event);
        }
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: widget.child,
      ),
    );
  }
}
