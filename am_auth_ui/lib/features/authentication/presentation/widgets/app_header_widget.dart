import 'package:flutter/material.dart';

/// App header widget showing app icon and title
/// Only visible on mobile/compact screens
class AppHeaderWidget extends StatelessWidget {
  final String appName;
  final IconData appIcon;
  final bool isCompact;
  
  const AppHeaderWidget({
    super.key,
    required this.appName,
    required this.appIcon,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    // Only show on compact/mobile screens
    if (!isCompact) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            appIcon,
            size: 32,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            appName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
