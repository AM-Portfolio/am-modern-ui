import 'package:flutter/material.dart';

/// A modern logo widget for AM Investment
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 60, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Theme.of(context).primaryColor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [logoColor.withOpacity(0.8), logoColor],
              ),
            ),
          ),

          // Inner circle
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),

          // AM text
          Text(
            'AM',
            style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
              color: logoColor,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A full logo with text for AM Investment
class AppLogoWithText extends StatelessWidget {
  const AppLogoWithText({
    super.key,
    this.logoSize = 60,
    this.fontSize = 24,
    this.color,
    this.vertical = false,
  });
  final double logoSize;
  final double fontSize;
  final Color? color;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Theme.of(context).primaryColor;

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLogo(size: logoSize, color: textColor),
          const SizedBox(height: 12),
          Text(
            'AM Investment',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize, color: textColor),
        const SizedBox(width: 12),
        Text(
          'AM Investment',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
