import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_library/am_library.dart';
import 'package:am_common/am_common.dart';
import 'package:am_doc_intelligence_ui/features/broker_logo.dart';
import 'package:am_doc_intelligence_ui/features/import_process_banner.dart';
import 'package:am_doc_intelligence_ui/features/recent_imports_store.dart';
import 'package:am_doc_intelligence_ui/services/api_service.dart';

class EmailExtractorView extends StatefulWidget {
  const EmailExtractorView({
    super.key,
    this.compactImportMode = false,
    this.footer,
    this.onImportCompleted,
  });

  /// Hide standalone page chrome when embedded under Import holdings.
  final bool compactImportMode;

  /// Optional trailing content (e.g. info rail on mobile).
  final Widget? footer;

  /// Called after a broker extract succeeds or fails (for Recent Imports).
  final ValueChanged<RecentImportEntry>? onImportCompleted;

  @override
  State<EmailExtractorView> createState() => _EmailExtractorViewState();
}

class _EmailExtractorViewState extends State<EmailExtractorView> {
  List<Map<String, dynamic>> _brokers = [];
  bool _loading = true;
  String _status = '';
  Map<String, dynamic>? _gmailStatus;
  List<Map<String, dynamic>> _mailboxes = [];
  String? _selectedMailbox;

  // Health
  bool? _isServiceConnected;
  bool _checkingHealth = true;
  String? _activeExtractingBrokerId;
  /// Persists highlight on the broker tile the user picked.
  String? _selectedBrokerId;

  Timer? _statusPollTimer;
  StreamSubscription<html.MessageEvent>? _oauthMessageSub;
  final TextEditingController _panController = TextEditingController();
  bool _pdfPasswordVisible = false;
  ImportProcessPhase _phase = ImportProcessPhase.idle;
  DateTime? _busyStartedAt;

  @override
  void initState() {
    super.initState();
    _checkHealthAndLoad();
    _handleGmailQueryParams();

    // Popup callback posts here; also poll until status flips to connected
    _oauthMessageSub = html.window.onMessage.listen(_onOAuthMessage);
    _statusPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isServiceConnected == true && _gmailStatus?['connected'] != true) {
        _checkGmail();
      }
    });
  }

  void _setFeedback(
    String message, {
    required ImportProcessPhase phase,
    bool snack = true,
  }) {
    _status = message;
    _phase = phase;
    if (phase == ImportProcessPhase.busy) {
      _busyStartedAt ??= DateTime.now();
    } else {
      _busyStartedAt = null;
    }
    if (snack && mounted) {
      showImportSnackBar(context, message: message, phase: phase);
    }
  }

  void _handleGmailQueryParams() {
    try {
      final uri = Uri.parse(html.window.location.href);
      final gmail = uri.queryParameters['gmail'];
      if (gmail == 'connected') {
        _status = 'Gmail connected';
        _phase = ImportProcessPhase.success;
        _busyStartedAt = null;
        _checkGmail();
      } else if (gmail == 'error') {
        _status =
            'Gmail connection failed: ${uri.queryParameters['msg'] ?? 'unknown'}';
        _phase = ImportProcessPhase.error;
        _busyStartedAt = null;
      }
    } catch (_) {}
  }

  void _onOAuthMessage(html.MessageEvent event) {
    final data = event.data;
    if (data is! Map) return;
    if (data['type'] != 'am-gmail-oauth') return;
    if (data['success'] == true) {
      final email = data['email'] != null && '${data['email']}'.isNotEmpty
          ? ' (${data['email']})'
          : '';
      setState(() {
        _setFeedback(
          'Gmail connected$email',
          phase: ImportProcessPhase.success,
        );
      });
      _checkGmail();
    } else {
      setState(() {
        _setFeedback(
          'Gmail connection failed: ${data['error'] ?? 'unknown'}',
          phase: ImportProcessPhase.error,
        );
      });
    }
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    _oauthMessageSub?.cancel();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _checkHealthAndLoad() async {
    setState(() => _checkingHealth = true);
    final isConnected = await apiProvider.checkEmailExtractorHealth();
    if (!mounted) return;

    setState(() {
      _isServiceConnected = isConnected;
      _checkingHealth = false;
    });

    if (isConnected) {
      _loadData();
    } else {
      setState(() {
        _status = 'Service disconnected. Cannot load brokers.';
        _loading = false;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final brokersData = await apiProvider.getBrokers();
      await _checkGmail(); // Check connection status
      if (!mounted) return;

      final rawBrokers = brokersData['brokers'];
      final parsedBrokers = rawBrokers is List
          ? rawBrokers
              .whereType<Map>()
              .map((b) => Map<String, dynamic>.from(b))
              .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _brokers = parsedBrokers;
        _loading = false;
        if (rawBrokers is! List) {
          _status = 'Error: invalid broker data received from server.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Error loading data: $e';
        _loading = false;
      });
    }
  }

  void _applyMailboxesFrom(Map<String, dynamic> status) {
    final raw = status['mailboxes'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
        : <Map<String, dynamic>>[];
    _mailboxes = list;
    if (_selectedMailbox == null ||
        !_mailboxes.any((m) => m['email'] == _selectedMailbox)) {
      Map<String, dynamic>? def;
      for (final m in _mailboxes) {
        if (m['is_default'] == true) {
          def = m;
          break;
        }
      }
      def ??= _mailboxes.isNotEmpty ? _mailboxes.first : null;
      _selectedMailbox = def?['email'] as String?;
    }
  }

  Future<void> _checkGmail() async {
    try {
      final status = await apiProvider.checkGmailStatus();
      if (!mounted) return;
      setState(() {
        _gmailStatus = status;
        _applyMailboxesFrom(status);
        // OAuth popup finished — poll flipped to connected.
        if (status['connected'] == true &&
            _phase == ImportProcessPhase.busy) {
          final email = status['email'];
          _setFeedback(
            email != null && '$email'.isNotEmpty
                ? 'Gmail connected ($email)'
                : 'Gmail connected',
            phase: ImportProcessPhase.success,
          );
        }
      });
    } catch (e) {
      debugPrint('Gmail check error: $e');
    }
  }

  Future<void> _startOAuth({required bool addMailbox}) async {
    setState(() {
      _busyStartedAt = DateTime.now();
      _setFeedback(
        addMailbox ? 'Connecting another Gmail…' : 'Opening Google sign-in…',
        phase: ImportProcessPhase.busy,
      );
    });
    try {
      final result = await apiProvider.connectGmail(addMailbox: addMailbox);
      if (!mounted) return;
      if (result['connected'] == true && result['auth_url'] == null) {
        setState(() {
          _setFeedback('Gmail already connected', phase: ImportProcessPhase.success);
        });
        await _checkGmail();
        return;
      }
      if (result['error'] != null) {
        setState(() {
          _setFeedback(
            'Gmail connect failed: ${result['error']}',
            phase: ImportProcessPhase.error,
          );
        });
        return;
      }
      if (result['auth_url'] != null) {
        final String authUrl = result['auth_url'];
        html.window.open(
          authUrl,
          'am_gmail_oauth',
          'width=520,height=720',
        );
        setState(() {
          _setFeedback(
            'Complete Google sign-in in the popup…',
            phase: ImportProcessPhase.busy,
            snack: false,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _setFeedback(
          'Gmail connect failed: ${shortImportError(e)}',
          phase: ImportProcessPhase.error,
        );
      });
    }
  }

  Future<void> _handleGmailConnectionToggle(bool isConnected) async {
    if (isConnected) {
      final target = _selectedMailbox;
      setState(() {
        _busyStartedAt = DateTime.now();
        _setFeedback(
          target != null ? 'Disconnecting $target…' : 'Disconnecting Gmail…',
          phase: ImportProcessPhase.busy,
        );
      });
      try {
        final result = await apiProvider.disconnectGmail(mailbox: target);
        if (!mounted) return;
        setState(() {
          _selectedMailbox = null;
          _setFeedback(
            result['message']?.toString() ?? 'Gmail disconnected',
            phase: ImportProcessPhase.success,
          );
        });
        await _checkGmail();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _setFeedback(
            'Disconnect failed: ${shortImportError(e)}',
            phase: ImportProcessPhase.error,
          );
        });
      }
      return;
    }
    await _startOAuth(addMailbox: false);
  }

  void _onBrokerTap(String brokerId, {required bool gmailConnected}) {
    setState(() => _selectedBrokerId = brokerId);
    if (!gmailConnected) {
      setState(() {
        _setFeedback('Connect Gmail first', phase: ImportProcessPhase.error);
      });
      return;
    }
    _extract(brokerId);
  }

  Future<void> _extract(String brokerId) async {
    setState(() => _selectedBrokerId = brokerId);

    final pan = _panController.text.trim();
    if (pan.isEmpty && brokerId != 'angleone') {
      setState(() {
        _setFeedback(
          'Enter PDF password, then tap ${brokerDisplayName(brokerId)}',
          phase: ImportProcessPhase.error,
        );
      });
      return;
    }

    final label = brokerDisplayName(brokerId);
    setState(() {
      _activeExtractingBrokerId = brokerId;
      _busyStartedAt = DateTime.now();
      _setFeedback('Importing $label…', phase: ImportProcessPhase.busy);
    });

    final sw = Stopwatch()..start();
    ProductTelemetry.instance.featureAction(
      'gmail_extract',
      tag: 'docs',
      metadata: {'broker': brokerId, 'mailbox': _selectedMailbox},
    );
    try {
      final result = await apiProvider.extractFromGmail(
        brokerId,
        pan: pan,
        mailbox: _selectedMailbox,
      );
      sw.stop();
      ProductTelemetry.instance.widgetTiming(
        widget: 'gmail_extract',
        durationMs: sw.elapsedMilliseconds,
        operation: 'extract',
        technicalArea: 'docs',
      );
      if (!mounted) return;
      final count = result['count'];
      final portfolioId = result['db_id']?.toString();
      final fileName = result['filename']?.toString() ??
          result['file_name']?.toString() ??
          'Gmail · $label statement';
      final msg = count != null
          ? 'Imported $count holdings from $label'
          : 'Imported from $label';
      setState(() {
        _activeExtractingBrokerId = null;
        _setFeedback(msg, phase: ImportProcessPhase.success);
      });
      widget.onImportCompleted?.call(RecentImportEntry(
        id: 'mb-${DateTime.now().millisecondsSinceEpoch}',
        source: 'mailbox',
        title: label,
        status: 'success',
        at: DateTime.now().toUtc(),
        files: [fileName],
        detail: count != null ? '$count holdings' : null,
        portfolioId: portfolioId,
      ));
      PortfolioDataRefresh.instance.notifyImported(portfolioId: portfolioId);
    } catch (e) {
      sw.stop();
      ProductTelemetry.instance.widgetTiming(
        widget: 'gmail_extract',
        durationMs: sw.elapsedMilliseconds,
        operation: 'extract_error',
        technicalArea: 'docs',
      );
      ProductTelemetry.instance.clientError(errorType: 'gmail_extract');
      if (!mounted) return;
      final err = shortImportError(e);
      setState(() {
        _activeExtractingBrokerId = null;
        _setFeedback('Import failed: $err', phase: ImportProcessPhase.error);
      });
      widget.onImportCompleted?.call(RecentImportEntry(
        id: 'mb-${DateTime.now().millisecondsSinceEpoch}',
        source: 'mailbox',
        title: label,
        status: 'failed',
        at: DateTime.now().toUtc(),
        files: ['Gmail · $label statement'],
        detail: err,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isConnected = _gmailStatus?['connected'] == true;
    String email = _gmailStatus?['email'] ?? 'Not Connected';

    return LayoutBuilder(
      builder: (context, constraints) {
        final double contentWidth = constraints.maxWidth;
        final bool isCompact = contentWidth < 560;
        final embed = widget.compactImportMode;

        if (embed) {
          if (_checkingHealth) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          if (_isServiceConnected == false) {
            return _buildConnectionError();
          }
          // Two full-width cards (same width as each other / column):
          // 1) Gmail + broker tiles  2) PDF password
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactImportCard(isConnected, email, contentWidth),
              const SizedBox(height: 6),
              _buildCompactPasswordCard(),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildStatusLog(),
              ],
              if (widget.footer != null) ...[
                const SizedBox(height: 8),
                widget.footer!,
              ],
            ],
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16.0 : 32.0,
            vertical: 24.0,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isCompact: isCompact),
                const SizedBox(height: 28),
                if (_checkingHealth)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Checking email extractor connectivity...',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else if (_isServiceConnected == false)
                  _buildConnectionError()
                else ...[
                  _buildMailboxSection(isConnected, email),
                  const SizedBox(height: 16),
                  if (_loading)
                    const ShimmerLoading(
                        child:
                            SkeletonBox(height: 64, width: double.infinity))
                  else
                    _buildBrokerGrid(isConnected, contentWidth: contentWidth),
                  const SizedBox(height: 16),
                  _buildPanField(),
                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildStatusLog(),
                  ],
                ],
                if (widget.footer != null) ...[
                  const SizedBox(height: 16),
                  widget.footer!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    Color statusColor = _isServiceConnected == true
        ? Colors.green
        : (_isServiceConnected == false ? Colors.red : Colors.grey);
    String statusText = _isServiceConnected == true
        ? 'Online'
        : (_isServiceConnected == false ? 'Offline' : 'Unknown');

    final headerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Extractor',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                fontSize: isCompact ? 22 : null,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Extract holding statements directly from your secure mailbox',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );

    final statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerContent,
          const SizedBox(height: 12),
          statusBadge,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: headerContent),
        const SizedBox(width: 16),
        statusBadge,
      ],
    );
  }

  Widget _buildConnectionError() {
    return GlassCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.mail_lock_outlined,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 20),
            Text(
              'Email Extraction Service Offline',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The Email Extractor backend in the "${apiProvider.environment == AppEnvironment.local ? "Local" : "Dev"}" environment is unreachable.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Retry Connection',
              onPressed: _checkHealthAndLoad,
              type: AppButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  static const EdgeInsets _compactCardPad =
      EdgeInsets.fromLTRB(12, 10, 12, 12);

  /// Gmail row + broker tiles in one full-width card (tiles align to card edges).
  Widget _buildCompactImportCard(
    bool isConnected,
    String email,
    double contentWidth,
  ) {
    final accent = ModuleColors.analytics;
    // Inner width after card pad — used so broker grid spans edge-to-edge.
    final gridWidth = (contentWidth - _compactCardPad.horizontal).clamp(120.0, 4000.0);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: _compactCardPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isConnected
                      ? Icons.mark_email_read_outlined
                      : Icons.mail_outline,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isConnected
                        ? (email.isNotEmpty && email != 'Not Connected'
                            ? email
                            : 'Gmail connected')
                        : 'Connect Gmail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!isConnected)
                  FilledButton(
                    onPressed: () => _startOAuth(addMailbox: false),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Connect', style: TextStyle(fontSize: 12)),
                  )
                else ...[
                  TextButton(
                    onPressed: _mailboxes.length >= 5
                        ? null
                        : () => _startOAuth(addMailbox: true),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Add', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () => _handleGmailConnectionToggle(true),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child:
                        const Text('Disconnect', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
            if (isConnected && _mailboxes.length > 1) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in _mailboxes)
                    ChoiceChip(
                      label: Text(
                        '${m['email']}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: _selectedMailbox == m['email'],
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) {
                        setState(
                            () => _selectedMailbox = m['email'] as String?);
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (_loading)
              const ShimmerLoading(
                child: SkeletonBox(height: 56, width: double.infinity),
              )
            else
              _buildBrokerGrid(isConnected, contentWidth: gridWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPasswordCard() {
    final forId = _activeExtractingBrokerId ?? _selectedBrokerId;
    final forBroker = forId != null ? brokerDisplayName(forId) : null;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: _compactCardPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              forBroker != null ? 'Password · $forBroker' : 'PDF password',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _panController,
              obscureText: !_pdfPasswordVisible,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'PAN / PDF password',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  tooltip: _pdfPasswordVisible ? 'Hide' : 'Show',
                  icon: Icon(
                    _pdfPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  onPressed: () => setState(
                    () => _pdfPasswordVisible = !_pdfPasswordVisible,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMailboxSection(bool isConnected, String email) {
    final accent = Theme.of(context).colorScheme.primary;
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.mark_email_read_outlined : Icons.mail_outline,
                  size: 20,
                  color: isConnected ? Colors.green : accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isConnected ? 'Gmail' : 'Connect Gmail',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (!isConnected)
                  TextButton(
                    onPressed: () => _startOAuth(addMailbox: false),
                    child: const Text('Connect'),
                  )
                else ...[
                  TextButton(
                    onPressed: _mailboxes.length >= 5
                        ? null
                        : () => _startOAuth(addMailbox: true),
                    child: const Text('Add'),
                  ),
                  TextButton(
                    onPressed: () => _handleGmailConnectionToggle(true),
                    child: const Text('Disconnect'),
                  ),
                ],
              ],
            ),
            if (isConnected && _mailboxes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in _mailboxes)
                    ChoiceChip(
                      label: Text(
                        '${m['email']}${m['is_default'] == true ? ' · default' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _selectedMailbox == m['email'],
                      onSelected: (_) {
                        setState(() => _selectedMailbox = m['email'] as String?);
                      },
                    ),
                ],
              ),
            ] else if (isConnected) ...[
              const SizedBox(height: 6),
              Text(email, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPanField() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PDF password (for the broker you select)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Unlocks the statement PDF for the broker you tap. May be your PAN or a broker-specific password.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _panController,
              obscureText: !_pdfPasswordVisible,
              decoration: InputDecoration(
                hintText: 'PAN or broker PDF password',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  tooltip: _pdfPasswordVisible ? 'Hide' : 'Show',
                  icon: Icon(
                    _pdfPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(
                    () => _pdfPasswordVisible = !_pdfPasswordVisible,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrokerGrid(bool isConnected, {required double contentWidth}) {
    // Narrow screens: fewer columns so tiles wrap (avoids mobile overflow).
    final int cols;
    if (_brokers.isEmpty) {
      cols = 1;
    } else if (contentWidth < 360) {
      cols = 3;
    } else if (contentWidth < 480) {
      cols = _brokers.length <= 4 ? _brokers.length : 4;
    } else if (_brokers.length <= 6) {
      cols = _brokers.length;
    } else if (contentWidth < 720) {
      cols = 5;
    } else {
      cols = 6;
    }

    Widget buildBrokerTile(Map<String, dynamic> broker) {
      final String brokerId = broker['id']?.toString() ?? '';
      final String brokerName =
          broker['name']?.toString() ?? 'Unknown Broker';
      final bool isCurrentlyExtracting =
          _activeExtractingBrokerId == brokerId;
      final bool selected = _selectedBrokerId == brokerId;
      // High-contrast select ring (works in light + dark app chrome).
      const selectColor = Color(0xFF12B76A);

      final logoPath = brokerLogoAsset(brokerId);
      final label = brokerDisplayName(brokerId.isNotEmpty ? brokerId : brokerName);

      return Tooltip(
        message: label,
        child: Material(
          color: Colors.white,
          elevation: selected ? 4 : 0,
          shadowColor: selectColor.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: isCurrentlyExtracting
                ? null
                : () => _onBrokerTap(brokerId, gmailConnected: isConnected),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? selectColor : const Color(0xFFE4E7EC),
                  width: selected ? 3 : 1,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: logoPath != null
                          ? Image.asset(
                              logoPath,
                              package: 'am_doc_intelligence_ui',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  brokerLetterAvatar(brokerId, size: 26),
                            )
                          : brokerLetterAvatar(brokerId, size: 26),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: selectColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (isCurrentlyExtracting)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: 0.7),
                        child: const Center(
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: selectColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Wrap (not GridView) so height is always content-sized on mobile web —
    // shrinkWrap GridView still left a tall empty band under the Gmail row.
    const tileExtent = 56.0;
    const gap = 8.0;
    final tileWidth =
        ((contentWidth - gap * (cols - 1)) / cols).clamp(48.0, 200.0);

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final broker in _brokers)
          SizedBox(
            width: tileWidth,
            height: tileExtent,
            child: buildBrokerTile(broker),
          ),
      ],
    );
  }

  Widget _buildStatusLog() {
    if (_status.isEmpty) return const SizedBox.shrink();
    return ImportProcessBanner(
      phase: _phase,
      message: _status,
      busyStartedAt: _busyStartedAt,
    );
  }
}
