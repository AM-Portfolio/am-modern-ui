import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_doc_intelligence_ui/features/document_processor/document_processor_view.dart';
import 'package:am_doc_intelligence_ui/features/email_extractor/email_extractor_view.dart';
import 'package:am_doc_intelligence_ui/features/import_holdings_info_rail.dart';
import 'package:am_doc_intelligence_ui/features/recent_imports_store.dart';
import 'package:am_doc_intelligence_ui/services/api_service.dart';

/// Import holdings — **mobile** uses Portfolio/Trade section pills (Email | Upload);
/// **web/desktop** keeps title + segmented toggle, no Email/Upload sidebar.
class DocIntelligenceScreen extends StatefulWidget {
  const DocIntelligenceScreen({
    required this.userId,
    this.initialTab = 'mailbox',
    this.onTabChanged,
    super.key,
  });

  final String userId;
  /// Legacy: `email-extractor` / `doc-processor` / `mailbox` / `upload`.
  final String initialTab;
  final ValueChanged<String>? onTabChanged;

  @override
  State<DocIntelligenceScreen> createState() => _DocIntelligenceScreenState();
}

enum _ImportMode { mailbox, upload }

class _DocIntelligenceScreenState extends State<DocIntelligenceScreen> {
  late _ImportMode _mode;
  List<RecentImportEntry> _recentEntries = const [];

  /// Same cutoff as [UnifiedSidebarScaffold.tabletBreakpoint].
  static const double _mobileShellMax = 1100;

  static _ImportMode _modeFromSlug(String slug) {
    switch (slug) {
      case 'doc-processor':
      case 'upload':
        return _ImportMode.upload;
      case 'email-extractor':
      case 'mailbox':
      default:
        if (!kIsWeb) return _ImportMode.upload;
        return _ImportMode.mailbox;
    }
  }

  static String _slugForMode(_ImportMode mode) =>
      mode == _ImportMode.upload ? 'upload' : 'mailbox';

  @override
  void initState() {
    super.initState();
    _mode = _modeFromSlug(widget.initialTab);
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final items = await RecentImportsStore.instance.load(widget.userId);
    if (!mounted) return;
    setState(() => _recentEntries = items);
  }

  @override
  void didUpdateWidget(covariant DocIntelligenceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      final next = _modeFromSlug(widget.initialTab);
      if (next != _mode) setState(() => _mode = next);
    }
    if (oldWidget.userId != widget.userId) {
      _loadRecent();
    }
  }

  void _setMode(_ImportMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    widget.onTabChanged?.call(_slugForMode(mode));
  }

  Future<void> _prependRecent(RecentImportEntry entry) async {
    final next =
        await RecentImportsStore.instance.prepend(widget.userId, entry);
    if (!mounted) return;
    setState(() => _recentEntries = next);
  }

  List<SecondarySidebarItem> _mobileNavItems() {
    final accent = ModuleColors.analytics;
    return [
      SecondarySidebarItem(
        title: 'Email',
        icon: Icons.mail_outline,
        accentColor: accent,
        isSelected: _mode == _ImportMode.mailbox,
        onTap: () => _setMode(_ImportMode.mailbox),
      ),
      SecondarySidebarItem(
        title: 'Upload',
        icon: Icons.cloud_upload_outlined,
        accentColor: accent,
        isSelected: _mode == _ImportMode.upload,
        onTap: () => _setMode(_ImportMode.upload),
      ),
    ];
  }

  Widget _mainPanel() {
    return KeyedSubtree(
      key: ValueKey(
        'import_main_${apiProvider.environment}_${_mode.name}',
      ),
      child: _mode == _ImportMode.upload
          ? DocumentProcessorView(
              embeddedInImportShell: true,
              onImportCompleted: _prependRecent,
            )
          : EmailExtractorView(
              compactImportMode: true,
              onImportCompleted: _prependRecent,
            ),
    );
  }

  // ─── Mobile: section pills (no page title) ───────────────────────────

  Widget _mobileBody() {
    const gap = 8.0;
    const inset = 16.0;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        inset,
        4,
        inset,
        PlatformConstants.globalBottomNavReserve(context) + 12,
      ),
      children: [
        const ImportPrivacyCard(isCompact: true),
        const SizedBox(height: gap),
        _mainPanel(),
        const SizedBox(height: gap),
        ImportRecentCard(
          isCompact: true,
          entries: _recentEntries,
        ),
        const SizedBox(height: gap),
        const ImportCapabilitiesCard(isCompact: true),
      ],
    );
  }

  Widget _buildMobileShell() {
    return UnifiedSidebarScaffold(
      title: 'Import holdings',
      icon: Icons.cloud_download_outlined,
      accentColor: ModuleColors.analytics,
      showAppBarOnMobile: false,
      showMobileMenuButton: false,
      showModuleBottomNavigation: false,
      autoHideMobileTabsOnScroll: false,
      enableMobileSearch: true,
      items: _mobileNavItems(),
      body: _mobileBody(),
    );
  }

  // ─── Web: title + Email|Upload toggle, no secondary sidebar ──────────

  Widget _modeSegment({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accent = ModuleColors.analytics;
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
            ? Colors.white
            : const Color(0xFF0B0D0F);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: selected ? accent : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: selected ? onAccent : muted),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? onAccent : muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _webModeToggle() {
    final border = Theme.of(context).colorScheme.outlineVariant;
    final fill = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeSegment(
            label: 'Email',
            icon: Icons.mail_outline,
            selected: _mode == _ImportMode.mailbox,
            onTap: () => _setMode(_ImportMode.mailbox),
          ),
          const SizedBox(width: 4),
          _modeSegment(
            label: 'Upload',
            icon: Icons.cloud_upload_outlined,
            selected: _mode == _ImportMode.upload,
            onTap: () => _setMode(_ImportMode.upload),
          ),
        ],
      ),
    );
  }

  Widget _webHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: ModuleColors.analytics,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Import holdings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
            ),
          ),
          _webModeToggle(),
        ],
      ),
    );
  }

  Widget _webBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(child: _mainPanel()),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: ImportHoldingsInfoRail(
                isCompact: true,
                recentEntries: _recentEntries,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebShell() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _webHeader(),
          Expanded(child: _webBody()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < _mobileShellMax;
        if (mobile) return _buildMobileShell();
        return _buildWebShell();
      },
    );
  }
}
