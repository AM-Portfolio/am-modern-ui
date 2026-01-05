import 'package:flutter/material.dart';

/// Reusable dialog header with icon, title, and close button
class DialogHeader extends StatelessWidget {
  const DialogHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
    this.onClose,
    this.iconColor = const Color(0xFFFF9800),
    this.iconGradient,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onClose;
  final Color iconColor;
  final Gradient? iconGradient;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = MediaQuery.of(context).size.width;
      final iconSize = screenWidth * 0.08;
      final titleFontSize = screenWidth * 0.04;
      final subtitleFontSize = screenWidth * 0.025;

      return Row(
        children: [
          Container(
            width: iconSize.clamp(40.0, 60.0),
            height: iconSize.clamp(40.0, 60.0),
            decoration: BoxDecoration(
              gradient:
                  iconGradient ??
                  LinearGradient(
                    colors: [iconColor, iconColor.withOpacity(0.8)],
                  ),
              borderRadius: BorderRadius.circular(
                iconSize.clamp(40.0, 60.0) * 0.33,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: (iconSize * 0.5).clamp(20.0, 30.0),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize.clamp(18.0, 28.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: subtitleFontSize.clamp(12.0, 16.0),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              iconSize: (iconSize * 0.5).clamp(20.0, 28.0),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      );
    },
  );
}
