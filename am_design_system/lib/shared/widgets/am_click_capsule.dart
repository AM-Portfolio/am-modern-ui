import 'package:flutter/material.dart';

/// A reusable interactive popover capsule that opens when the [child] is clicked/tapped.
/// When [triggerOnHover] is true, the popup opens on mouse-enter and closes on mouse-exit
/// — giving users a natural discovery hint without requiring a click.
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

class _AmClickCapsuleState extends State<AmClickCapsule> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  // Hover debounce — prevents flicker when cursor briefly leaves between target and popup
  bool _isHoveringTarget = false;
  bool _isHoveringPopup = false;

  void _togglePopup() {
    _overlayController.toggle();
  }

  void _onTargetEnter() {
    _isHoveringTarget = true;
    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
  }

  void _onTargetExit() {
    _isHoveringTarget = false;
    // Small delay so moving into the popup doesn't close it
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!_isHoveringTarget && !_isHoveringPopup && _overlayController.isShowing) {
        _overlayController.hide();
      }
    });
  }

  void _onPopupEnter() {
    _isHoveringPopup = true;
  }

  void _onPopupExit() {
    _isHoveringPopup = false;
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!_isHoveringTarget && !_isHoveringPopup && _overlayController.isShowing) {
        _overlayController.hide();
      }
    });
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
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.bottomCenter,
                    child: Opacity(
                      opacity: scale.clamp(0.0, 1.0),
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
                  );
                },
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
            _overlayController.hide();
          }
        },
        child: targetChild,
      );
    }

    return targetChild;
  }
}
