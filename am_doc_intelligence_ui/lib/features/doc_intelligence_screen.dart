import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_doc_intelligence_ui/features/document_processor/document_processor_view.dart';
import 'package:am_doc_intelligence_ui/features/email_discover_models.dart';
import 'package:am_doc_intelligence_ui/features/email_extractor/email_extractor_view.dart';
import 'package:am_doc_intelligence_ui/features/import_holdings_info_rail.dart';
import 'package:am_doc_intelligence_ui/features/import_holdings_shared_controls.dart';
import 'package:am_doc_intelligence_ui/features/recent_imports_store.dart';
import 'package:am_doc_intelligence_ui/models/batch_sync_models.dart';
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
  /// Local-only hides until next full page reload (no server delete API).
  final Set<String> _hiddenRecentIds = {};
  /// Bumped on refresh / userId change so a stale [_loadRecent] cannot clobber.
  int _recentLoadGen = 0;
  Set<String> _selectedSourceKeys = {};
  String? _documentType;
  late _ImportSource _source;
  final TextEditingController _portfolioNameController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _npsPasswordController = TextEditingController();
  String? _autoPortfolioName;
  EmailDiscoverSnapshot _emailDiscover = const EmailDiscoverSnapshot();

  static const double _mobileShellMax = 1100;
  static const int _recentCap = 25;

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
    _npsPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final gen = ++_recentLoadGen;

    List<RecentImportEntry> uploadRows = const [];
    List<RecentImportEntry> mailboxRows = const [];

    try {
      final history =
          await apiProvider.listBatchSyncHistory(limit: _recentCap);
      uploadRows = _entriesFromBatchHistory(history.items);
    } catch (e) {
      debugPrint('[ImportHoldings] batch history failed: $e');
    }

    try {
      final extracts =
          await apiProvider.listExtractHistory(limit: _recentCap);
      mailboxRows = _entriesFromExtractHistory(extracts);
    } catch (e) {
      debugPrint('[ImportHoldings] extract history failed: $e');
    }

    final merged = <RecentImportEntry>[...uploadRows, ...mailboxRows]
      ..sort((a, b) => b.at.compareTo(a.at));
    final capped = merged
        .where((e) => !_hiddenRecentIds.contains(e.id))
        .take(_recentCap)
        .toList();

    // Best-effort local cache for offline display; server is SoT.
    try {
      await RecentImportsStore.instance.replaceAll(widget.userId, capped);
    } catch (_) {}

    if (!mounted || gen != _recentLoadGen) return;
    setState(() => _recentEntries = capped);
  }

  static List<RecentImportEntry> _entriesFromBatchHistory(
      List<BatchSyncStatus> batches) {
    final out = <RecentImportEntry>[];
    for (final batch in batches) {
      final batchAt = batch.updatedAt ?? batch.createdAt ?? DateTime.now();
      if (batch.files.isEmpty) {
        out.add(RecentImportEntry(
          id: 'up-${batch.batchId}',
          source: 'upload',
          title: 'Batch ${batch.batchId}',
          status: _mapOverallStatus(batch.overallStatus),
          at: batchAt.toLocal(),
          files: const [],
          detail: batch.overallStatus,
        ));
        continue;
      }
      for (final file in batch.files) {
        final at =
            (file.completedAt ?? file.startedAt ?? batchAt).toLocal();
        out.add(RecentImportEntry(
          id: 'up-${batch.batchId}-${file.fileId}',
          source: 'upload',
          title: file.fileName.isNotEmpty ? file.fileName : 'Upload',
          status: _mapFileStatus(file.status),
          at: at,
          files: [file.fileName],
          detail: file.errorMessage ??
              (file.detectedBroker != null
                  ? file.detectedBroker
                  : file.status),
        ));
      }
    }
    return out;
  }

  static List<RecentImportEntry> _entriesFromExtractHistory(
      List<ExtractHistoryItem> items) {
    return items.map((e) {
      final label = e.broker.isNotEmpty ? e.broker : 'Gmail';
      final title = e.filename?.isNotEmpty == true
          ? e.filename!
          : 'Gmail · $label';
      return RecentImportEntry(
        id: 'mb-${e.id}',
        source: 'mailbox',
        title: title,
        status: 'success',
        at: e.extractedAt,
        files: [e.filename ?? 'Gmail · $label statement'],
        detail: e.holdingsCount > 0 ? '${e.holdingsCount} holdings' : null,
      );
    }).toList();
  }

  static String _mapOverallStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'FAILED':
        return 'failed';
      case 'PARTIAL':
        return 'partial';
      case 'COMPLETED':
        return 'success';
      default:
        return raw.toLowerCase();
    }
  }

  static String _mapFileStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'FAILED':
        return 'failed';
      case 'COMPLETED':
      case 'SKIPPED':
        return 'success';
      case 'NEEDS_INPUT':
      case 'NEEDS_CONFIRM':
        return 'partial';
      default:
        return raw.toLowerCase();
    }
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

  Future<void> _onImportCompleted(RecentImportEntry entry) async {
    // Optimistic local row, then refresh from server history APIs.
    _recentLoadGen++;
    if (mounted) {
      setState(() {
        _recentEntries = [
          entry,
          ..._recentEntries.where((e) => e.id != entry.id),
        ].take(_recentCap).toList();
      });
    }
    await _loadRecent();
  }

  Future<void> _onDeleteRecent(RecentImportEntry entry) async {
    _hiddenRecentIds.add(entry.id);
    try {
      await RecentImportsStore.instance.remove(widget.userId, entry.id);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _recentEntries =
          _recentEntries.where((e) => e.id != entry.id).toList();
    });
  }

  void _setSource(_ImportSource source) {
    if (_source == source) return;
    setState(() => _source = source);
    widget.onTabChanged?.call(_slugForSource(source));
  }

  void _onSourcesChanged(Set<String> keys) {
    final ordered = orderedImportSources(keys);
    final label = ordered.isEmpty
        ? ''
        : ordered.length == 1
            ? brokerKeyDisplayName(ordered.first)
            : '${ordered.length} sources';
    final current = _portfolioNameController.text.trim();
    final shouldReplaceName = current.isEmpty ||
        current == (_autoPortfolioName ?? '') ||
        (_autoPortfolioName != null && current == _autoPortfolioName);
    setState(() {
      _selectedSourceKeys = keys;
      // CDSL/NPS auto-pick the matching doc type; other brokers clear for chips.
      _documentType = defaultDocTypeForSourceKeys(keys);
      // Hide passwords until Email view finishes discover for the new set.
      if (_source == _ImportSource.email) {
        _emailDiscover = const EmailDiscoverSnapshot(discovering: true);
      }
      if (shouldReplaceName && label.isNotEmpty) {
        _portfolioNameController.text = label;
        _autoPortfolioName = label;
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
    final ordered = orderedImportSources(_selectedSourceKeys);
    final brokerHint = ordered.isEmpty
        ? null
        : ordered.length == 1
            ? brokerKeyDisplayName(ordered.first)
            : '${ordered.length} sources';
    final isEmail = _source == _ImportSource.email;
    // Email: passwords only after Gmail discover finds a statement.
    final showEmailPassword =
        isEmail && _emailDiscover.showPasswordFields;
    return ImportHoldingsSharedControls(
      selectedSourceKeys: _selectedSourceKeys,
      onSourcesChanged: _onSourcesChanged,
      portfolioNameController: _portfolioNameController,
      passwordController: _passwordController,
      npsPasswordController: _npsPasswordController,
      documentType: _documentType,
      onDocumentTypeChanged: (v) => setState(() {
        _documentType =
            (v == null || v.isEmpty || v == kImportDocTypeAuto) ? null : v;
        // Doc-type chips can seed the matching source when none selected yet.
        if (_selectedSourceKeys.isEmpty) {
          if (_documentType == 'MUTUAL_FUND') {
            _selectedSourceKeys = {'cdsl'};
          } else if (_documentType == 'NPS_STATEMENT') {
            _selectedSourceKeys = {'nps'};
          }
        }
      }),
      portfolioNameHint: brokerHint != null
          ? 'Optional — defaults to $brokerHint'
          : 'Optional — defaults to broker name',
      showPassword: isEmail ? showEmailPassword : true,
      passwordRequiredHint: isEmail || showEmailPassword,
      showDocumentType: !isEmail,
      documentTypeOptional: false,
      useSimpleDocTypePicker: true,
      // NPS field only when NPS was found (not merely selected).
      showNpsPassword: !isEmail
          ? null
          : _emailDiscover.found.any((h) => h.brokerId == 'nps'),
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
            sharedSourceEmailIds: orderedImportSources(_selectedSourceKeys)
                .map(brokerKeyToEmailId)
                .whereType<String>()
                .toList(),
            passwordController: _passwordController,
            npsPasswordController: _npsPasswordController,
            portfolioNameController: _portfolioNameController,
            onImportCompleted: _onImportCompleted,
            onOpenPortfolio: widget.onOpenPortfolio,
            onOpenTrade: widget.onOpenTrade,
            onDiscoverChanged: (snap) {
              if (!mounted) return;
              setState(() => _emailDiscover = snap);
            },
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
            sharedSourceDocCodes: orderedImportSources(_selectedSourceKeys)
                .map(brokerKeyToDocCode)
                .whereType<String>()
                .toList(),
            sharedDocumentType: _documentType,
            portfolioNameController: _portfolioNameController,
            passwordController: _passwordController,
            npsPasswordController: _npsPasswordController,
            onImportCompleted: _onImportCompleted,
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
          onDelete: _onDeleteRecent,
          onOpenPortfolio: widget.onOpenPortfolio,
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
                      onDeleteRecent: _onDeleteRecent,
                      onOpenPortfolio: widget.onOpenPortfolio,
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
