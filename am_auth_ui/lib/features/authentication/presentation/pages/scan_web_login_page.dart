import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';

import '../../../../di/auth_providers.dart';

class ScanWebLoginPage extends StatefulWidget {
  const ScanWebLoginPage({super.key});

  @override
  State<ScanWebLoginPage> createState() => _ScanWebLoginPageState();
}

class _ScanWebLoginPageState extends State<ScanWebLoginPage> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    final deviceLinkId =
        AuthProviders.deviceLinkRemoteDataSource.parseDeviceLinkIdFromPayload(raw);
    if (deviceLinkId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not an AM login code')),
      );
      return;
    }

    _handled = true;
    context.push('/app/scan-web-login/confirm?id=$deviceLinkId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Web Login'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(onDetect: _onDetect),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Point at the QR code on your computer screen',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
