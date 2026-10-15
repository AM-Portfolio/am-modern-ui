import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_doc_intelligence_ui/features/document_processor/document_processor_view.dart';
import 'package:am_doc_intelligence_ui/features/email_extractor/email_extractor_view.dart';
import 'package:am_doc_intelligence_ui/features/import_holdings_info_rail.dart';
import 'package:am_doc_intelligence_ui/features/import_holdings_shared_controls.dart';
import 'package:am_doc_intelligence_ui/features/recent_imports_store.dart';
import 'package:am_doc_intelligence_ui/services/api_service.dart';

enum _ImportSource { email, upload }

/// Import holdings — tab card (Email | Document upload) + mode-specific fields.
class DocIntelligenceScreen extends StatefulWidget {
  const DocIntelligenceScreen({
    required this.userId,
    this.initialTab = 'mailbox',
    this.onTabChanged,
    this.onOpenPortfolio,
    this.onOpenTrade,
    super.key,
  });

  final String userId;
  final String initialTab;
  final ValueChanged<String>? onTabChanged;
  final void Function(String portfolioId, String portfolioName)? onOpenPortfolio;
  final void Function(String portfolioId, String portfolioName)? onOpenTrade;

  @override
  State<DocIntelligenceScreen> createState() => _DocIntelligenceScreenState();
}

class _DocIntelligenceScreenState extends State<DocIntelligenceScreen> {
  List<RecentImportEntry> _recentEntries = const [];
  String? _selectedBrokerKey;
  String? _documentType;
  late _ImportSource _source;
  final TextEditingController _portfolioNameController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _autoPortfolioName;

  static const double _mobileShellMax = 1100;

  static _ImportSource _sourceFromSlug(String slug) {
    switch (slug) {
      case 'doc-processor':
      case 'upload':
        return _ImportSource.upload;
      case 'email-extractor':
      case 'mailbox':
      default:
        if (!kIsWeb) return _ImportSource.upload;
        return _ImportSource.email;
    }
  }

  static String _slugForSource(_ImportSource source) =>
      source == _ImportSource.upload ? 'upload' : 'mailbox';

  @override
  void initState() {
    super.initState();
    _source = _sourceFromSlug(widget.initialTab);
    _loadRecent();
  }

  @override
  void dispose() {
    _portfolioNameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      final next = _sourceFromSlug(widget.initialTab);
      if (next != _source) setState(() => _source = next);
    }
    if (oldWidget.userId != widget.userId) {
      _loadRecent();
    }
  }

  Future<void> _prependRecent(RecentImportEntry entry) async {
    final next =
        await RecentImportsStore.instance.prepend(widget.userId, entry);
    if (!mounted) return;
    setState(() => _recentEntries = next);
  }

  void _setSource(_ImportSource source) {
    if (_source == source) return;
    setState(() => _source = source);
    widget.onTabChanged?.call(_slugForSource(source));
  }

  void _onBrokerSelected(String key) {
    final brokerDefault = brokerKeyDisplayName(key);
    final current = _portfolioNameController.text.trim();
    final shouldReplaceName = current.isEmpty ||
        current == (_autoPortfolioName ?? '') ||
        (_selectedBrokerKey != null &&
            current == brokerKeyDisplayName(_selectedBrokerKey));
    setState(() {
      _selectedBrokerKey = key;
      _documentType = null;
      if (shouldReplaceName) {
        _portfolioNameController.text = brokerDefault;
        _autoPortfolioName = brokerDefault;
      }
    });
  }

  Widget _sourceTabs() {
    final accent = Theme.of(context).colorScheme.primary;
    final border = Theme.of(context).colorScheme.outlineVariant;
    final fill = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surface;

    Widget tab({
      required String label,
      required IconData icon,
      required _ImportSource source,
    }) {
      final selected = _source == source;
      final onAccent =
          ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
              ? Colors.white
              : const Color(0xFF0B0D0F);
      final muted = Theme.of(context).colorScheme.onSurfaceVariant;
      return Expanded(
        child: Material(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => _setSource(source),
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              tab(
                label: 'Email',
                icon: Icons.mail_outline,
                source: _ImportSource.email,
              ),
              const SizedBox(width: 4),
              tab(
                label: 'Document upload',
                icon: Icons.cloud_upload_outlined,
                source: _ImportSource.upload,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sharedControls() {
    final brokerHint = _selectedBrokerKey != null
        ? brokerKeyDisplayName(_selectedBrokerKey)
        : null;
    final isEmail = _source == _ImportSource.email;
    return ImportHoldingsSharedControls(
      selectedBrokerKey: _selectedBrokerKey,
      onBrokerSelected: _onBrokerSelected,
      portfolioNameController: _portfolioNameController,
      passwordController: _passwordController,
      documentType: _documentType,
      onDocumentTypeChanged: (v) => setState(() {
        _documentType =
            (v == null || v.isEmpty || v == kImportDocTypeAuto) ? null : v;
      }),
      portfolioNameHint: brokerHint != null
          ? 'Optional — defaults to $brokerHint'
          : 'Optional — defaults to broker name',
      showPassword: true,
      passwordRequiredHint: isEmail,
      showDocumentType: !isEmail,
      documentTypeOptional: false,
      useSimpleDocTypePicker: true,
    );
  }

  Widget _modeBodies() {
    // Keep both panes mounted (no health re-check on tab switch) but only the
    // active one contributes height — IndexedStack used the taller pane and
    // left a large empty gap above Recent imports on mobile.
    final email = _source == _ImportSource.email;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Visibility(
          visible: email,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: false,
          child: EmailExtractorView(
            compactImportMode: true,
            useSharedImportControls: true,
            sharedBrokerEmailId: brokerKeyToEmailId(_selectedBrokerKey),
            passwordController: _passwordController,
            portfolioNameController: _portfolioNameController,
            onImportCompleted: _prependRecent,
            onOpenPortfolio: widget.onOpenPortfolio,
            onOpenTrade: widget.onOpenTrade,
          ),
        ),
        Visibility(
          visible: !email,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: false,
          child: DocumentProcessorView(
            embeddedInImportShell: true,
            useSharedImportControls: true,
            sharedBrokerDocCode: brokerKeyToDocCode(_selectedBrokerKey),
            sharedDocumentType: _documentType,
            portfolioNameController: _portfolioNameController,
            passwordController: _passwordController,
            onImportCompleted: _prependRecent,
            onOpenPortfolio: widget.onOpenPortfolio,
            onOpenTrade: widget.onOpenTrade,
          ),
        ),
      ],
    );
  }

  Widget _mainColumn({required bool isCompact}) {
    final gap = isCompact ? 8.0 : 10.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sourceTabs(),
        SizedBox(height: gap),
        _sharedControls(),
        SizedBox(height: gap),
        _modeBodies(),
      ],
    );
  }

  /// Shared controls + mode bodies (no Email/Upload tabs).
  Widget _mainContentBelowTabs({required bool isCompact}) {
    final gap = isCompact ? 8.0 : 10.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sharedControls(),
        SizedBox(height: gap),
        _modeBodies(),
      ],
    );
  }

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
        _mainColumn(isCompact: true),
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

  /// Content-only shell — never mounts a secondary "Import holdings" sidebar
  /// (Portfolio / AppShell already own navigation chrome).
  Widget _buildMobileShell() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _webHeader(),
          Expanded(child: _mobileBody()),
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
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Upload Portfolio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                ),
                Text(
                  'Import from file or broker',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _webBody() {
    const gap = 10.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tabs only on the left; rail starts with Broker on the next row.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _sourceTabs()),
              const SizedBox(width: 14),
              const Expanded(flex: 3, child: SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: KeyedSubtree(
                      key: ValueKey('import_main_${apiProvider.environment}'),
                      child: _mainContentBelowTabs(isCompact: false),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: ImportHoldingsInfoRail(
                      isCompact: false,
                      showPrivacy: false,
                      recentEntries: _recentEntries,
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
