import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_doc_intelligence_ui/services/api_service.dart';

class EmailExtractorView extends StatefulWidget {
  const EmailExtractorView({super.key});

  @override
  State<EmailExtractorView> createState() => _EmailExtractorViewState();
}

class _EmailExtractorViewState extends State<EmailExtractorView> {
  List<Map<String, dynamic>> _brokers = [];
  bool _loading = true;
  String _status = '';
  Map<String, dynamic>? _gmailStatus;
  
  // Health
  bool? _isServiceConnected;
  bool _checkingHealth = true;
  String? _activeExtractingBrokerId;
  
  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();
    _checkHealthAndLoad();
    
    // Periodically poll Gmail status to see if OAuth succeeded in the other window
    _statusPollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isServiceConnected == true) {
        _checkGmail();
      }
    });
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkHealthAndLoad() async {
    setState(() => _checkingHealth = true);
    final isConnected = await apiProvider.checkEmailExtractorHealth();
    
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
      
      setState(() {
        _brokers = List<Map<String, dynamic>>.from(brokersData['brokers']);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading data: $e';
        _loading = false;
      });
    }
  }

  Future<void> _checkGmail() async {
    try {
      final status = await apiProvider.checkGmailStatus();
      setState(() {
        _gmailStatus = status;
      });
    } catch (e) {
       debugPrint('Gmail check error: $e');
    }
  }

  Future<void> _handleGmailConnectionToggle(bool isConnected) async {
    setState(() {
      _status = isConnected ? 'Disconnecting Gmail account...' : 'Initiating Google OAuth connection...';
    });
    
    try {
      if (isConnected) {
        final result = await apiProvider.disconnectGmail();
        setState(() {
          _status = result['message'] ?? 'Gmail disconnected successfully!';
        });
        await _checkGmail();
      } else {
        final result = await apiProvider.connectGmail();
        if (result['connected'] == true) {
          setState(() {
            _status = 'Gmail already connected!';
          });
          await _checkGmail();
        } else if (result['auth_url'] != null) {
          final String authUrl = result['auth_url'];
          // Open OAuth in new tab
          html.window.open(authUrl, '_blank');
          setState(() {
            _status = 'Please complete the Google OAuth sign-in in the newly opened tab.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _extract(String brokerId) async {
    setState(() {
      _activeExtractingBrokerId = brokerId;
      _status = 'Fetching latest email from ${brokerId.toUpperCase()} & scanning for statements...';
    });
    
    try {
      final result = await apiProvider.extractFromGmail(brokerId);
      setState(() {
        _status = 'Extraction successful!\n- Parsed ${result['count']} holdings\n- Saved Portfolio ID: ${result['db_id']}';
        _activeExtractingBrokerId = null;
      });
    } catch (e) {
      setState(() {
        _status = 'Extraction failed: $e';
        _activeExtractingBrokerId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isConnected = _gmailStatus?['connected'] == true;
    String email = _gmailStatus?['email'] ?? 'Not Connected';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
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
                    Text('Checking email extractor connectivity...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else if (_isServiceConnected == false)
             _buildConnectionError()
          else ...[
            _buildGmailStatusCard(isConnected, email),
            const SizedBox(height: 32),
            Row(
              children: [
                Icon(Icons.list_alt_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Available Broker Profiles', 
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
               const ShimmerLoading(child: SkeletonBox(height: 180, width: double.infinity))
            else
               _buildBrokerGrid(isConnected),
            const SizedBox(height: 28),
            _buildStatusLog(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    Color statusColor = _isServiceConnected == true ? Colors.green : (_isServiceConnected == false ? Colors.red : Colors.grey);
    String statusText = _isServiceConnected == true ? 'Online' : (_isServiceConnected == false ? 'Offline' : 'Checking...');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email Extractor',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
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
        ),
        Container(
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
        )
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
            Icon(Icons.mail_lock_outlined, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 20),
            Text(
              'Email Extraction Service Offline',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The Email Extractor backend in the "${apiProvider.environment == AppEnvironment.local ? "Local" : "Dev"}" environment is unreachable.',
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

  Widget _buildGmailStatusCard(bool isConnected, String email) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isConnected ? Colors.green : Colors.amber).withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: (isConnected ? Colors.green : Colors.amber).withOpacity(0.3)),
              ),
              child: Icon(
                isConnected ? Icons.verified_user_outlined : Icons.lock_open_outlined,
                color: isConnected ? Colors.green : Colors.amber,
                size: 32,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'GMAIL MAILBOX CONNECTED' : 'SECURE GMAIL INTEGRATION REQUIRED',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 11, 
                      letterSpacing: 0.8,
                      color: isConnected ? Colors.green : Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected ? email : 'Authorize read-only statement scanning to extract holdings automatically.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            AppButton(
              text: isConnected ? 'Disconnect Access' : 'Authenticate Google Mail',
              onPressed: () => _handleGmailConnectionToggle(isConnected),
              type: isConnected ? AppButtonType.secondary : AppButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrokerGrid(bool isConnected) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _brokers.length,
      itemBuilder: (context, index) {
        final broker = _brokers[index];
        final String brokerId = broker['id'];
        final String brokerName = broker['name'];
        final String format = broker['format'];
        final bool isCurrentlyExtracting = _activeExtractingBrokerId == brokerId;

        // Custom colors/icons per broker
        Color brokerColor = Theme.of(context).colorScheme.primary;
        IconData brokerIcon = Icons.account_balance_outlined;
        if (brokerId == 'zerodha') {
          brokerColor = Colors.blue;
          brokerIcon = Icons.auto_graph_outlined;
        } else if (brokerId == 'groww') {
          brokerColor = Colors.teal;
          brokerIcon = Icons.show_chart_outlined;
        } else if (brokerId == 'angleone') {
          brokerColor = Colors.deepOrange;
          brokerIcon = Icons.analytics_outlined;
        }

        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: brokerColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(brokerIcon, color: brokerColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(brokerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              format, 
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                isCurrentlyExtracting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: isConnected ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : Colors.grey.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: isConnected ? () => _extract(brokerId) : null,
                          icon: Icon(
                            Icons.arrow_circle_down_outlined, 
                            color: isConnected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.4)
                          ),
                          tooltip: isConnected ? 'Extract holdings from mailbox' : 'Connect Gmail to enable mailbox scanning',
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusLog() {
    if (_status.isEmpty) return const SizedBox.shrink();
    
    bool isError = _status.toLowerCase().contains('failed') || _status.toLowerCase().contains('error');
    Color statusColor = isError ? Colors.red : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isError ? Icons.error_outline : Icons.terminal_outlined, color: statusColor, size: 20),
              const SizedBox(width: 12),
              Text(
                'EXTRACTION AUDIT LOG', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 11, 
                  letterSpacing: 0.8, 
                  color: statusColor
                )
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _status, 
            style: TextStyle(
              color: isError ? Colors.red : Colors.black87, 
              fontFamily: 'monospace', 
              fontSize: 12,
              height: 1.4,
            )
          ),
        ],
      ),
    );
  }
}
