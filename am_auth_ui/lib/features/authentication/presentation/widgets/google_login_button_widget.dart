import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import '../cubit/auth_cubit.dart';

/// Google login button widget matching image (1).png
class GoogleLoginButtonWidget extends StatefulWidget {
  final bool isLoading;

  const GoogleLoginButtonWidget({
    super.key,
    this.isLoading = false,
  });

  @override
  State<GoogleLoginButtonWidget> createState() => _GoogleLoginButtonWidgetState();
}

class _GoogleLoginButtonWidgetState extends State<GoogleLoginButtonWidget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isLoading;

    final baseBgColor = context.colors.surface;
    final borderColor = context.colors.border;
    final textColor = context.colors.textPrimary;

    return MouseRegion(
      onEnter: (_) {
        if (enabled) setState(() => _isHovering = true);
      },
      onExit: (_) {
        if (enabled) setState(() => _isHovering = false);
      },
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: baseBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: 1.2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: enabled
                      ? () {
                          context.read<AuthCubit>().loginWithGoogle();
                        }
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(textColor),
                          ),
                        )
                      else
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CustomPaint(
                            painter: _GoogleGLogoPainter(),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Text(
                        widget.isLoading
                            ? 'Signing in…'
                            : 'Continue with Google',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius * 0.82);

    final strokeW = radius * 0.38;

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    // Draw Google 4-color G arcs
    canvas.drawArc(rect, -0.4, 1.6, false, bluePaint);
    canvas.drawArc(rect, 1.2, 1.3, false, greenPaint);
    canvas.drawArc(rect, 2.5, 1.2, false, yellowPaint);
    canvas.drawArc(rect, 3.7, 1.4, false, redPaint);

    // Horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(center.dx, center.dy - (strokeW / 2), center.dx + (radius * 0.8), center.dy + (strokeW / 2)),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
