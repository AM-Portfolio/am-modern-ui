import 'dart:async';
import 'package:flutter/material.dart';

/// A reusable interactive popover capsule that opens when the [child] is clicked/tapped.
/// When [triggerOnHover] is true, the popup opens on mouse-enter and closes on mouse-exit
/// giving users a natural discovery hint without requiring a click.
/// The [popupContent] is rendered in a floating overlay above the child.
class AmClickCapsule extends StatefulWidget {
  final Widget child;
  final Widget popupContent;
  final Color backgroundColor;

  /// When true, the popup opens on hover (mouse enter) and closes when the
  /// mouse leaves the combined area of the target + popup overlay.
  /// Defaults to false (click-to-open behaviour).
  final bool triggerOnHover;

  const AmClickCapsule({
    Key? key,
    required this.child,
    required this.popupContent,
    this.backgroundColor = const Color(0xFF1E1E32),
    this.triggerOnHover = false,
  }) : super(key: key);

  @override
  State<AmClickCapsule> createState() => _AmClickCapsuleState();
}

class _AmClickCapsuleState extends State<AmClickCapsule>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  Timer? _hideTimer;

  bool _isHoveringTarget = false;
  bool _isHoveringPopup = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        if (_overlayController.isShowing) {
          _overlayController.hide();
        }
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _show() {
    _hideTimer?.cancel();
    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
    _animController.forward();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      if (!_isHoveringTarget && !_isHoveringPopup) {
        _animController.reverse();
      }
    });
  }

  void _togglePopup() {
    if (_overlayController.isShowing) {
      _animController.reverse();
    } else {
      _show();
    }
  }

  void _onTargetEnter() {
    _isHoveringTarget = true;
    _show();
  }

  void _onTargetExit() {
    _isHoveringTarget = false;
    _scheduleHide();
  }

  void _onPopupEnter() {
    _isHoveringPopup = true;
    _hideTimer?.cancel();
  }

  void _onPopupExit() {
    _isHoveringPopup = false;
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final targetChild = CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (BuildContext context) {
          return Positioned(
            left: 0,
            top: 0,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, -10),
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      alignment: Alignment.bottomCenter,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: TapRegion(
                      groupId: this,
                      child: MouseRegion(
                        onEnter: widget.triggerOnHover ? (_) => _onPopupEnter() : null,
                        onExit: widget.triggerOnHover ? (_) => _onPopupExit() : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.backgroundColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              )
                            ],
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: widget.popupContent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: widget.triggerOnHover ? (_) => _onTargetEnter() : null,
          onExit: widget.triggerOnHover ? (_) => _onTargetExit() : null,
          child: GestureDetector(
            onTap: widget.triggerOnHover ? null : _togglePopup,
            behavior: HitTestBehavior.opaque,
            child: widget.child,
          ),
        ),
      ),
    );

    // In click mode keep TapRegion so tapping outside closes the popup
    if (!widget.triggerOnHover) {
      return TapRegion(
        groupId: this,
        onTapOutside: (event) {
          if (_overlayController.isShowing) {
            _animController.reverse();
          }
        },
        child: targetChild,
      );
    }

    return targetChild;
  }
}
