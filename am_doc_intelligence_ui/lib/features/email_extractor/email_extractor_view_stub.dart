import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_doc_intelligence_ui/features/recent_imports_store.dart';

/// Native builds: Gmail OAuth is web-only — point users to Upload or desktop web.
class EmailExtractorView extends StatelessWidget {
  const EmailExtractorView({
    super.key,
    this.compactImportMode = false,
    this.footer,
    this.onImportCompleted,
    this.useSharedImportControls = false,
    this.sharedBrokerEmailId,
    this.passwordController,
    this.portfolioNameController,
    this.onOpenPortfolio,
    this.onOpenTrade,
  });

  /// When embedded under Import holdings.
  final bool compactImportMode;
  final Widget? footer;

  /// Unused on native — web-only mailbox extract.
  final ValueChanged<RecentImportEntry>? onImportCompleted;
  final bool useSharedImportControls;
  final String? sharedBrokerEmailId;
  final TextEditingController? passwordController;
  final TextEditingController? portfolioNameController;
  final void Function(String portfolioId, String portfolioName)? onOpenPortfolio;
  final void Function(String portfolioId, String portfolioName)? onOpenTrade;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          decoration: BoxDecoration(
            color: isDark
                ? context.colors.cardSurface.withValues(alpha: 0.6)
                : context.colors.cardSurface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  size: 36,
                  color: accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Connect Gmail on web',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mailbox import needs Google sign-in in a browser. '
                'On this device, use Upload below to add a broker PDF or Excel.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (footer == null) return card;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: footer!,
          ),
        ],
      ),
    );
  }
}
