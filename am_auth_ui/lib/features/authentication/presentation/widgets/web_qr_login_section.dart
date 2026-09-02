import 'dart:convert';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:am_design_system/core/config/feature_flags.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';

import '../../../../core/utils/pkce_utils.dart';
import '../../../../di/auth_providers.dart';
import '../../data/models/device_link_models.dart';
import '../../data/services/device_link_poll_service.dart';
import '../cubit/auth_cubit.dart';

class WebQrLoginSection extends StatefulWidget {
  const WebQrLoginSection({super.key});

  @override
  State<WebQrLoginSection> createState() => _WebQrLoginSectionState();
}

class _WebQrLoginSectionState extends State<WebQrLoginSection> {
  final FeatureFlags _flags = FeatureFlags();
  late final DeviceLinkPollService _pollService;
  DeviceLinkPollSession? _session;
  DeviceLinkPollState _state = DeviceLinkPollState.waiting;
  String? _errorMessage;
  String? _codeVerifier;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pollService = AuthProviders.deviceLinkPollService;
    if (_flags.enableQrWebLogin) {
      _beginSession();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _pollService.stopPolling();
    super.dispose();
  }

  Future<void> _beginSession() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _state = DeviceLinkPollState.waiting;
    });

    try {
      await _pollService.cancelActiveSession();
      _codeVerifier = generateCodeVerifier();
      final challenge = codeChallengeFromVerifier(_codeVerifier!);
      final session = await _pollService.startSession(
        codeVerifier: _codeVerifier!,
        codeChallenge: challenge,
        browser: kIsWeb ? 'Web' : null,
        os: defaultTargetPlatform.name,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });
      _pollService.startPolling(
        session: session,
        onUpdate: _handlePollUpdate,
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _errorMessage = error.toString();
            _state = DeviceLinkPollState.error;
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
        _state = DeviceLinkPollState.error;
      });
    }
  }

  Future<void> _handlePollUpdate(
    DeviceLinkPollState state,
    DeviceLinkPollUser? user,
  ) async {
    if (!mounted) return;
    if (state == DeviceLinkPollState.expired) {
      await _beginSession();
      return;
    }
    if (state == DeviceLinkPollState.approved && user != null) {
      await context.read<AuthCubit>().completeWebSession(
        userId: user.sub,
        email: user.email ?? user.preferredUsername ?? user.sub,
        displayName: user.preferredUsername,
      );
      return;
    }
    setState(() => _state = state);
  }

  @override
  Widget build(BuildContext context) {
    if (!_flags.enableQrWebLogin) {
      return const SizedBox.shrink();
    }

    if (_loading || _session == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final qrData = jsonEncode(_session!.qrPayload);
    final remainingSeconds =
        (_session!.expiresAt - DateTime.now().millisecondsSinceEpoch / 1000)
            .clamp(0, 120)
            .round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Scan with the AM app on your phone',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _state == DeviceLinkPollState.waiting
              ? 'Waiting for scan… refreshes in ${remainingSeconds}s'
              : _state.name,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 12),
        Text(
          'Confirm this code on your phone',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          formatConfirmationCode(_session!.confirmationCode),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            letterSpacing: 6,
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.statusError),
          ),
          TextButton(onPressed: _beginSession, child: const Text('Retry')),
        ],
      ],
    );
  }
}
