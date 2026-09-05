import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';

import '../../data/models/security_event_model.dart';

class SecurityAlertBanner extends StatelessWidget {
  const SecurityAlertBanner({
    required this.event,
    required this.onAcknowledge,
    required this.onReviewSessions,
    super.key,
  });

  final SecurityEventModel event;
  final VoidCallback onAcknowledge;
  final VoidCallback onReviewSessions;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: context.colors.statusWarning.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: context.colors.statusWarning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New sign-in detected',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.locationLabel.isEmpty
                        ? 'Review your active sessions'
                        : event.locationLabel,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: onReviewSessions,
                        child: const Text('Review sessions'),
                      ),
                      TextButton(
                        onPressed: onAcknowledge,
                        child: const Text('This was me'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onAcknowledge,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
