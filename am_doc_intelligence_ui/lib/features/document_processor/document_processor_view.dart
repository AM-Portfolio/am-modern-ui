import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_doc_intelligence_ui/services/api_service.dart';
import 'package:am_doc_intelligence_ui/utils/file_downloader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:am_design_system/core/utils/responsive_helper.dart';
class DocumentProcessorView extends StatefulWidget {
  const DocumentProcessorView({super.key});

  @override
  State<DocumentProcessorView> createState() => _DocumentProcessorViewState();
}

class _DocumentProcessorViewState extends State<DocumentProcessorView> {
  List<String> _docTypes = [];
  String? _selectedDocType;
  String? _selectedBrokerType = 'ZERODHA';
  bool _loadingTypes = true;
  String _status = '';
  Map<String, dynamic>? _lastResult;
  bool _processing = false;
  
  // Health check
  bool? _isServiceConnected;
  bool _checkingHealth = true;
  bool _showRawJson = false;

  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  
  @override
  void initState() {
    super.initState();
    _checkHealthAndLoad();
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
        return _selectedBrokerType == 'ANGEL_ONE' ? 'Trading History' : 'Stock Trading History';
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
        return _docTypes.where((t) => t == 'STOCK_PORTFOLIO' || t == 'TRADE_EQ' || t == 'TRADE_FNO').toList();
      case 'GROWW':
        return _docTypes.where((t) => t == 'STOCK_PORTFOLIO' || t == 'MUTUAL_FUND' || t == 'TRADE_EQ' || t == 'TRADE_MF').toList();
      case 'DHAN':
        return ['PORTFOLIO_EQUITY', 'PORTFOLIO_ETF'];

      case 'ANGEL_ONE':
        return _docTypes.where((t) => t == 'COMBINE_PORTFOLIO' || t == 'TRADE_EQ').toList();
      case 'MSTOCK':
        return _docTypes.where((t) => t == 'STOCK_PORTFOLIO' || t == 'TRADE_EQ').toList();
      case 'UPSTOX':
        return _docTypes.where((t) => t == 'STOCK_PORTFOLIO' || t == 'TRADE_EQ').toList();
      case 'OTHER':
      default:
        return _docTypes;
    }
  }

  Future<void> _loadDocTypes() async {
    try {
      final types = await apiProvider.getSupportedDocumentTypes();
      setState(() {
        _docTypes = types;
        final filtered = _getFilteredDocTypes();
        if (filtered.isNotEmpty) {
          _selectedDocType = filtered.first;
        }
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
    FileDownloader.downloadCSV(FileDownloader.getDummyPortfolioCSV(), 'sample_portfolio.csv');
    setState(() => _status = 'Sample file downloaded!');
  }

  Future<void> _pickAndUpload() async {
    if (_selectedDocType == null) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'xlsx', 'xls', 'csv'],
      withData: true,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      setState(() {
        _status = 'Uploading ${file.name}...';
        _processing = true;
        _lastResult = null;
      });

      try {
        final response = await apiProvider.processDocument(
          file.bytes!, 
          file.name, 
          _selectedDocType!,
          brokerType: _selectedBrokerType ?? 'ZERODHA'
        );
        setState(() {
          _lastResult = response;
          _status = 'Success! Processed ${file.name}';
          _processing = false;
        });
      } catch (e) {
        setState(() {
          _status = 'Error uploading: $e';
          _processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveHelper.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 32.0, 
        vertical: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 28),
          
          if (_checkingHealth)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Checking service connectivity...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else if (_isServiceConnected == false)
             _buildConnectionError()
          else ...[
            if (isMobile) ...[
              _buildConfigurationSection(),
              const SizedBox(height: 24),
              _buildUploadSection(),
              const SizedBox(height: 24),
              _buildDetailsPanel(),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildConfigurationSection(),
                        const SizedBox(height: 24),
                        _buildUploadSection(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: _buildDetailsPanel(),
                  )
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (_status.isNotEmpty || _processing) _buildStatusLog(),
            if (_lastResult != null) ...[
              const SizedBox(height: 28),
              _buildResultSection(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    Color statusColor = _isServiceConnected == true ? Colors.green : (_isServiceConnected == false ? Colors.red : Colors.grey);
    String statusText = _isServiceConnected == true ? 'Online' : (_isServiceConnected == false ? 'Offline' : 'Checking...');
    final bool isMobile = ResponsiveHelper.isMobile(context);

    final headerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Intelligence',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            fontSize: isMobile ? 22 : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Automated parser for financial statements',
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

    if (isMobile) {
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 20),
            Text(
              'Backend service is unreachable',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The Document Processor service in the "${apiProvider.environment == AppEnvironment.local ? "Local" : "Dev"}" cluster is currently offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  Widget _buildDetailsPanel() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported Capabilities',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildCapabilityTile(Icons.assignment_outlined, 'Equity Portfolios', 'Extract direct stock holdings from Zerodha, Angel One, and others.'),
            const SizedBox(height: 16),
            _buildCapabilityTile(Icons.pie_chart_outline, 'Mutual Funds', 'Parse CAS statements, AMFI scheme holdings, and asset breakdowns.'),
            const SizedBox(height: 16),
            _buildCapabilityTile(Icons.trending_up_outlined, 'F&O Trade Books', 'Track derivative trades, profit distributions, and executions.'),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityTile(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildConfigurationSection() {
    final bool isMobile = ResponsiveHelper.isMobile(context);

    final brokerSelect = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BROKER / INSTITUTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey)),
        const SizedBox(height: 8),
        CustomDropdown<String>(
          value: _selectedBrokerType,
          items: apiProvider.brokerTypes.map((e) => e.toSimpleDropdownItem(text: e)).toList(),
          hint: 'Select Broker',
          onChanged: (v) {
            setState(() {
              _selectedBrokerType = v;
              final filtered = _getFilteredDocTypes();
              if (filtered.isNotEmpty) {
                if (!filtered.contains(_selectedDocType)) {
                  _selectedDocType = filtered.first;
                }
              } else {
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
        const Text('DOCUMENT TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey)),
        const SizedBox(height: 8),
        _loadingTypes 
          ? const ShimmerLoading(child: SkeletonBox(height: 42, width: double.infinity))
          : CustomDropdown<String>(
              value: _selectedDocType,
              items: _getFilteredDocTypes().map((e) => e.toSimpleDropdownItem(text: _getDocTypeDisplayName(e))).toList(),
              hint: 'Select Doc Type',
              onChanged: (v) => setState(() => _selectedDocType = v),
            ),
      ],
    );

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'Parser Configuration', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isMobile) ...[
              brokerSelect,
              const SizedBox(height: 16),
              docTypeSelect,
            ] else ...[
              Row(
                children: [
                  Expanded(child: brokerSelect),
                  const SizedBox(width: 20),
                  Expanded(child: docTypeSelect),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    final bool isInteractable = !_processing && _selectedDocType != null;
    return GlassCard(
      child: InkWell(
        onTap: isInteractable ? _pickAndUpload : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(isInteractable ? 0.3 : 0.1),
              style: BorderStyle.solid,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _processing 
                ? const SizedBox(
                    height: 52,
                    width: 52,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(
                    Icons.cloud_upload_outlined, 
                    size: 52, 
                    color: isInteractable ? Theme.of(context).colorScheme.primary : Colors.grey
                  ),
              const SizedBox(height: 16),
              Text(
                _processing ? 'Parsing Statement Data...' : 'Click to Upload Document',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isInteractable ? Theme.of(context).colorScheme.primary : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Supports PDF, Excel (XLSX, XLS), and CSV formats', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _downloadSample, 
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download Sample Portfolio CSV', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              if ((_selectedBrokerType == 'ZERODHA' && (_selectedDocType == 'STOCK_PORTFOLIO' || _selectedDocType == 'TRADE_FNO' || _selectedDocType == 'TRADE_EQ')) ||
                  (_selectedBrokerType == 'GROWW' && _selectedDocType != null) ||
                  (_selectedBrokerType == 'ANGEL_ONE' && (_selectedDocType == 'COMBINE_PORTFOLIO' || _selectedDocType == 'TRADE_EQ')))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton.icon(
                    onPressed: () {
                      _showDownloadStepsDialog(context, _selectedBrokerType!, _selectedDocType!);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(Icons.open_in_new, size: 16, color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.9)
                        : Theme.of(context).colorScheme.primary),
                    label: Text(
                      "Don't have the document? Download from ${_selectedBrokerType == 'ZERODHA' ? 'Zerodha Console' : _selectedBrokerType == 'ANGEL_ONE' ? 'Angel One' : 'Groww'}",
                      style: TextStyle(
                        fontSize: 13, 
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.9)
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLog() {
    bool isError = _status.toLowerCase().contains('error');
    Color statusColor = isError ? Colors.red : Theme.of(context).colorScheme.primary;

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
          Icon(isError ? Icons.error_outline : Icons.info_outline, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _status.isEmpty ? 'Ready' : _status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
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
  }  Widget _buildResultSection() {
    if (_lastResult == null) return const SizedBox.shrink();

    final List<dynamic> parsedDataList = _lastResult!['data'] ?? [];
    
    final bool isTrade = (_selectedDocType != null && _selectedDocType!.startsWith('TRADE_')) ||
        (parsedDataList.isNotEmpty && parsedDataList.first is Map && (parsedDataList.first as Map).containsKey('basicInfo'));

    double totalValuation = 0.0;
    
    if (isTrade) {
      for (var item in parsedDataList) {
        if (item is Map) {
          final exec = item['executionInfo'] is Map ? item['executionInfo'] : {};
          final double quantity = (exec['quantity'] ?? exec['qty'] ?? item['quantity'] ?? 0.0).toDouble();
          final double price = (exec['price'] ?? item['price'] ?? 0.0).toDouble();
          totalValuation += quantity * price;
        }
      }
    } else {
      // Sum total assets dynamically using same fallback logic as datatable rows
      for (var item in parsedDataList) {
        if (item is Map) {
          final double quantity = (item['quantity'] ?? item['qty'] ?? 0.0).toDouble();
          final double currentPrice = (item['currentPrice'] ?? 
                                       (item['marketData'] != null ? item['marketData']['marketPrice'] : null) ?? 
                                       (item['currentValue'] != null && quantity > 0 ? (item['currentValue'] / quantity) : null) ?? 
                                       item['avgBuyingPrice'] ?? 
                                       item['averagePrice'] ??
                                       item['buyPrice'] ??
                                       item['nav'] ?? 
                                       item['price'] ?? 
                                       0.0).toDouble();
          final double totalValue = item['currentValue'] != null ? (item['currentValue'] as num).toDouble() : quantity * currentPrice;
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
                Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Text(
                  isTrade ? 'Extracted Trade Log Details' : 'Extracted Holdings Details', 
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(_showRawJson ? Icons.visibility_off_outlined : Icons.code_outlined),
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
            _buildResultStatCard(isTrade ? 'TOTAL VOLUME' : 'TOTAL VALUATION', currencyFormatter.format(totalValuation), Icons.account_balance_wallet_outlined, Colors.green),
            const SizedBox(width: 16),
            _buildResultStatCard('PARSED RECORDS', '${parsedDataList.length} Items', Icons.format_list_bulleted_outlined, Colors.blue),
            const SizedBox(width: 16),
            _buildResultStatCard('PROCESS CODE', _lastResult!['processId']?.toString().substring(0, 8).toUpperCase() ?? 'N/A', Icons.vpn_key_outlined, Colors.purple),
          ],
        ),
        
        const SizedBox(height: 24),
        
        if (_showRawJson) ...[
          const Text('Raw JSON Payload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
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
                style: const TextStyle(
                  color: Colors.greenAccent, 
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
                    child: Center(child: Text(isTrade ? 'No trade records found in this file.' : 'No holding assets found in this statement file.')),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                        child: Text(
                          isTrade ? 'TRADE LOG BREAKDOWN' : 'HOLDING ASSETS BREAKDOWN',
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
                                      DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('ASSET / SYMBOL', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('TRADE ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('TYPE', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(numeric: true, label: Text('QTY', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(numeric: true, label: Text('PRICE', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(numeric: true, label: Text('TOTAL AMOUNT', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ]
                                  : const [
                                      DataColumn(label: Text('ASSET / SYMBOL', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('IDENTIFIER', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(numeric: true, label: Text('QTY', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(numeric: true, label: Text('BUY PRICE', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(numeric: true, label: Text('CURRENT PRICE', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(numeric: true, label: Text('TOTAL VALUATION', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                              rows: parsedDataList.map((item) {
                                final map = item is Map ? item : {};
                                
                                if (isTrade) {
                                  final basic = map['basicInfo'] is Map ? map['basicInfo'] : {};
                                  final instrument = map['instrumentInfo'] is Map ? map['instrumentInfo'] : {};
                                  final exec = map['executionInfo'] is Map ? map['executionInfo'] : {};
                                  
                                  final String tradeDate = basic['tradeDate'] ?? basic['orderExecutionTime']?.toString().split('T').first ?? 'N/A';
                                  final String assetName = instrument['symbol'] ?? instrument['name'] ?? map['symbol'] ?? 'Unknown Asset';
                                  final String tradeId = basic['tradeId'] ?? map['tradeId'] ?? 'N/A';
                                  final String tradeType = (exec['tradeType'] ?? basic['tradeType'] ?? map['type'] ?? 'BUY').toString().toUpperCase();
                                  final double quantity = (exec['quantity'] ?? exec['qty'] ?? map['quantity'] ?? 0.0).toDouble();
                                  final double price = (exec['price'] ?? map['price'] ?? 0.0).toDouble();
                                  final double totalValue = quantity * price;

                                  final Color typeColor = tradeType.contains('BUY') ? Colors.green : Colors.red;

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(tradeDate, style: const TextStyle(fontSize: 13))),
                                      DataCell(
                                        Container(
                                          constraints: const BoxConstraints(maxWidth: 220),
                                          child: Text(
                                            assetName, 
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(tradeId, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: typeColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
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
                                      DataCell(Text(quantity.toStringAsFixed(0))),
                                      DataCell(Text(currencyFormatter.format(price))),
                                      DataCell(
                                        Text(
                                          currencyFormatter.format(totalValue),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  final String assetName = map['name'] ?? map['securityName'] ?? map['schemeName'] ?? map['symbol'] ?? 'Unknown Asset';
                                  final String identifier = map['isin'] ?? map['amfiCode'] ?? map['symbol'] ?? 'N/A';
                                  final double quantity = (map['quantity'] ?? map['qty'] ?? 0.0).toDouble();
                                  final double buyPrice = (map['avgBuyingPrice'] ?? map['averagePrice'] ?? map['buyPrice'] ?? map['price'] ?? 0.0).toDouble();
                                  final double currentPrice = (map['currentPrice'] ?? 
                                                              (map['marketData'] != null ? map['marketData']['marketPrice'] : null) ?? 
                                                              (map['currentValue'] != null && quantity > 0 ? (map['currentValue'] / quantity) : null) ?? 
                                                              map['avgBuyingPrice'] ?? 
                                                              map['nav'] ?? 
                                                              map['price'] ?? 
                                                              0.0).toDouble();
                                  final double totalValue = map['currentValue'] != null ? (map['currentValue'] as num).toDouble() : quantity * currentPrice;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Container(
                                          constraints: const BoxConstraints(maxWidth: 220),
                                          child: Text(
                                            assetName, 
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(identifier, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey))),
                                      DataCell(Text(quantity.toStringAsFixed(2))),
                                      DataCell(Text(currencyFormatter.format(buyPrice))),
                                      DataCell(Text(currencyFormatter.format(currentPrice), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(
                                        Text(
                                          currencyFormatter.format(totalValue),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
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

  Widget _buildResultStatCard(String label, String value, IconData icon, Color color) {
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
                    Text(
                      label, 
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  void _showDownloadStepsDialog(BuildContext context, String broker, String docType) {
    String title = 'How to Download Document';
    String url = '';
    List<Widget> steps = [];

    if (broker == 'ZERODHA') {
      if (docType == 'STOCK_PORTFOLIO') {
        url = 'https://console.zerodha.com/portfolio/holdings';
        title = 'Download Zerodha Portfolio';
        steps = [
          _buildStep(1, 'Log in to Zerodha Console and go to Portfolio > Holdings', imagePath: 'assets/images/holdings_step1.png'),
          _buildStep(2, 'Scroll down to the bottom of the page and click "Download: XLSX"', imagePath: 'assets/images/holdings_step2.png'),
          _buildStep(3, 'Upload the downloaded file here'),
        ];
      } else if (docType == 'TRADE_FNO' || docType == 'TRADE_EQ') {
        url = 'https://console.zerodha.com/reports/tradebook';
        title = 'Download Zerodha Tradebook';
        String segment = docType == 'TRADE_FNO' ? 'Futures & Options' : 'Equity';
        steps = [
          _buildStep(1, 'Go to Zerodha Console > Reports > Tradebook', imagePath: 'assets/images/step1.png'),
          _buildStep(2, 'Under the Segment dropdown, select "$segment"', imagePath: 'assets/images/step2.png'),
          _buildStep(3, 'Select your desired Date Range (e.g. current FY) and click the blue arrow (→) button', imagePath: 'assets/images/step3.png'),
          _buildStep(4, 'Scroll down to the results and click "Download: XLSX"', imagePath: 'assets/images/step4.png'),
          _buildStep(5, 'Upload the downloaded file here'),
        ];
      }
    } else if (broker == 'GROWW') {
      if (docType == 'STOCK_PORTFOLIO') {
        url = 'https://groww.in/user/profile/report';
        title = 'Download Groww Stock Holdings';
        steps = [
          _buildStep(1, 'Log in to Groww and click on your Profile picture at the top right', imagePath: 'assets/images/groww_step1.png'),
          _buildStep(2, 'Navigate to the "Holdings" section and select "Stocks - Holdings statement"'),
          _buildStep(3, 'Select the current date and click the "Download" button', imagePath: 'assets/images/groww_step2.png'),
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
          _buildStep(1, 'Log in to Angel One and go to your Profile section', imagePath: 'assets/images/angel_step1.png'),
          _buildStep(2, 'Under Reports, select Statements (or any option) to open the reports page', imagePath: 'assets/images/angel_step2.png'),
          _buildStep(3, 'Navigate to the "Download Reports" tab', imagePath: 'assets/images/angel_step3.png'),
          _buildStep(4, 'In the Others section, click "DOWNLOAD REPORT" for "Combined Holding Statement"', imagePath: 'assets/images/angel_step4.png'),
          _buildStep(5, 'Upload the downloaded file here'),
        ];
      } else if (docType == 'TRADE_EQ') {
        url = 'https://www.angelone.in/trade/reports/download-reports';
        title = 'Download Angel One Trading History';
        steps = [
          _buildStep(1, 'Log in to Angel One and go to your Profile section', imagePath: 'assets/images/angel_step1.png'),
          _buildStep(2, 'Under Reports, select Statements (or any option) to open the reports page', imagePath: 'assets/images/angel_step2.png'),
          _buildStep(3, 'Navigate to the "Download Reports" tab', imagePath: 'assets/images/angel_step3.png'),
          _buildStep(4, 'In the Stocks, SGBs, Bonds and FnO section, click "DOWNLOAD REPORT" for "DP Transaction and Holding Statement"', imagePath: 'assets/images/angel_trade_step4.png'),
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
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                    label: Text('Open ${broker == 'ZERODHA' ? 'Zerodha Console' : broker == 'ANGEL_ONE' ? 'Angel One' : 'Groww'}'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
