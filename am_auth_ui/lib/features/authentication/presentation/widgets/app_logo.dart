import 'package:flutter/material.dart';

/// A modern logo widget for AM Investment using the brand logo asset
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 60, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'lib/assets/images/app_logo.png',
        package: 'am_design_system',
        width: size * 1.8,  // Adjusted scaling for aspect ratio
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// A full logo with text for AM Investment using the brand logo asset
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
    // The logo asset already contains the "ASRAX" and "Financial Intelligence" text
    return AppLogo(size: logoSize);
  }
}
