import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_spacing.dart';

/// # Submarine reveal motion
///
/// Wrap a control in [AmSubmarineReveal] to keep its layout slot while it
/// dives below the slot edge or surfaces back into place. Diving tilts the
/// right edge down; surfacing leads with the right edge up and settles flat.
/// The child owns its colors and styling; [accentColor] only colors the brief
/// waterline. Use this around controls in compact navigation rows, usually at
/// the mobile breakpoint.
///
/// The [withSubmarineReveal] extension is the concise opt-in for any widget:
///
/// ```dart
/// final expiryControl = FoExpiryPicker(...).withSubmarineReveal(
///   visible: selectedTab == 0,
///   height: 36,
///   accentColor: ModuleColors.market,
/// );
/// ```
///
/// The equivalent explicit composition is:
///
/// ```dart
/// AmSubmarineReveal(
///   visible: selectedTab == 0,
///   height: 36,
///   accentColor: ModuleColors.market,
///   child: FoExpiryPicker(...),
/// )
/// ```
class AmSubmarineReveal extends StatefulWidget {
  const AmSubmarineReveal({
    super.key,
    required this.visible,
    required this.height,
    required this.child,
    this.accentColor,
    this.tiltAngle = 7,
  });

  /// Whether the child should be surfaced and interactive.
  final bool visible;

  /// The fixed height reserved for the control while it is hidden or visible.
  final double height;

  /// The widget whose appearance and theme remain owned by the calling module.
  final Widget child;

  /// Optional module accent for the short waterline effect.
  final Color? accentColor;

  /// Maximum tilt, in degrees. Positive tilt sends the right edge down on dive.
  final double tiltAngle;

  @override
  State<AmSubmarineReveal> createState() => _AmSubmarineRevealState();
}

/// Adds submarine reveal behavior to any widget through composition.
///
/// ```dart
/// const Icon(Icons.calendar_today).withSubmarineReveal(
///   visible: isOptionChainSelected,
///   height: 36,
///   accentColor: ModuleColors.market,
/// )
/// ```
extension AmSubmarineRevealWidgetExtension on Widget {
  Widget withSubmarineReveal({
    Key? key,
    required bool visible,
    required double height,
    Color? accentColor,
    double tiltAngle = 7,
  }) {
    return AmSubmarineReveal(
      key: key,
      visible: visible,
      height: height,
      accentColor: accentColor,
      tiltAngle: tiltAngle,
      child: this,
    );
  }
}

class _AmSubmarineRevealState extends State<AmSubmarineReveal>
    with SingleTickerProviderStateMixin {
  static const double _hiddenTravel = 1.08;

  late final AnimationController _controller;
  late _RevealFrame _fromFrame;
  late _RevealFrame _toFrame;
  late bool _isSurfacing;

  @override
  void initState() {
    super.initState();
    _fromFrame = _frameForVisibility(widget.visible);
    _toFrame = _fromFrame;
    _isSurfacing = widget.visible;
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant AmSubmarineReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;

    // Start from the exact frame currently on screen. Rapid tab changes can
    // redirect the motion without snapping to either endpoint first.
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _fromFrame = disableAnimations ? _toFrame : _frameAt(_controller.value);
    _toFrame = _frameForVisibility(widget.visible);
    _isSurfacing = widget.visible;
    if (disableAnimations) {
      _controller.value = 1;
      return;
    }
    _controller.duration =
        widget.visible ? AppAnimations.slow : AppAnimations.medium;
    _controller.forward(from: 0);
  }

  _RevealFrame _frameForVisibility(bool visible) => _RevealFrame(
        travel: visible ? 0 : _hiddenTravel,
        rotation: 0,
        scale: visible ? 1 : 0.88,
        opacity: visible ? 1 : 0,
      );

  _RevealFrame _frameAt(double time) {
    final progress = time.clamp(0.0, 1.0).toDouble();
    final travelCurve = _isSurfacing
        ? Curves.easeOutCubic.transform(progress)
        : Curves.easeInCubic.transform(progress);
    final opacityCurve = Curves.easeInOutCubic.transform(progress);
    final tiltPulse = math.sin(math.pi * progress) *
        widget.tiltAngle *
        math.pi /
        180 *
        (_isSurfacing ? -1 : 1);

    return _RevealFrame(
      travel: _lerp(_fromFrame.travel, _toFrame.travel, travelCurve),
      rotation: _lerp(
            _fromFrame.rotation,
            _toFrame.rotation,
            travelCurve,
          ) +
          tiltPulse,
      scale: _lerp(_fromFrame.scale, _toFrame.scale, travelCurve),
      opacity: _lerp(_fromFrame.opacity, _toFrame.opacity, opacityCurve),
    );
  }

  double _lerp(double begin, double end, double t) => begin + (end - begin) * t;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? Theme.of(context).colorScheme.primary;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return SizedBox(
      height: widget.height,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          child: IgnorePointer(
            ignoring: !widget.visible,
            child: ExcludeSemantics(
              excluding: !widget.visible,
              child: FocusScope(
                canRequestFocus: widget.visible,
                descendantsAreFocusable: widget.visible,
                child: widget.child,
              ),
            ),
          ),
          builder: (context, child) {
            final frame =
                disableAnimations ? _toFrame : _frameAt(_controller.value);
            final wake = disableAnimations
                ? 0.0
                : math
                    .sin(math.pi * _controller.value)
                    .clamp(0.0, 1.0)
                    .toDouble();

            return Stack(
              fit: StackFit.expand,
              alignment: Alignment.bottomCenter,
              children: [
                Transform.translate(
                  offset: Offset(0, widget.height * frame.travel),
                  child: Transform.rotate(
                    angle: frame.rotation,
                    child: Transform.scale(
                      scale: frame.scale,
                      child: Opacity(opacity: frame.opacity, child: child),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: wake * 0.6,
                      child: Transform.scale(
                        scaleX: 0.7 + 0.3 * (1 - wake),
                        child: SizedBox(
                          height: AppSpacing.xxs,
                          child: ColoredBox(color: accent),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RevealFrame {
  const _RevealFrame({
    required this.travel,
    required this.rotation,
    required this.scale,
    required this.opacity,
  });

  final double travel;
  final double rotation;
  final double scale;
  final double opacity;
}
