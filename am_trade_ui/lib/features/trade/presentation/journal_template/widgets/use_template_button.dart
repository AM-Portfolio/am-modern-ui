// Example integration code for adding template browser to journal workflow
// Add this to your journal entry creation flow

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../journal_template/pages/template_browser_page.dart';

/// Example: Add this button to your journal entry creation UI
class UseTemplateButton extends ConsumerWidget {
  const UseTemplateButton({
    required this.userId,
    this.onTemplateSelected,
    super.key,
  });

  final String userId;
  final Function(dynamic template)? onTemplateSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TemplateBrowserPage(
              userId: userId,
              onTemplateSelected: (template) {
                // Handle template selection
                onTemplateSelected?.call(template);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
      icon: const Icon(Icons.description_outlined),
      label: const Text('Use Template'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}

/// Example usage in journal entry form:
/// 
/// ```dart
/// // In your journal entry creation widget
/// UseTemplateButton(
///   userId: currentUserId,
///   onTemplateSelected: (template) {
///     // Pre-fill form with template data
///     // or navigate to template form builder
///   },
/// )
/// ```
