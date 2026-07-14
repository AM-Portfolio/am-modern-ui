import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Shared book-like layout for in-app legal documents (Privacy / Terms).
class LegalDocumentPage extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<Widget> body;
  final String? relatedLabel;
  final VoidCallback? onRelatedTap;
  final VoidCallback? onBack;

  const LegalDocumentPage({
    required this.title,
    required this.lastUpdated,
    required this.body,
    this.relatedLabel,
    this.onRelatedTap,
    this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0C0A09);
    final textSoft = isDark ? const Color(0xFFD6D3D1) : const Color(0xFF44403C);
    final muted = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    final pageBg = isDark ? const Color(0xFF161B22) : const Color(0xFFFAF7F2);
    final accent = isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);
    final shortBg = accent.withValues(alpha: isDark ? 0.12 : 0.06);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Container(
        decoration: AppGlassmorphismV2.techBackground(isDark: isDark),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: pageBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                          blurRadius: isDark ? 40 : 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 32,
                    ),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 16.5,
                        height: 1.75,
                        color: textSoft,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'LEGAL DOCUMENT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Segoe UI',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.4,
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last updated · $lastUpdated',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Segoe UI',
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Divider(color: muted.withValues(alpha: 0.35)),
                          const SizedBox(height: 16),
                          ...body.map(
                            (child) => _LegalSectionTheme(
                              accent: accent,
                              textPrimary: textPrimary,
                              textSoft: textSoft,
                              muted: muted,
                              shortBg: shortBg,
                              child: child,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Divider(color: muted.withValues(alpha: 0.35)),
                          const SizedBox(height: 16),
                          Text(
                            '· · ·',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              letterSpacing: 6,
                              color: muted.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '© 2026 AM Portfolio. All rights reserved.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Segoe UI',
                              fontSize: 12,
                              color: muted,
                            ),
                          ),
                          if (relatedLabel != null && onRelatedTap != null) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: onRelatedTap,
                                child: Text(relatedLabel!),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Provides accent tokens to section helper widgets below.
class _LegalSectionTheme extends InheritedWidget {
  final Color accent;
  final Color textPrimary;
  final Color textSoft;
  final Color muted;
  final Color shortBg;

  const _LegalSectionTheme({
    required this.accent,
    required this.textPrimary,
    required this.textSoft,
    required this.muted,
    required this.shortBg,
    required super.child,
  });

  static _LegalSectionTheme of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<_LegalSectionTheme>();
    assert(theme != null, 'Legal helpers must be used inside LegalDocumentPage');
    return theme!;
  }

  @override
  bool updateShouldNotify(_LegalSectionTheme oldWidget) =>
      accent != oldWidget.accent ||
      textPrimary != oldWidget.textPrimary ||
      textSoft != oldWidget.textSoft;
}

class LegalLead extends StatelessWidget {
  final String text;
  const LegalLead(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = _LegalSectionTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 18,
          height: 1.65,
          color: t.textPrimary,
        ),
      ),
    );
  }
}

class LegalParagraph extends StatelessWidget {
  final String text;
  const LegalParagraph(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text),
    );
  }
}

class LegalHeading extends StatelessWidget {
  final String text;
  const LegalHeading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = _LegalSectionTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 2,
            margin: const EdgeInsets.only(bottom: 10),
            color: t.accent.withValues(alpha: 0.7),
          ),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class LegalSubheading extends StatelessWidget {
  final String text;
  const LegalSubheading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = _LegalSectionTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: t.textPrimary,
        ),
      ),
    );
  }
}

class LegalShort extends StatelessWidget {
  final String text;
  const LegalShort(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = _LegalSectionTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.shortBg,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
        border: Border(left: BorderSide(color: t.accent, width: 3)),
      ),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 15.5,
            fontStyle: FontStyle.italic,
            height: 1.55,
            color: t.textPrimary,
          ),
          children: [
            TextSpan(
              text: 'In Short: ',
              style: TextStyle(
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

class LegalBulletList extends StatelessWidget {
  final List<InlineSpan> items;
  const LegalBulletList(this.items, {super.key});

  /// Convenience for plain or simple bold-prefix items.
  factory LegalBulletList.strings(List<String> items) {
    return LegalBulletList(
      items.map((e) => TextSpan(text: e)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _LegalSectionTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 10),
                    child: Icon(Icons.circle, size: 6, color: t.accent),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [item]),
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 16.5,
                        height: 1.65,
                        color: t.textSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class LegalBoldItem extends TextSpan {
  LegalBoldItem(String bold, String rest)
      : super(
          children: [
            TextSpan(
              text: bold,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: rest),
          ],
        );
}

class LegalAddress extends StatelessWidget {
  final List<String> lines;
  const LegalAddress(this.lines, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Text(lines.join('\n')),
    );
  }
}
