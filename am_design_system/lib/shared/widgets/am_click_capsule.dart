import 'package:flutter/material.dart';

/// A reusable interactive popover capsule that opens when the [child] is clicked/tapped.
/// The [popupContent] is rendered in a floating overlay above the child.
class AmClickCapsule extends StatefulWidget {
  final Widget child;
  final Widget popupContent;
  final Color backgroundColor;

  const AmClickCapsule({
    Key? key,
    required this.child,
    required this.popupContent,
    this.backgroundColor = const Color(0xFF1E1E32),
  }) : super(key: key);

  @override
  State<AmClickCapsule> createState() => _AmClickCapsuleState();
}

class _AmClickCapsuleState extends State<AmClickCapsule> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  void _togglePopup() {
    _overlayController.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: this,
      onTapOutside: (event) {
        if (_overlayController.isShowing) {
          _overlayController.hide();
        }
      },
      child: CompositedTransformTarget(
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
                offset: const Offset(0, -10), // Float slightly above the text
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
                    );
                  },
                ),
              ),
            );
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _togglePopup,
              behavior: HitTestBehavior.opaque,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
