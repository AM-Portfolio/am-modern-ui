import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../../journal_template/widgets/create_template_dialog.dart';

/// Full-screen Create Custom Template for mobile.
class JournalCreateTemplateMobilePage extends StatelessWidget {
  const JournalCreateTemplateMobilePage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const JournalCreateTemplateMobilePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Template'),
      ),
      body: const SafeArea(
        child: CreateTemplateDialog(asPage: true),
      ),
    );
  }
}
