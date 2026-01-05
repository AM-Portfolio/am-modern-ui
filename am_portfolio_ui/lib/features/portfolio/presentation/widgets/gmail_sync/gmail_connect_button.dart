import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import 'package:am_common/core/utils/logger.dart';
import '../../../providers/gmail_sync_providers.dart';
import 'gmail_sync_modal.dart';

class GmailConnectButton extends ConsumerWidget {
  const GmailConnectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(gmailSyncStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (status.connected) {
          return _buildSyncButton(context, status.email);
        } else {
          return _buildConnectButton(context, ref);
        }
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) {
        CommonLogger.error('Gmail status error', error: error);
        // On error, show connect button to allow retry
        return _buildConnectButton(context, ref);
      },
    );
  }

  Widget _buildConnectButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _handleConnect(context, ref),
      icon: const Icon(Icons.mail_outline, size: 18),
      label: const Text('Connect Gmail'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.red,
        elevation: 0,
        side: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildSyncButton(BuildContext context, String? email) {
    return ElevatedButton.icon(
      onPressed: () => _showSyncModal(context),
      icon: const Icon(Icons.sync, size: 18),
      label: Text('Sync Portfolio${email != null ? ' ($email)' : ''}'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade700,
        elevation: 0,
      ),
    );
  }

  Future<void> _handleConnect(BuildContext context, WidgetRef ref) async {
    try {
      final authUrl = await ref.read(gmailConnectUrlProvider.future);
      final uri = Uri.parse(authUrl);
      
      if (await launcher.canLaunchUrl(uri)) {
        await launcher.launchUrl(
          uri,
          mode: launcher.LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch Gmail login URL')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate connection: $e')),
        );
      }
    }
  }

  void _showSyncModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GmailSyncModal(),
    );
  }
}
