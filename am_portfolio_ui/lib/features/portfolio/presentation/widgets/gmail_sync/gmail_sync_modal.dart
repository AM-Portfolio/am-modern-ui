import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:am_common/core/utils/logger.dart';
import '../../../providers/gmail_sync_providers.dart';

class GmailSyncModal extends ConsumerStatefulWidget {
  const GmailSyncModal({super.key});

  @override
  ConsumerState<GmailSyncModal> createState() => _GmailSyncModalState();
}

class _GmailSyncModalState extends ConsumerState<GmailSyncModal> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();
  
  String _selectedBroker = 'zerodha';
  
  // Broker options mapping: value -> display label
  final Map<String, String> _brokers = {
    'zerodha': 'Zerodha',
    'groww': 'Groww',
    'angleone': 'Angel One',
    'dhan': 'Dhan',
    'mstock': 'mStock',
  };

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the sync state to show loading/error
    final syncState = ref.watch(gmailPortfolioSyncProvider);
    final isLoading = syncState.isLoading;

    return AlertDialog(
      title: const Text('Sync Portfolio'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fetch your portfolio holdings from your broker email statements provided heavily by Gmail integration.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              
              // Broker Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBroker,
                decoration: const InputDecoration(
                  labelText: 'Select Broker',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _brokers.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: isLoading ? null : (value) {
                  if (value != null) {
                    setState(() {
                      _selectedBroker = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // PAN Input
              TextFormField(
                controller: _panController,
                decoration: const InputDecoration(
                  labelText: 'PAN Number',
                  hintText: 'ABCD1234F',
                  border: OutlineInputBorder(),
                  helperText: 'Required for verification',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  // AngelOne might not need PAN according to spec, but enforcing for others
                  if (_selectedBroker != 'angleone') {
                    if (value == null || value.isEmpty) {
                      return 'PAN is required';
                    }
                    if (value.length != 10) {
                      return 'Invalid PAN format';
                    }
                  }
                  return null;
                },
                enabled: !isLoading,
              ),
              
              if (syncState.hasError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 20, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getErrorMessage(syncState.error),
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _handleSync,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Scan & Sync'),
        ),
      ],
    );
  }

  String _getErrorMessage(Object? error) {
    // Customize error messages based on exception type if needed
    return error.toString();
  }

  Future<void> _handleSync() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final count = await ref.read(gmailPortfolioSyncProvider.notifier).syncPortfolio(
        broker: _selectedBroker,
        pan: _panController.text.toUpperCase(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully synced $count holdings from $_selectedBroker'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh portfolio data here if needed, or let real-time streams handle it
      }
    } catch (e) {
      // Error handled in UI via syncState
      CommonLogger.error('Sync failed', error: e);
    }
  }
}
