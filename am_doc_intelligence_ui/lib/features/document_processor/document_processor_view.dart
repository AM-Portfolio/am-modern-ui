import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_library/am_library.dart';
import 'package:am_doc_intelligence_ui/features/document_processor/pending_batch_intake.dart';
import 'package:am_doc_intelligence_ui/features/document_processor/pending_sync_file.dart';
import 'package:am_doc_intelligence_ui/models/batch_sync_models.dart';
import 'package:am_doc_intelligence_ui/models/sync_unavailable_exception.dart';
import 'package:am_doc_intelligence_ui/services/api_service.dart';
import 'package:am_doc_intelligence_ui/utils/file_downloader.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentProcessorView extends StatefulWidget {
  const DocumentProcessorView({super.key});

  @override
  State<DocumentProcessorView> createState() => _DocumentProcessorViewState();
}

class _DocumentProcessorViewState extends State<DocumentProcessorView> {
  static const int _maxFiles = PendingBatchIntake.maxFiles;

  List<String> _docTypes = [];
  String? _selectedDocType;
  String? _selectedBrokerType;
  bool _loadingTypes = true;
  String _status = '';
  Map<String, dynamic>? _lastResult;
  bool _processing = false;
  bool _dragHover = false;
  bool _intakeBusy = false;
  DropzoneViewController? _dropzoneController;

  /// Serializes drop / pick intake so concurrent drops cannot overrun max files.
  Future<void> _intakeChain = Future<void>.value();

  bool? _isServiceConnected;
  bool _checkingHealth = true;
  bool _showRawJson = false;
  bool _samePortfolioForAll = true;
  /// Mobile-only: Parser Configuration starts expanded (design image 3).
  bool _parserConfigExpanded = true;

  final List<PendingSyncFile> _pendingFiles = [];
  BatchSyncStatus? _batchStatus;
  Timer? _pollTimer;
  final TextEditingController _sharedPortfolioController =
      TextEditingController();
  final ScrollController _pageScroll = ScrollController();

  final currencyFormatter =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _checkHealthAndLoad();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pageScroll.dispose();
    _sharedPortfolioController.dispose();
    for (final file in _pendingFiles) {
      file.dispose();
    }
    super.dispose();
  }

  void _applyBatchStatus(BatchSyncStatus status, {String? statusMessage}) {
    _batchStatus = status;
    _parserConfigExpanded = false;
    if (statusMessage != null) _status = statusMessage;
  }

  void _clearPendingFiles() {
    for (final file in _pendingFiles) {
      file.dispose();
    }
    _pendingFiles.clear();
  }

  void _scrollResultsToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageScroll.hasClients) return;
      _pageScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _checkHealthAndLoad() async {
    setState(() => _checkingHealth = true);
    final isConnected = await apiProvider.checkDocProcessorHealth();

    setState(() {
      _isServiceConnected = isConnected;
      _checkingHealth = false;
    });

    if (isConnected) {
      _loadDocTypes();
    } else {
      setState(() {
        _status = 'Service disconnected. Cannot load types.';
        _loadingTypes = false;
      });
    }
  }

  String _getDocTypeDisplayName(String type) {
    switch (type) {
      case 'COMBINE_PORTFOLIO':
        return 'Combined Portfolio';
      case 'MUTUAL_FUND':
        return 'Mutual Funds';
      case 'NPS_STATEMENT':
        return 'NPS Statement';
      case 'COMPANY_FINANCIAL_REPORT':
        return 'Financial Report';
      case 'STOCK_PORTFOLIO':
        return 'Stock Portfolio';
      case 'TRADE_FNO':
        return 'F&O Tradebook';
      case 'TRADE_EQ':
        return _selectedBrokerType == 'ANGEL_ONE'
            ? 'Trading History'
            : 'Stock Trading History';
      case 'TRADE_MF':
        return 'Mutual Fund Transaction History';
      case 'NSE_INDICES':
        return 'NSE Indices';
      default:
        return type.split('_').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  List<String> _getFilteredDocTypes() {
    if (_selectedBrokerType == null) {
      return _docTypes;
    }
    switch (_selectedBrokerType) {
      case 'ZERODHA':
        return _docTypes
            .where((t) =>
                t == 'STOCK_PORTFOLIO' || t == 'TRADE_EQ' || t == 'TRADE_FNO')
            .toList();
      case 'GROWW':
        return _docTypes
            .where((t) =>
                t == 'STOCK_PORTFOLIO' ||
                t == 'MUTUAL_FUND' ||
                t == 'TRADE_EQ' ||
                t == 'TRADE_MF')
            .toList();
      case 'DHAN':
        return ['PORTFOLIO_EQUITY', 'PORTFOLIO_ETF'];

      case 'ANGEL_ONE':
        return _docTypes
            .where((t) => t == 'COMBINE_PORTFOLIO' || t == 'TRADE_EQ')
            .toList();
      case 'MSTOCK':
        return _docTypes
            .where((t) => t == 'STOCK_PORTFOLIO' || t == 'TRADE_EQ')
            .toList();
      default:
        return _docTypes;
    }
  }

  Future<void> _loadDocTypes() async {
    try {
      final types = await apiProvider.getSupportedDocumentTypes();
      setState(() {
        _docTypes = types;
        _loadingTypes = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading types: $e';
        _loadingTypes = false;
      });
    }
  }

  void _downloadSample() {
    FileDownloader.downloadCSV(
        FileDownloader.getDummyPortfolioCSV(), 'sample_portfolio.csv');
    setState(() => _status = 'Sample file downloaded!');
  }

  Future<void> _pickAndUpload() async {
    if (_processing || _intakeBusy) return;

    // Prefer the dropzone native picker on web so click + browse share one path.
    if (kIsWeb && _dropzoneController != null) {
      try {
        final picked = await _dropzoneController!.pickFiles(
          multiple: true,
          mime: PendingBatchIntake.acceptedMimeTypes,
        );
        if (picked.isEmpty) return;
        await _enqueueDropzoneFiles(picked);
        return;
      } catch (e) {
        // Fall through to FilePicker if the HTML dialog fails.
        debugPrint('[DocProcessor] dropzone pickFiles failed: $e');
      }
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: PendingBatchIntake.allowedExtensions.toList(),
      withData: true,
      allowMultiple: true,
    );
    if (result == null) return;

    final staged = <StagedFileBytes>[];
    for (final file in result.files) {
      if (file.bytes == null) {
        setState(
            () => _status = 'Could not read file bytes for ${file.name}');
        continue;
      }
      staged.add(StagedFileBytes(bytes: file.bytes!, filename: file.name));
    }
    if (staged.isEmpty) return;
    await _stageIncoming(staged);
  }

  Future<void> _stageIncoming(List<StagedFileBytes> incoming) {
    final next = _intakeChain.then((_) async {
      if (!mounted || _processing || incoming.isEmpty) return;
      setState(() => _intakeBusy = true);
      try {
        final result = PendingBatchIntake.addAll(
          pending: _pendingFiles,
          incoming: incoming,
          defaultBroker: _selectedBrokerType,
          defaultDocType: _selectedDocType,
        );
        if (!mounted) return;
        setState(() {
          _dragHover = false;
          _status = result.statusMessage(pendingCount: _pendingFiles.length);
        });
      } finally {
        if (mounted) setState(() => _intakeBusy = false);
      }
    });
    _intakeChain = next.catchError((_) {});
    return next;
  }

  void _onPendingBrokerChanged(PendingSyncFile file, String? broker) {
    setState(() {
      file.brokerType = broker;
      if (broker == null || broker.isEmpty) return;
      final replaced =
          PendingBatchIntake.evictBroker(_pendingFiles, broker, except: file);
      if (replaced != null) {
        _status =
            'Replaced earlier $broker file with ${file.filename} (latest wins)';
      }
    });
  }

  void _removePendingFile(int index) {
    setState(() {
      _pendingFiles.removeAt(index).dispose();
      _status = _pendingFiles.isEmpty
          ? ''
          : '${_pendingFiles.length} file${_pendingFiles.length == 1 ? '' : 's'} ready to sync';
    });
  }

  Future<void> _submitBatch() async {
    if (_pendingFiles.isEmpty || _processing) return;

    setState(() {
      _processing = true;
      _lastResult = null;
      _batchStatus = null;
      _status =
          'Submitting ${_pendingFiles.length} file${_pendingFiles.length == 1 ? '' : 's'}...';
    });

    final sharedName = _sharedPortfolioController.text.trim();
    ProductTelemetry.instance.featureAction(
      'doc_upload',
      tag: 'docs',
      metadata: {
        'file_count': _pendingFiles.length,
        'multi_portfolio': !_samePortfolioForAll,
      },
    );

    try {
      final submitted = await apiProvider.submitBatchSync(
        fileBytes: _pendingFiles.map((f) => f.bytes).toList(),
        filenames: _pendingFiles.map((f) => f.filename).toList(),
        brokerTypes: _pendingFiles
            .map((f) => apiProvider.mapBrokerForApi(f.brokerType))
            .toList(),
        documentTypes: _pendingFiles
            .map((f) => apiProvider.mapDocumentTypeForApi(f.documentType))
            .toList(),
        passwords: _pendingFiles
            .map((f) => f.passwordController.text.trim().isEmpty
                ? null
                : f.passwordController.text.trim())
            .toList(),
        portfolioIds: _samePortfolioForAll
            ? List<String?>.filled(
                _pendingFiles.length,
                sharedName.isEmpty ? null : sharedName,
              )
            : _pendingFiles
                .map((f) => f.portfolioController.text.trim().isEmpty
                    ? null
                    : f.portfolioController.text.trim())
                .toList(),
        // Belt-and-suspenders: batch-level portfolio when shared mode is on.
        portfolioId: _samePortfolioForAll && sharedName.isNotEmpty
            ? sharedName
            : null,
      );
      if (!mounted) return;
      setState(() {
        _applyBatchStatus(
          submitted,
          statusMessage:
              'Sync started (${submitted.total} file${submitted.total == 1 ? '' : 's'}). Detecting brokers...',
        );
      });
      _scrollResultsToTop();
      _startPolling(submitted.batchId);
    } on SyncUnavailableException catch (e) {
      await _handleSyncUnavailable(e);
    } catch (e) {
      if (SyncUnavailableException.looksLikeNetworkOrMissingRoute(e)) {
        await _handleSyncUnavailable(SyncUnavailableException(
          message: e.toString(),
          cause: e,
        ));
        return;
      }
      ProductTelemetry.instance.clientError(errorType: 'doc_process');
      if (!mounted) return;
      setState(() {
        _status = 'Error uploading: $e';
        _processing = false;
      });
    }
  }

  Future<void> _handleSyncUnavailable(SyncUnavailableException e) async {
    final missingTypes =
        _pendingFiles.where((f) => !f.hasExplicitTypes).toList();
    if (missingTypes.isNotEmpty) {
      ProductTelemetry.instance.clientError(errorType: 'doc_process');
      if (!mounted) return;
      setState(() {
        _processing = false;
        _status = 'Auto-detect is unavailable here. '
            'Set broker and document type for each file below, then Sync again.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _status =
          'Batch sync unavailable — parsing ${_pendingFiles.length} file(s) with legacy /process...';
    });

    try {
      await _runSequentialProcessFallback();
    } catch (fallbackError) {
      ProductTelemetry.instance.clientError(errorType: 'doc_process');
      if (!mounted) return;
      setState(() {
        _processing = false;
        _status = 'Error uploading: $fallbackError';
      });
    }
  }

  String? _portfolioNameForPending(PendingSyncFile file) {
    if (_samePortfolioForAll) {
      final shared = _sharedPortfolioController.text.trim();
      return shared.isEmpty ? null : shared;
    }
    final perFile = file.portfolioController.text.trim();
    return perFile.isEmpty ? null : perFile;
  }

  Future<void> _runSequentialProcessFallback() async {
    final results = <Map<String, dynamic>>[];
    var completed = 0;
    var failed = 0;
    final fileStatuses = <FileSyncStatus>[];

    for (var i = 0; i < _pendingFiles.length; i++) {
      final file = _pendingFiles[i];
      if (!mounted) return;
      setState(() {
        _status =
            'Parsing ${i + 1} of ${_pendingFiles.length}: ${file.filename}...';
      });

      try {
        final response = await apiProvider.processDocument(
          file.bytes,
          file.filename,
          file.documentType!,
          brokerType: file.brokerType!,
          portfolioId: _portfolioNameForPending(file),
        );
        completed++;
        final data = response['data'];
        final recordCount = data is List ? data.length : 0;
        results.add({
          'fileName': file.filename,
          'broker': file.brokerType,
          'documentType': file.documentType,
          'response': response,
          'ok': true,
          'records': recordCount,
        });
        fileStatuses.add(FileSyncStatus(
          fileId: 'fallback-$i',
          fileName: file.filename,
          detectedBroker: file.brokerType,
          detectedDocumentType: file.documentType,
          status: 'COMPLETED',
          recordsProcessed: recordCount,
        ));
      } catch (err) {
        failed++;
        results.add({
          'fileName': file.filename,
          'broker': file.brokerType,
          'documentType': file.documentType,
          'ok': false,
          'error': err.toString(),
          'records': 0,
        });
        fileStatuses.add(FileSyncStatus(
          fileId: 'fallback-$i',
          fileName: file.filename,
          detectedBroker: file.brokerType,
          detectedDocumentType: file.documentType,
          status: 'FAILED',
          errorMessage: err.toString(),
        ));
      }
    }

    final overall =
        failed == 0 ? 'COMPLETED' : (completed == 0 ? 'FAILED' : 'PARTIAL');

    if (!mounted) return;
    Map<String, dynamic>? lastOk;
    for (final r in results) {
      if (r['ok'] == true && r['response'] is Map) {
        lastOk = Map<String, dynamic>.from(r['response'] as Map);
      }
    }
    final totalFiles = _pendingFiles.length;
    setState(() {
      _processing = false;
      _applyBatchStatus(
        BatchSyncStatus(
          batchId: 'legacy-process',
          total: totalFiles,
          completed: completed,
          failed: failed,
          overallStatus: overall,
          files: fileStatuses,
        ),
        statusMessage:
            'Legacy parse $overall: $completed of $totalFiles completed'
            '${failed > 0 ? ', $failed failed' : ''} '
            '(used /process because Auto-detect /sync was unavailable)',
      );
      _lastResult = lastOk;
      _clearPendingFiles();
    });
    _scrollResultsToTop();

    ProductTelemetry.instance.featureAction(
      'doc_process',
      tag: 'docs',
      metadata: {
        'mode': 'legacy_fallback',
        'overall_status': overall,
        'completed': completed,
        'failed': failed,
      },
    );
  }

  void _startPolling(String batchId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollStatus(batchId);
    });
    _pollStatus(batchId);
  }

  Future<void> _pollStatus(String batchId) async {
    try {
      final status = await apiProvider.getBatchSyncStatus(batchId);
      if (!mounted) return;
      final waiting = status.needsConfirm + status.needsInput;
      final statusMessage = waiting > 0 && status.isTerminal
          ? 'Review needed: $waiting file${waiting == 1 ? '' : 's'} · '
              '${status.completed} completed'
              '${status.failed > 0 ? ', ${status.failed} failed' : ''}'
          : 'Sync ${status.overallStatus.toLowerCase()}: ${status.completed} of ${status.total} completed'
              '${status.failed > 0 ? ', ${status.failed} failed' : ''}'
              '${waiting > 0 ? ', $waiting need review' : ''}';
      setState(() {
        _applyBatchStatus(status, statusMessage: statusMessage);
        if (status.isTerminal) {
          _processing = false;
          // Clear intake queue so compact UI enters resultsIdle.
          _clearPendingFiles();
        }
      });
      if (status.isTerminal) {
        _pollTimer?.cancel();
        _pollTimer = null;
        _scrollResultsToTop();
        ProductTelemetry.instance.featureAction(
          'doc_process',
          tag: 'docs',
          metadata: {
            'overall_status': status.overallStatus,
            'completed': status.completed,
            'failed': status.failed,
            'needs_confirm': status.needsConfirm,
            'needs_input': status.needsInput,
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Status check failed: $e');
    }
  }

  Future<void> _enqueueDropzoneFiles(List<DropzoneFileInterface> files) async {
    final controller = _dropzoneController;
    if (_processing || controller == null || files.isEmpty) return;
    try {
      final staged = <StagedFileBytes>[];
      for (final ev in files) {
        final name = await controller.getFilename(ev);
        final bytes = await controller.getFileData(ev);
        staged.add(StagedFileBytes(bytes: bytes, filename: name));
      }
      await _stageIncoming(staged);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dragHover = false;
        _status = 'Drop failed: $e';
      });
    }
  }

  Future<void> _onDropFiles(List<DropzoneFileInterface>? files) async {
    if (files == null || files.isEmpty) return;
    await _enqueueDropzoneFiles(files);
  }

  void _onDropInvalid(String? mime) {
    if (!mounted) return;
    setState(() {
      _dragHover = false;
      _status = mime == null || mime.isEmpty
          ? 'That file type is not supported — use XLSX, XLS, PDF, or CSV'
          : 'Unsupported type ($mime) — use XLSX, XLS, PDF, or CSV';
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double contentWidth = constraints.maxWidth;
        final bool isWide = contentWidth >= 920;
        final bool isMedium = contentWidth >= 560 && contentWidth < 920;
        final bool isCompact = contentWidth < 560;
        final bool stackConfigDropdowns = contentWidth < 620;

        final hasBatch = _batchStatus != null;
        final compactHasBatch = isCompact && hasBatch;
        final hideOnlineFooter = compactHasBatch;

        return SingleChildScrollView(
          controller: _pageScroll,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12.0 : (isMedium ? 20.0 : 32.0),
            vertical: isCompact ? 8.0 : 24.0,
          ),
          child: Column(
            // Compact: stretch so GlassCards fill width (no left-clustered black gutter).
            crossAxisAlignment: isCompact
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.start,
            children: [
              if (_checkingHealth)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Checking service connectivity...',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else if (_isServiceConnected == false)
                _buildConnectionError()
              else ...[
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildUploadSection(
                              contentWidth: contentWidth * 0.6,
                              isCompact: isCompact,
                            ),
                            const SizedBox(height: 20),
                            _buildConfigurationSection(
                              stackDropdowns: stackConfigDropdowns,
                              isCompact: isCompact,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: _buildDetailsPanel(
                          isGrid: false,
                          isCompact: isCompact,
                        ),
                      ),
                    ],
                  )
                else if (compactHasBatch) ...[
                  // Results-first, then restore upload + parser + capabilities.
                  if (_status.isNotEmpty || _processing) ...[
                    _buildStatusLog(),
                    const SizedBox(height: 8),
                  ],
                  _buildBatchResultSection(
                    contentWidth: contentWidth,
                    isCompact: true,
                  ),
                  if (_lastResult != null) ...[
                    const SizedBox(height: 8),
                    _buildResultSection(),
                  ],
                  const SizedBox(height: 8),
                  _buildUploadSection(
                    contentWidth: contentWidth,
                    isCompact: true,
                  ),
                  const SizedBox(height: 8),
                  _buildConfigurationSection(
                    stackDropdowns: false,
                    isCompact: true,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailsPanel(
                    isGrid: true,
                    isCompact: true,
                  ),
                ] else ...[
                  // Empty / medium: Upload → Parser → Capabilities
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildUploadSection(
                        contentWidth: contentWidth,
                        isCompact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 8 : 18),
                      _buildConfigurationSection(
                        stackDropdowns:
                            isCompact ? false : stackConfigDropdowns,
                        isCompact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 8 : 18),
                      _buildDetailsPanel(
                        isGrid: isCompact || isMedium,
                        isCompact: isCompact,
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 8 : 20),
                  if (_status.isNotEmpty || _processing) _buildStatusLog(),
                  if (_batchStatus != null) ...[
                    SizedBox(height: isCompact ? 8 : 24),
                    _buildBatchResultSection(
                      contentWidth: contentWidth,
                      isCompact: isCompact,
                    ),
                  ],
                  if (_lastResult != null) ...[
                    SizedBox(height: isCompact ? 8 : 24),
                    _buildResultSection(),
                  ],
                ],
                if (_isServiceConnected == true && !hideOnlineFooter) ...[
                  SizedBox(height: isCompact ? 8 : 16),
                  Text(
                    'Doc processor online',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionError() {
    return GlassCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 20),
            Text(
              'Backend service is unreachable',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The Document Processor service in the "${apiProvider.environment == AppEnvironment.local ? "Local" : "Dev"}" cluster is currently offline.',
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

  Widget _buildDetailsPanel({required bool isGrid, required bool isCompact}) {
    final mfDesc = isCompact
        ? 'CAS, AMFI statements and holdings.'
        : 'CAS, AMFI statements';
    final multiDesc = isCompact
        ? 'Upload multiple files in one batch.'
        : 'Upload multiple files';

    final Widget cap1;
    final Widget cap2;
    final Widget cap3;
    if (isCompact) {
      cap1 = _buildCompactCapabilityTile(
        Icons.assignment_outlined,
        'Equity Portfolios',
        'Zerodha, Angel One and more.',
      );
      cap2 = _buildCompactCapabilityTile(
        Icons.pie_chart_outline,
        'Mutual Funds',
        mfDesc,
      );
      cap3 = _buildCompactCapabilityTile(
        Icons.layers_outlined,
        'Multi-portfolio sync',
        multiDesc,
      );
    } else {
      cap1 = _buildCapabilityTile(
        Icons.assignment_outlined,
        'Equity Portfolios',
        'Zerodha, Angel One and more',
      );
      cap2 = _buildCapabilityTile(
        Icons.pie_chart_outline,
        'Mutual Funds',
        mfDesc,
      );
      cap3 = _buildCapabilityTile(
        Icons.layers_outlined,
        'Multi-portfolio sync',
        multiDesc,
      );
    }

    return GlassCard(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: isCompact ? 16 : 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Supported Capabilities',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 13 : 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 10 : 16),
            if (isGrid)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cap1),
                  SizedBox(width: isCompact ? 8 : 12),
                  Expanded(child: cap2),
                  SizedBox(width: isCompact ? 8 : 12),
                  Expanded(child: cap3),
                ],
              )
            else
              Column(
                children: [
                  cap1,
                  const SizedBox(height: 12),
                  cap2,
                  const SizedBox(height: 12),
                  cap3,
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Compact mobile mini-card: icon above title (design image 3).
  Widget _buildCompactCapabilityTile(
      IconData icon, String title, String desc) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primary, size: 16),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              height: 1.25,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityTile(IconData icon, String title, String desc) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildConfigurationSection({
    required bool stackDropdowns,
    required bool isCompact,
  }) {
    final brokerSelect = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Broker (Optional)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        CustomDropdown<String>(
          // Closed field shows Select; __AUTO__/null still means auto-detect.
          value: _selectedBrokerType,
          items: [
            ...apiProvider.brokerTypes
                .map((e) => e.toSimpleDropdownItem(text: e)),
            '__AUTO__'.toSimpleDropdownItem(text: 'Auto-detect (recommended)'),
          ],
          hint: 'Select',
          onChanged: (v) {
            setState(() {
              _selectedBrokerType = (v == null || v == '__AUTO__') ? null : v;
              final filtered = _getFilteredDocTypes();
              if (_selectedDocType != null &&
                  !filtered.contains(_selectedDocType)) {
                _selectedDocType = null;
              }
            });
          },
        ),
      ],
    );

    final docTypeSelect = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Type (Optional)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        _loadingTypes
            ? const ShimmerLoading(
                child: SkeletonBox(height: 42, width: double.infinity))
            : CustomDropdown<String>(
                value: _selectedDocType,
                items: [
                  ..._getFilteredDocTypes().map((e) =>
                      e.toSimpleDropdownItem(text: _getDocTypeDisplayName(e))),
                  '__AUTO__'.toSimpleDropdownItem(
                      text: 'Auto-detect (recommended)'),
                ],
                hint: 'Select',
                onChanged: (v) => setState(() => _selectedDocType =
                    (v == null || v == '__AUTO__') ? null : v),
              ),
      ],
    );

    final parserBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stackDropdowns) ...[
          brokerSelect,
          const SizedBox(height: 12),
          docTypeSelect,
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: brokerSelect),
              SizedBox(width: isCompact ? 10 : 16),
              Expanded(child: docTypeSelect),
            ],
          ),
        ],
        SizedBox(height: isCompact ? 8 : 12),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _samePortfolioForAll,
          onChanged: _processing
              ? null
              : (v) => setState(() => _samePortfolioForAll = v ?? true),
          title: Text(
            isCompact
                ? 'Use same portfolio name for all files'
                : 'Use the same portfolio name for every file',
            style: TextStyle(
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          visualDensity: isCompact
              ? VisualDensity.compact
              : VisualDensity.standard,
        ),
        if (_samePortfolioForAll) ...[
          SizedBox(height: isCompact ? 4 : 6),
          AppTextField(
            controller: _sharedPortfolioController,
            labelText: 'Portfolio name',
            hintText: isCompact
                ? 'Portfolio name'
                : 'Optional — leave blank to use the broker name',
          ),
        ],
      ],
    );

    final header = Row(
      children: [
        Icon(
          Icons.settings_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: isCompact ? 16 : 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Parser Configuration',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 13 : 15,
            ),
          ),
        ),
        if (isCompact)
          Icon(
            _parserConfigExpanded
                ? Icons.expand_less
                : Icons.expand_more,
            size: 22,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      ],
    );

    return GlassCard(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCompact)
              InkWell(
                onTap: () => setState(
                    () => _parserConfigExpanded = !_parserConfigExpanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: header,
                ),
              )
            else
              header,
            if (!isCompact || _parserConfigExpanded) ...[
              SizedBox(height: isCompact ? 10 : 18),
              parserBody,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection({
    required double contentWidth,
    required bool isCompact,
  }) {
    final bool isInteractable = !_processing && !_intakeBusy;
    final primary = Theme.of(context).colorScheme.primary;
    final batchFull = _pendingFiles.length >= _maxFiles;
    final showBrokerDownload = (_selectedBrokerType == 'ZERODHA') ||
        (_selectedBrokerType == 'GROWW') ||
        (_selectedBrokerType == 'ANGEL_ONE') ||
        (_selectedBrokerType == 'UPSTOX') ||
        (_selectedBrokerType == 'DHAN');

    String headline;
    if (_processing) {
      headline =
          'Syncing ${_pendingFiles.length} file${_pendingFiles.length == 1 ? '' : 's'}...';
    } else if (_intakeBusy) {
      headline = 'Adding files…';
    } else if (_dragHover) {
      headline = batchFull
          ? 'Batch full — drop to replace after clearing a slot'
          : 'Drop to add up to ${_maxFiles - _pendingFiles.length} more';
    } else if (batchFull) {
      headline = 'Batch ready · $_maxFiles of $_maxFiles files';
    } else {
      headline = 'Upload broker files';
    }

    final selectFilesButton = isCompact
        ? FilledButton.icon(
            onPressed:
                isInteractable && !batchFull ? _pickAndUpload : null,
            icon: const Icon(Icons.description_outlined, size: 18),
            label: Text(
              batchFull ? 'Batch full' : 'Select Files',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primary.withOpacity(0.35),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          )
        : OutlinedButton.icon(
            onPressed:
                isInteractable && !batchFull ? _pickAndUpload : null,
            icon: const Icon(Icons.folder_open, size: 18),
            label: Text(
              batchFull ? 'Batch full' : 'Select Files',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );

    final zoneDecoration = BoxDecoration(
      color: _dragHover
          ? primary.withOpacity(0.10)
          : (batchFull && isInteractable
              ? primary.withOpacity(0.03)
              : Colors.transparent),
      border: Border.all(
        color: primary.withOpacity(
          _dragHover ? 0.75 : (isInteractable ? 0.45 : 0.2),
        ),
        style: BorderStyle.solid,
        width: _dragHover ? 2 : 1.5,
      ),
      borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
    );

    final uploadHeadline = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _processing || _intakeBusy
            ? SizedBox(
                height: isCompact ? 32 : 44,
                width: isCompact ? 32 : 44,
                child: const CircularProgressIndicator(strokeWidth: 3),
              )
            : Icon(
                _dragHover
                    ? Icons.file_download_outlined
                    : Icons.cloud_upload_outlined,
                size: isCompact ? 30 : 44,
                color: isInteractable ? primary : Colors.grey,
              ),
        SizedBox(height: isCompact ? 8 : 10),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isInteractable ? primary : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: isCompact ? 13 : 15,
          ),
        ),
        SizedBox(height: isCompact ? 4 : 6),
        Text(
          batchFull
              ? 'Remove a file to add another · Max 10 MB each'
              : 'PDF • CSV • XLSX | Up to $_maxFiles files',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompact ? 11 : 12,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withOpacity(0.8),
          ),
        ),
      ],
    );

    // Dropzone/InkWell only cover the headline area so compact Select Files stays tappable.
    final dropTarget = ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 14 : 24,
              isCompact ? 14 : 28,
              isCompact ? 14 : 24,
              isCompact ? 4 : 28,
            ),
            child: uploadHeadline,
          ),
          if (kIsWeb && isInteractable)
            Positioned.fill(
              child: DropzoneView(
                operation: DragOperation.copy,
                cursor: CursorType.pointer,
                // Do not set mime here: many OS drops send an empty MIME and
                // would be rejected before extension checks can run.
                onCreated: (ctrl) => _dropzoneController = ctrl,
                onHover: () {
                  if (!_dragHover) setState(() => _dragHover = true);
                },
                onLeave: () {
                  if (_dragHover) setState(() => _dragHover = false);
                },
                // Use onDropFiles only — onDropFile also fires and would double-add.
                onDropFiles: _onDropFiles,
                onDropInvalid: _onDropInvalid,
              ),
            ),
          if (!kIsWeb && !isCompact)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isInteractable ? _pickAndUpload : null,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
        ],
      ),
    );

    final uploadZone = Container(
      width: double.infinity,
      decoration: zoneDecoration,
      child: isCompact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                dropTarget,
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: selectFilesButton,
                ),
              ],
            )
          : dropTarget,
    );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          uploadZone,
          // Web/wide: Select Files + Sample stay below the zone (unchanged).
          // Compact: Select Files is inside the zone; hide Sample/broker help.
          if (!isCompact)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  selectFilesButton,
                  TextButton.icon(
                    onPressed: _downloadSample,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text(
                      'Sample Portfolio CSV',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  if (showBrokerDownload)
                    TextButton.icon(
                      onPressed: () {
                        _showDownloadStepsDialog(
                          context,
                          _selectedBrokerType!,
                          _selectedDocType ?? 'STOCK_PORTFOLIO',
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? primary.withOpacity(0.3)
                                : primary.withOpacity(0.12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        Icons.open_in_new,
                        size: 15,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.9)
                            : primary,
                      ),
                      label: Text(
                        "Download from ${_brokerDownloadLabel(_selectedBrokerType!)}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.9)
                                  : primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (_pendingFiles.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
              child: Row(
                children: [
                  Text(
                    'Selected files · ${_pendingFiles.length} of $_maxFiles',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (!_processing)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (final file in _pendingFiles) {
                            file.dispose();
                          }
                          _pendingFiles.clear();
                          _status = '';
                          _batchStatus = null;
                        });
                      },
                      child: const Text('Clear all'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'Set broker and document type for each file, or leave as Select.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...List.generate(
              _pendingFiles.length,
              (index) => _buildPendingFileCard(index, contentWidth: contentWidth),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Sync portfolios (${_pendingFiles.length})',
                  onPressed: _submitBatch,
                  isLoading: _processing,
                  type: AppButtonType.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingFileCard(int index, {double? contentWidth}) {
    final file = _pendingFiles[index];
    final primary = Theme.of(context).colorScheme.primary;
    final brokerItems = [
      ...apiProvider.brokerTypes.map((e) => e.toSimpleDropdownItem(text: e)),
      '__AUTO__'.toSimpleDropdownItem(text: 'Auto-detect (recommended)'),
    ];
    final docTypeValues = <String>{..._docTypes};
    if (file.documentType != null) {
      docTypeValues.add(file.documentType!);
    }
    final docItems = [
      ...docTypeValues
          .map((e) => e.toSimpleDropdownItem(text: _getDocTypeDisplayName(e))),
      '__AUTO__'.toSimpleDropdownItem(text: 'Auto-detect (recommended)'),
    ];

    final bool stackDropdowns = contentWidth != null && contentWidth < 480;

    final brokerDropdown = CustomDropdown<String>(
      value: file.brokerType,
      items: brokerItems,
      hint: 'Select',
      onChanged: _processing
          ? null
          : (v) => _onPendingBrokerChanged(
                file,
                (v == null || v == '__AUTO__') ? null : v,
              ),
    );

    final docTypeDropdown = CustomDropdown<String>(
      value: file.documentType,
      items: docItems,
      hint: 'Select',
      onChanged: _processing
          ? null
          : (v) => setState(() {
                file.documentType =
                    (v == null || v == '__AUTO__') ? null : v;
              }),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.8),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      file.extensionLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.filename,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          file.sizeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    file.hasExplicitTypes
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    size: 20,
                    color: file.hasExplicitTypes
                        ? context.colors.statusSuccess
                        : Colors.grey,
                  ),
                  if (!_processing)
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removePendingFile(index),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_samePortfolioForAll) ...[
                    AppTextField(
                      controller: file.portfolioController,
                      labelText: 'Portfolio name',
                      hintText: 'e.g. Family Zerodha',
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (stackDropdowns) ...[
                    brokerDropdown,
                    const SizedBox(height: 8),
                    docTypeDropdown,
                  ] else ...[
                    Row(
                      children: [
                        Expanded(child: brokerDropdown),
                        const SizedBox(width: 8),
                        Expanded(child: docTypeDropdown),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: file.passwordController,
                    labelText: 'Password (if encrypted)',
                    hintText: 'Optional',
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLog() {
    final lower = _status.toLowerCase();
    final isError = lower.contains('error') ||
        lower.contains('failed to fetch') ||
        lower.contains('not available');
    Color statusColor = isError
        ? context.colors.statusError
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.info_outline,
              color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _status.isEmpty ? 'Ready' : _status,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          if (_processing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Future<void> _resolveBatchFile({
    required FileSyncStatus file,
    bool confirm = false,
    String? brokerType,
    String? documentType,
    String? password,
  }) async {
    final batch = _batchStatus;
    if (batch == null) return;
    setState(() {
      _processing = true;
      _status = confirm
          ? 'Confirming ${file.fileName}...'
          : (password != null
              ? 'Retrying ${file.fileName} with password...'
              : 'Resolving ${file.fileName}...');
    });
    try {
      final updated = await apiProvider.resolveBatchFile(
        batchId: batch.batchId,
        fileId: file.fileId,
        confirm: confirm,
        brokerType: brokerType,
        documentType: documentType,
        password: password,
      );
      if (!mounted) return;
      setState(() => _applyBatchStatus(updated));
      _startPolling(batch.batchId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _status = 'Resolve failed: $e';
      });
    }
  }

  Future<void> _promptPasswordAndResolve(FileSyncStatus file) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Password required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the password for ${file.fileName}',
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Document password',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Unlock & sync'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.isEmpty || !mounted) return;
    await _resolveBatchFile(file: file, password: password);
  }

  Future<void> _promptOverrideAndResolve(FileSyncStatus file) async {
    String? broker = file.detectedBroker;
    String? docType = file.detectedDocumentType;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Set broker & type'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: broker != null &&
                            apiProvider.brokerTypes.contains(broker)
                        ? broker
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Broker',
                      border: OutlineInputBorder(),
                    ),
                    items: apiProvider.brokerTypes
                        .map((b) =>
                            DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setLocal(() => broker = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: docType != null && _docTypes.contains(docType)
                        ? docType
                        : (_docTypes.contains('STOCK_PORTFOLIO')
                            ? 'STOCK_PORTFOLIO'
                            : null),
                    decoration: const InputDecoration(
                      labelText: 'Document type',
                      border: OutlineInputBorder(),
                    ),
                    items: _docTypes
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(_getDocTypeDisplayName(d)),
                            ))
                        .toList(),
                    onChanged: (v) => setLocal(() => docType = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sync'),
              ),
            ],
          ),
        );
      },
    );
    if (ok != true || broker == null || docType == null || !mounted) return;
    await _resolveBatchFile(
      file: file,
      brokerType: broker,
      documentType: docType,
    );
  }

  Widget _buildBatchResultSection({
    double? contentWidth,
    bool isCompact = false,
  }) {
    final batch = _batchStatus;
    if (batch == null) return const SizedBox.shrink();

    Color statusColor(String status) {
      switch (status) {
        case 'COMPLETED':
          return context.colors.statusSuccess;
        case 'FAILED':
          return context.colors.statusError;
        case 'SKIPPED':
          return Colors.orange;
        case 'NEEDS_INPUT':
          return Colors.amber.shade700;
        case 'NEEDS_CONFIRM':
          return Colors.blueGrey;
        case 'PARTIAL':
          return Colors.orange;
        default:
          return Theme.of(context).colorScheme.primary;
      }
    }

    IconData statusIcon(String status) {
      switch (status) {
        case 'COMPLETED':
          return Icons.check_circle_outline;
        case 'FAILED':
          return Icons.error_outline;
        case 'SKIPPED':
          return Icons.skip_next_outlined;
        case 'NEEDS_INPUT':
          return Icons.help_outline;
        case 'NEEDS_CONFIRM':
          return Icons.verified_outlined;
        case 'PROCESSING':
          return Icons.hourglass_empty;
        default:
          return Icons.schedule;
      }
    }

    String friendlyDetail(FileSyncStatus file) {
      final raw = file.errorMessage?.trim();
      if (raw == null || raw.isEmpty) {
        return [
          if (file.detectedBroker != null) file.detectedBroker,
          if (file.detectedDocumentType != null) file.detectedDocumentType,
          if (file.detectionConfidence != null) '${file.detectionConfidence}%',
          if (file.status == 'COMPLETED') '${file.recordsProcessed} records',
        ].whereType<String>().join(' · ');
      }
      if (file.isNeedsConfirm) {
        return [
          'Confirm',
          if (file.detectedBroker != null) file.detectedBroker,
          if (file.detectedDocumentType != null) file.detectedDocumentType,
          if (file.detectionConfidence != null) '${file.detectionConfidence}%',
        ].whereType<String>().join(' · ');
      }
      if (file.isNeedsInput ||
          raw.contains('Could not detect broker') ||
          raw.contains('Could not auto-detect') ||
          raw.contains('Password required') ||
          raw.contains('Scanned or image-only') ||
          raw.contains('Conflicting broker')) {
        final evidence = file.detectionEvidenceSummary.isNotEmpty
            ? ' (${file.detectionEvidenceSummary.first})'
            : '';
        return '$raw$evidence';
      }
      if (raw.startsWith('Duplicate ') && raw.contains('(latest)')) {
        return raw;
      }
      return raw;
    }

    Widget actionRow(FileSyncStatus file) {
      if (file.isNeedsConfirm) {
        final label = [
          file.detectedBroker,
          file.detectedDocumentType,
        ].whereType<String>().join(' · ');
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            FilledButton.tonal(
              onPressed: _processing
                  ? null
                  : () => _resolveBatchFile(file: file, confirm: true),
              child: Text(
                label.isEmpty ? 'Confirm & sync' : 'Confirm $label',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            TextButton(
              onPressed:
                  _processing ? null : () => _promptOverrideAndResolve(file),
              child: const Text('Change', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      }
      if (file.isNeedsInput) {
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (file.needsPassword)
              FilledButton.tonal(
                onPressed: _processing
                    ? null
                    : () => _promptPasswordAndResolve(file),
                child: const Text('Enter password',
                    style: TextStyle(fontSize: 12)),
              ),
            TextButton(
              onPressed:
                  _processing ? null : () => _promptOverrideAndResolve(file),
              child: Text(
                file.needsPassword ? 'Set types instead' : 'Set broker & type',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    final bool wrapStats = contentWidth != null && contentWidth < 640;
    final filePadV = isCompact ? 8.0 : 10.0;

    final statusChip = _buildCompactStatChip(
      'Status',
      batch.overallStatus,
      Icons.flag_outlined,
      statusColor(batch.overallStatus),
      expand: isCompact,
    );
    final doneChip = _buildCompactStatChip(
      'Done',
      '${batch.completed}/${batch.total}',
      Icons.done_all_outlined,
      context.colors.statusSuccess,
      expand: isCompact,
    );
    final confirmChip = _buildCompactStatChip(
      'Confirm',
      '${batch.needsConfirm}',
      Icons.verified_outlined,
      batch.needsConfirm > 0 ? Colors.blueGrey : Colors.grey,
      expand: isCompact,
    );
    final needsChip = _buildCompactStatChip(
      'Needs input',
      '${batch.needsInput}',
      Icons.help_outline,
      batch.needsInput > 0 ? Colors.amber.shade700 : Colors.grey,
      expand: isCompact,
    );
    final failedChip = _buildCompactStatChip(
      'Failed',
      '${batch.failed}',
      Icons.error_outline,
      batch.failed > 0 ? context.colors.statusError : Colors.grey,
      expand: isCompact,
    );

    final Widget statsBody;
    if (isCompact) {
      // Full-width 2-column grid — uses the right side instead of left-clustered Wrap.
      statsBody = Column(
        children: [
          Row(
            children: [
              Expanded(child: statusChip),
              const SizedBox(width: 8),
              Expanded(child: doneChip),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: confirmChip),
              const SizedBox(width: 8),
              Expanded(child: needsChip),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: failedChip),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      );
    } else if (wrapStats) {
      statsBody = Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceAround,
        children: [statusChip, doneChip, confirmChip, needsChip, failedChip],
      );
    } else {
      statsBody = Row(
        children: [
          _buildCompactStat(
            'Status',
            batch.overallStatus,
            Icons.flag_outlined,
            statusColor(batch.overallStatus),
          ),
          _buildCompactStat(
            'Done',
            '${batch.completed}/${batch.total}',
            Icons.done_all_outlined,
            context.colors.statusSuccess,
          ),
          _buildCompactStat(
            'Confirm',
            '${batch.needsConfirm}',
            Icons.verified_outlined,
            batch.needsConfirm > 0 ? Colors.blueGrey : Colors.grey,
          ),
          _buildCompactStat(
            'Needs input',
            '${batch.needsInput}',
            Icons.help_outline,
            batch.needsInput > 0 ? Colors.amber.shade700 : Colors.grey,
          ),
          _buildCompactStat(
            'Failed',
            '${batch.failed}',
            Icons.error_outline,
            batch.failed > 0 ? context.colors.statusError : Colors.grey,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.sync,
                color: Theme.of(context).colorScheme.primary,
                size: isCompact ? 18 : 20),
            const SizedBox(width: 8),
            Text(
              'Batch results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 15 : null,
                  ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 8 : 12),
        GlassCard(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 10,
              vertical: isCompact ? 10 : 8,
            ),
            child: SizedBox(width: double.infinity, child: statsBody),
          ),
        ),
        SizedBox(height: isCompact ? 8 : 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < batch.files.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                Builder(builder: (context) {
                  final file = batch.files[i];
                  final color = statusColor(file.status);
                  final detail = friendlyDetail(file);
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: filePadV),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(statusIcon(file.status), color: color, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (detail.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  detail,
                                  style:
                                      TextStyle(color: color, fontSize: 12),
                                ),
                              ],
                              if (file.isNeedsConfirm ||
                                  file.isNeedsInput) ...[
                                const SizedBox(height: 8),
                                actionRow(file),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            file.status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        if (batch.isTerminal && batch.completed > 0) ...[
          const SizedBox(height: 10),
          Text(
            'Holdings appear under Portfolio — refresh that page if needed.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactStat(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatChip(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool expand = false,
  }) {
    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );

    if (!expand) {
      return Container(
        constraints: const BoxConstraints(minWidth: 100),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: row,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: row,
    );
  }

  Widget _buildResultSection() {
    if (_lastResult == null) return const SizedBox.shrink();

    final List<dynamic> parsedDataList = _lastResult!['data'] ?? [];

    final bool isTrade =
        (_selectedDocType != null && _selectedDocType!.startsWith('TRADE_')) ||
            (parsedDataList.isNotEmpty &&
                parsedDataList.first is Map &&
                (parsedDataList.first as Map).containsKey('basicInfo'));

    double totalValuation = 0.0;

    if (isTrade) {
      for (var item in parsedDataList) {
        if (item is Map) {
          final exec =
              item['executionInfo'] is Map ? item['executionInfo'] : {};
          final double quantity =
              (exec['quantity'] ?? exec['qty'] ?? item['quantity'] ?? 0.0)
                  .toDouble();
          final double price =
              (exec['price'] ?? item['price'] ?? 0.0).toDouble();
          totalValuation += quantity * price;
        }
      }
    } else {
      // Sum total assets dynamically using same fallback logic as datatable rows
      for (var item in parsedDataList) {
        if (item is Map) {
          final double quantity =
              (item['quantity'] ?? item['qty'] ?? 0.0).toDouble();
          final double currentPrice = (item['currentPrice'] ??
                  (item['marketData'] != null
                      ? item['marketData']['marketPrice']
                      : null) ??
                  (item['currentValue'] != null && quantity > 0
                      ? (item['currentValue'] / quantity)
                      : null) ??
                  item['avgBuyingPrice'] ??
                  item['averagePrice'] ??
                  item['buyPrice'] ??
                  item['nav'] ??
                  item['price'] ??
                  0.0)
              .toDouble();
          final double totalValue = item['currentValue'] != null
              ? (item['currentValue'] as num).toDouble()
              : quantity * currentPrice;
          totalValuation += totalValue;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Text(
                    isTrade
                        ? 'Extracted Trade Log Details'
                        : 'Extracted Holdings Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(_showRawJson
                      ? Icons.visibility_off_outlined
                      : Icons.code_outlined),
                  onPressed: () => setState(() => _showRawJson = !_showRawJson),
                  tooltip: 'View Raw JSON Data',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            _buildResultStatCard(
                isTrade ? 'TOTAL VOLUME' : 'TOTAL VALUATION',
                currencyFormatter.format(totalValuation),
                Icons.account_balance_wallet_outlined,
                context.colors.statusSuccess),
            const SizedBox(width: 16),
            _buildResultStatCard(
                'PARSED RECORDS',
                '${parsedDataList.length} Items',
                Icons.format_list_bulleted_outlined,
                Colors.blue),
            const SizedBox(width: 16),
            _buildResultStatCard(
                'PROCESS CODE',
                _lastResult!['processId']
                        ?.toString()
                        .substring(0, 8)
                        .toUpperCase() ??
                    'N/A',
                Icons.vpn_key_outlined,
                Colors.purple),
          ],
        ),

        const SizedBox(height: 24),

        if (_showRawJson) ...[
          const Text('Raw JSON Payload',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: SingleChildScrollView(
              child: Text(
                JsonEncoder.withIndent('  ').convert(_lastResult),
                style: TextStyle(
                  color: context.colors.statusSuccess,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Beautiful Interactive holdings/trade datatable
        GlassCard(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: parsedDataList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                        child: Text(isTrade
                            ? 'No trade records found in this file.'
                            : 'No holding assets found in this statement file.')),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                        child: Text(
                          isTrade
                              ? 'TRADE LOG BREAKDOWN'
                              : 'HOLDING ASSETS BREAKDOWN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 500),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 38.0,
                              horizontalMargin: 8.0,
                              columns: isTrade
                                  ? const [
                                      DataColumn(
                                          label: Text('DATE',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('ASSET / SYMBOL',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('TRADE ID',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('TYPE',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          numeric: true,
                                          label: Text('QTY',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          numeric: true,
                                          label: Text('PRICE',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          numeric: true,
                                          label: Text('TOTAL AMOUNT',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    ]
                                  : const [
                                      DataColumn(
                                          label: Text('ASSET / SYMBOL',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('IDENTIFIER',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          numeric: true,
                                          label: Text('QTY',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          numeric: true,
                                          label: Text('BUY PRICE',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          numeric: true,
                                          label: Text('CURRENT PRICE',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          numeric: true,
                                          label: Text('TOTAL VALUATION',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    ],
                              rows: parsedDataList.map((item) {
                                final map = item is Map ? item : {};

                                if (isTrade) {
                                  final basic = map['basicInfo'] is Map
                                      ? map['basicInfo']
                                      : {};
                                  final instrument =
                                      map['instrumentInfo'] is Map
                                          ? map['instrumentInfo']
                                          : {};
                                  final exec = map['executionInfo'] is Map
                                      ? map['executionInfo']
                                      : {};

                                  final String tradeDate = basic['tradeDate'] ??
                                      basic['orderExecutionTime']
                                          ?.toString()
                                          .split('T')
                                          .first ??
                                      'N/A';
                                  final String assetName =
                                      instrument['symbol'] ??
                                          instrument['name'] ??
                                          map['symbol'] ??
                                          'Unknown Asset';
                                  final String tradeId = basic['tradeId'] ??
                                      map['tradeId'] ??
                                      'N/A';
                                  final String tradeType = (exec['tradeType'] ??
                                          basic['tradeType'] ??
                                          map['type'] ??
                                          'BUY')
                                      .toString()
                                      .toUpperCase();
                                  final double quantity = (exec['quantity'] ??
                                          exec['qty'] ??
                                          map['quantity'] ??
                                          0.0)
                                      .toDouble();
                                  final double price =
                                      (exec['price'] ?? map['price'] ?? 0.0)
                                          .toDouble();
                                  final double totalValue = quantity * price;

                                  final Color typeColor =
                                      tradeType.contains('BUY')
                                          ? context.colors.statusSuccess
                                          : context.colors.statusError;

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(tradeDate,
                                          style:
                                              const TextStyle(fontSize: 13))),
                                      DataCell(
                                        Container(
                                          constraints: const BoxConstraints(
                                              maxWidth: 220),
                                          child: Text(
                                            assetName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(tradeId,
                                          style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              color: Colors.grey))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: typeColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            tradeType,
                                            style: TextStyle(
                                              color: typeColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                          Text(quantity.toStringAsFixed(0))),
                                      DataCell(Text(
                                          currencyFormatter.format(price))),
                                      DataCell(
                                        Text(
                                          currencyFormatter.format(totalValue),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  final String assetName = map['name'] ??
                                      map['securityName'] ??
                                      map['schemeName'] ??
                                      map['symbol'] ??
                                      'Unknown Asset';
                                  final String identifier = map['isin'] ??
                                      map['amfiCode'] ??
                                      map['symbol'] ??
                                      'N/A';
                                  final double quantity =
                                      (map['quantity'] ?? map['qty'] ?? 0.0)
                                          .toDouble();
                                  final double buyPrice =
                                      (map['avgBuyingPrice'] ??
                                              map['averagePrice'] ??
                                              map['buyPrice'] ??
                                              map['price'] ??
                                              0.0)
                                          .toDouble();
                                  final double currentPrice =
                                      (map['currentPrice'] ??
                                              (map['marketData'] != null
                                                  ? map['marketData']
                                                      ['marketPrice']
                                                  : null) ??
                                              (map['currentValue'] != null &&
                                                      quantity > 0
                                                  ? (map['currentValue'] /
                                                      quantity)
                                                  : null) ??
                                              map['avgBuyingPrice'] ??
                                              map['nav'] ??
                                              map['price'] ??
                                              0.0)
                                          .toDouble();
                                  final double totalValue =
                                      map['currentValue'] != null
                                          ? (map['currentValue'] as num)
                                              .toDouble()
                                          : quantity * currentPrice;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Container(
                                          constraints: const BoxConstraints(
                                              maxWidth: 220),
                                          child: Text(
                                            assetName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(identifier,
                                          style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              color: Colors.grey))),
                                      DataCell(
                                          Text(quantity.toStringAsFixed(2))),
                                      DataCell(Text(
                                          currencyFormatter.format(buyPrice))),
                                      DataCell(Text(
                                          currencyFormatter
                                              .format(currentPrice),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold))),
                                      DataCell(
                                        Text(
                                          currencyFormatter.format(totalValue),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDownloadStepsDialog(
      BuildContext context, String broker, String docType) {
    String title = 'How to Download Document';
    String url = '';
    List<Widget> steps = [];

    if (broker == 'ZERODHA') {
      if (docType == 'STOCK_PORTFOLIO') {
        url = 'https://console.zerodha.com/portfolio/holdings';
        title = 'Download Zerodha Portfolio';
        steps = [
          _buildStep(
              1, 'Log in to Zerodha Console and go to Portfolio > Holdings',
              imagePath: 'assets/images/holdings_step1.png'),
          _buildStep(2,
              'Scroll down to the bottom of the page and click "Download: XLSX"',
              imagePath: 'assets/images/holdings_step2.png'),
          _buildStep(3, 'Upload the downloaded file here'),
        ];
      } else if (docType == 'TRADE_FNO' || docType == 'TRADE_EQ') {
        url = 'https://console.zerodha.com/reports/tradebook';
        title = 'Download Zerodha Tradebook';
        String segment =
            docType == 'TRADE_FNO' ? 'Futures & Options' : 'Equity';
        steps = [
          _buildStep(1, 'Go to Zerodha Console > Reports > Tradebook',
              imagePath: 'assets/images/step1.png'),
          _buildStep(2, 'Under the Segment dropdown, select "$segment"',
              imagePath: 'assets/images/step2.png'),
          _buildStep(3,
              'Select your desired Date Range (e.g. current FY) and click the blue arrow (→) button',
              imagePath: 'assets/images/step3.png'),
          _buildStep(4, 'Scroll down to the results and click "Download: XLSX"',
              imagePath: 'assets/images/step4.png'),
          _buildStep(5, 'Upload the downloaded file here'),
        ];
      }
    } else if (broker == 'GROWW') {
      if (docType == 'STOCK_PORTFOLIO') {
        url = 'https://groww.in/user/profile/report';
        title = 'Download Groww Stock Holdings';
        steps = [
          _buildStep(1,
              'Log in to Groww and click on your Profile picture at the top right',
              imagePath: 'assets/images/groww_step1.png'),
          _buildStep(2,
              'Navigate to the "Holdings" section and select "Stocks - Holdings statement"'),
          _buildStep(
              3, 'Select the current date and click the "Download" button',
              imagePath: 'assets/images/groww_step2.png'),
          _buildStep(4, 'Upload the downloaded file here'),
        ];
      } else {
        url = 'https://groww.in/user/profile/report';
        title = 'Download Groww Report';
        steps = [
          _buildStep(1, 'Go to Groww > Profile > Reports'),
          _buildStep(2, 'Download your Tax Report or P&L Report'),
          _buildStep(3, 'Upload the downloaded file here'),
        ];
      }
    } else if (broker == 'ANGEL_ONE') {
      if (docType == 'COMBINE_PORTFOLIO') {
        url = 'https://www.angelone.in/trade/reports/download-reports';
        title = 'Download Angel One Portfolio';
        steps = [
          _buildStep(1, 'Log in to Angel One and go to your Profile section',
              imagePath: 'assets/images/angel_step1.png'),
          _buildStep(2,
              'Under Reports, select Statements (or any option) to open the reports page',
              imagePath: 'assets/images/angel_step2.png'),
          _buildStep(3, 'Navigate to the "Download Reports" tab',
              imagePath: 'assets/images/angel_step3.png'),
          _buildStep(4,
              'In the Others section, click "DOWNLOAD REPORT" for "Combined Holding Statement"',
              imagePath: 'assets/images/angel_step4.png'),
          _buildStep(5, 'Upload the downloaded file here'),
        ];
      } else if (docType == 'TRADE_EQ') {
        url = 'https://www.angelone.in/trade/reports/download-reports';
        title = 'Download Angel One Trading History';
        steps = [
          _buildStep(1, 'Log in to Angel One and go to your Profile section',
              imagePath: 'assets/images/angel_step1.png'),
          _buildStep(2,
              'Under Reports, select Statements (or any option) to open the reports page',
              imagePath: 'assets/images/angel_step2.png'),
          _buildStep(3, 'Navigate to the "Download Reports" tab',
              imagePath: 'assets/images/angel_step3.png'),
          _buildStep(4,
              'In the Stocks, SGBs, Bonds and FnO section, click "DOWNLOAD REPORT" for "DP Transaction and Holding Statement"',
              imagePath: 'assets/images/angel_trade_step4.png'),
          _buildStep(5, 'Upload the downloaded file here'),
        ];
      } else {
        url = 'https://www.angelone.in/trade/reports/download-reports';
        title = 'Download Angel One Report';
        steps = [
          _buildStep(1, 'Go to Angel One > Reports > Download Reports'),
          _buildStep(2, 'Download your Portfolio or Trade History'),
          _buildStep(3, 'Upload the downloaded file here'),
        ];
      }
    } else if (broker == 'UPSTOX') {
      if (docType == 'STOCK_PORTFOLIO') {
        url = 'https://pro.upstox.com/';
        title = 'Download Upstox Portfolio';
        steps = [
          _buildStep(
            1,
            'Log in to Upstox Pro and go to Holdings, then click the three-dot menu (⋮) at the top right of the holdings table',
            imagePath: 'assets/images/upstox_step1.png',
          ),
          _buildStep(
            2,
            'Select "Stock holdings report" from the menu',
            imagePath: 'assets/images/upstox_step2.png',
          ),
          _buildStep(
            3,
            'On the Reports > Holding page, select a date if needed, then click the download icon at the top right',
            imagePath: 'assets/images/upstox_step3.png',
          ),
          _buildStep(
            4,
            'Choose "Download XLSX" from the format menu',
            imagePath: 'assets/images/upstox_step4.png',
          ),
          _buildStep(5, 'Upload the downloaded file here'),
        ];
      }
    } else if (broker == 'DHAN') {
      if (docType == 'PORTFOLIO_EQUITY' || docType == 'PORTFOLIO_ETF') {
        url = 'https://web.dhan.co/';
        title = 'Download Dhan Portfolio';
        steps = [
          _buildStep(
            1,
            'Log in to Dhan Web and click the profile icon at the top right',
            imagePath: 'assets/images/dhan_step1.png',
          ),
          _buildStep(
            2,
            'Select "My Profile on Dhan" from the menu',
            imagePath: 'assets/images/dhan_step2.png',
          ),
          _buildStep(
            3,
            'In Manage Account, click "Statements & Reports"',
            imagePath: 'assets/images/dhan_step3.png',
          ),
          _buildStep(
            4,
            'Under "General Statement for:", select "Holding Summary"',
            imagePath: 'assets/images/dhan_step4.png',
          ),
          _buildStep(
            5,
            'Choose the date and click "Email Holding Summary", then download the attachment from your registered email',
            imagePath: 'assets/images/dhan_step5.png',
          ),
          _buildStep(6, 'Upload the downloaded file here'),
        ];
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...steps,
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text('Open ${_brokerDownloadLabel(broker)}'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _brokerDownloadLabel(String broker) {
    switch (broker) {
      case 'ZERODHA':
        return 'Zerodha Console';
      case 'ANGEL_ONE':
        return 'Angel One';
      case 'UPSTOX':
        return 'Upstox';
      case 'DHAN':
        return 'Dhan';
      case 'GROWW':
        return 'Groww';
      default:
        return broker;
    }
  }

  Widget _buildStep(int stepNumber, String text, {String? imagePath}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              stepNumber.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (imagePath != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 280),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          imagePath,
                          package: 'am_doc_intelligence_ui',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
