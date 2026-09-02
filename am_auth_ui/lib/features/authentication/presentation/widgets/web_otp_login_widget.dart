import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_design_system/core/config/feature_flags.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';

import '../../../../di/auth_providers.dart';
import '../../data/models/web_otp_models.dart';
import '../cubit/auth_cubit.dart';

enum WebOtpStep { destination, verify }

class WebOtpLoginWidget extends StatefulWidget {
  const WebOtpLoginWidget({super.key});

  @override
  State<WebOtpLoginWidget> createState() => _WebOtpLoginWidgetState();
}

class _WebOtpLoginWidgetState extends State<WebOtpLoginWidget> {
  final FeatureFlags _flags = FeatureFlags();
  final _destinationController = TextEditingController();
  final _codeController = TextEditingController();
  WebOtpStep _step = WebOtpStep.destination;
  String _channel = 'email';
  WebOtpSendResult? _sendResult;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _destinationController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final destination = _destinationController.text.trim();
      final result = await AuthProviders.identityAuthRemoteDataSource.sendWebOtp(
        channel: _channel,
        destination: destination,
      );
      if (!mounted) return;
      setState(() {
        _sendResult = result;
        _step = WebOtpStep.verify;
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

  Future<void> _verifyOtp() async {
    if (_sendResult == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result =
          await AuthProviders.identityAuthRemoteDataSource.verifyWebOtp(
        otpSessionId: _sendResult!.otpSessionId,
        code: _codeController.text.trim(),
      );
      if (!mounted) return;
      await context.read<AuthCubit>().completeWebSession(
        userId: result.user.sub,
        email: result.user.email ?? result.user.preferredUsername ?? result.user.sub,
        displayName: result.user.preferredUsername,
        accessToken: result.tokens?.accessToken,
        refreshToken: result.tokens?.refreshToken,
        expiresInSeconds: result.tokens?.expiresIn,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_flags.enableWebOtp) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in with email or SMS',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (_step == WebOtpStep.destination) ...[
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'email', label: Text('Email')),
              ButtonSegment(value: 'sms', label: Text('SMS')),
            ],
            selected: {_channel},
            onSelectionChanged: (selection) {
              setState(() => _channel = selection.first);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _destinationController,
            decoration: InputDecoration(
              labelText: _channel == 'email' ? 'Email address' : 'Phone number',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _sendOtp,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send code'),
          ),
        ] else ...[
          if (_sendResult != null)
            Text(
              'Code sent to ${_sendResult!.maskedDestination}',
              style: TextStyle(color: context.colors.textSecondary),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(labelText: '6-digit code'),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _verifyOtp,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify and sign in'),
          ),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() => _step = WebOtpStep.destination),
            child: const Text('Use a different destination'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: context.colors.statusError),
          ),
        ],
      ],
    );
  }
}
