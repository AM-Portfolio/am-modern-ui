import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';

import '../../../../core/utils/pkce_utils.dart';
import '../../../../di/auth_providers.dart';
import '../../data/models/device_link_models.dart';

class ScanWebLoginConfirmPage extends StatefulWidget {
  const ScanWebLoginConfirmPage({
    required this.deviceLinkId,
    super.key,
  });

  final String deviceLinkId;

  @override
  State<ScanWebLoginConfirmPage> createState() =>
      _ScanWebLoginConfirmPageState();
}

class _ScanWebLoginConfirmPageState extends State<ScanWebLoginConfirmPage> {
  DeviceLinkPreview? _preview;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final _machineLabelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void dispose() {
    _machineLabelController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    try {
      final preview = await AuthProviders.deviceLinkRemoteDataSource.preview(
        widget.deviceLinkId,
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _approve() async {
    final preview = _preview;
    if (preview == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final unlocked = await AuthProviders.appLockService.unlock();
      if (!unlocked) {
        throw StateError('Biometric unlock required');
      }

      await AuthProviders.deviceLinkRemoteDataSource.approve(
        deviceLinkId: widget.deviceLinkId,
        confirmationCode: preview.confirmationCode,
        machineLabel: _machineLabelController.text.trim().isEmpty
            ? null
            : _machineLabelController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web login approved')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _deny() async {
    await AuthProviders.deviceLinkRemoteDataSource.deny(
      widget.deviceLinkId,
      reason: 'not_me',
    );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm web login')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _preview == null
              ? Center(child: Text(_error ?? 'Unable to load preview'))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _preview!.host,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Code: ${formatConfirmationCode(_preview!.confirmationCode)}',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (_preview!.browser != null) _preview!.browser,
                          if (_preview!.os != null) _preview!.os,
                        ].whereType<String>().join(' · '),
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (_preview!.geoCity != null) _preview!.geoCity,
                          if (_preview!.geoCountry != null) _preview!.geoCountry,
                        ].whereType<String>().join(', '),
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                      if (_preview!.isNewDevice) ...[
                        const SizedBox(height: 8),
                        Text(
                          'First time this device',
                          style: TextStyle(color: context.colors.statusWarning),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: _machineLabelController,
                        decoration: const InputDecoration(
                          labelText: 'Label (optional)',
                          hintText: 'Office laptop',
                        ),
                      ),
                      const Spacer(),
                      if (_error != null)
                        Text(
                          _error!,
                          style: TextStyle(color: context.colors.statusError),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting ? null : _deny,
                              child: const Text('Not me'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _submitting ? null : _approve,
                              child: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
