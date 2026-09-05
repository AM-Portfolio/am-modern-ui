import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_design_system/core/config/feature_flags.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';

import '../../../../di/auth_providers.dart';
import '../../data/models/web_otp_models.dart';
import '../cubit/auth_cubit.dart';
import 'auth_circular_timer.dart';
import 'auth_dual_glow_frame.dart';
import 'auth_method_pill_tabs.dart';
import 'email_login_form_widget.dart';
import 'otp_digit_tiles.dart';

enum WebOtpStep { destination, verify }

class WebOtpLoginWidget extends StatefulWidget {
  const WebOtpLoginWidget({super.key});

  @override
  State<WebOtpLoginWidget> createState() => _WebOtpLoginWidgetState();
}

class _WebOtpLoginWidgetState extends State<WebOtpLoginWidget> {
  final FeatureFlags _flags = FeatureFlags();
  final _destinationController = TextEditingController();
  WebOtpStep _step = WebOtpStep.destination;
  String _channel = 'email';
  WebOtpSendResult? _sendResult;
  String _otpCode = '';
  bool _loading = false;
  String? _error;
  Timer? _tickTimer;
  int _remainingSeconds = 0;
  int _totalSeconds = 60;

  @override
  void dispose() {
    _tickTimer?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  void _startResendTimer(double expiresAt) {
    _tickTimer?.cancel();
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    _remainingSeconds = (expiresAt - now).clamp(0, 600).round();
    _totalSeconds = _remainingSeconds <= 0 ? 60 : _remainingSeconds;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final nowTick = DateTime.now().millisecondsSinceEpoch / 1000;
      setState(() {
        _remainingSeconds = (expiresAt - nowTick).clamp(0, 600).round();
      });
      if (_remainingSeconds <= 0) {
        _tickTimer?.cancel();
      }
    });
  }

  void _cancelTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _remainingSeconds = 0;
  }

  Future<void> _sendOtp() async {
    final channel = _flags.enableSmsOtp ? _channel : 'email';
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      setState(() => _error = channel == 'email'
          ? 'Enter your email address'
          : 'Enter your phone number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _channel = channel;
    });
    try {
      final result = await AuthProviders.identityAuthRemoteDataSource.sendWebOtp(
        channel: channel,
        destination: destination,
      );
      if (!mounted) return;
      setState(() {
        _sendResult = result;
        _step = WebOtpStep.verify;
        _otpCode = '';
        _loading = false;
      });
      _startResendTimer(result.expiresAt);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_sendResult == null || _otpCode.length < 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result =
          await AuthProviders.identityAuthRemoteDataSource.verifyWebOtp(
        otpSessionId: _sendResult!.otpSessionId,
        code: _otpCode.trim(),
      );
      if (!mounted) return;
      await context.read<AuthCubit>().completeWebSession(
        userId: result.user.sub,
        email: result.user.email ??
            result.user.preferredUsername ??
            result.user.sub,
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

  void _resetDestination() {
    _cancelTimer();
    setState(() {
      _step = WebOtpStep.destination;
      _sendResult = null;
      _otpCode = '';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_flags.enableWebOtp) {
      return const SizedBox.shrink();
    }

    final showTimer = _step == WebOtpStep.verify && _sendResult != null;
    final primary = context.colors.actionPrimaryBg;
    final smsEnabled = _flags.enableSmsOtp;
    final channel = smsEnabled ? _channel : 'email';

    return Column(
      children: [
        AuthPaneFrame(
          footer: showTimer
              ? AuthCircularTimer(
                  remainingSeconds: _remainingSeconds,
                  totalSeconds: _totalSeconds,
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                smsEnabled
                    ? 'Sign in with a one-time passcode sent to your email or phone.'
                    : 'Sign in with a one-time passcode sent to your email.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (_step == WebOtpStep.destination) ...[
                if (smsEnabled) ...[
                  AuthMethodPillTabs<String>(
                    compact: true,
                    accentColor: primary,
                    selected: _channel,
                    onChanged: (value) => setState(() => _channel = value),
                    options: const [
                      AuthMethodPillOption(
                        value: 'email',
                        label: 'Email',
                        icon: Icons.email_outlined,
                      ),
                      AuthMethodPillOption(
                        value: 'sms',
                        label: 'SMS',
                        icon: Icons.sms_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                LiquidTextField(
                  controller: _destinationController,
                  enabled: !_loading,
                  keyboardType: channel == 'email'
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  labelText:
                      channel == 'email' ? 'Email address' : 'Phone number',
                  hintText: channel == 'email'
                      ? 'Enter your email'
                      : 'Enter your phone number',
                  prefixIcon: channel == 'email'
                      ? Icons.email_outlined
                      : Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                _PrimaryActionButton(
                  label: 'Send Code',
                  loading: _loading,
                  onPressed: _sendOtp,
                ),
              ] else ...[
                if (_sendResult != null)
                  Text(
                    'Code sent to ${_sendResult!.maskedDestination}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                const SizedBox(height: 14),
                OtpDigitTiles(
                  digits: _otpCode,
                  editable: true,
                  enabled: !_loading,
                  onChanged: (value) {
                    setState(() => _otpCode = value);
                    if (value.length == 6) {
                      unawaited(_verifyOtp());
                    }
                  },
                ),
                const SizedBox(height: 16),
                _PrimaryActionButton(
                  label: 'Verify and sign in',
                  loading: _loading,
                  onPressed: _otpCode.length == 6 ? _verifyOtp : null,
                ),
                TextButton(
                  onPressed: _loading ? null : _resetDestination,
                  child: const Text('Use a different destination'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.statusError),
                ),
              ],
            ],
          ),
        ),
        if (showTimer) ...[
          const SizedBox(height: 8),
          if (_remainingSeconds > 0)
            Text(
              'Resend code in ${_remainingSeconds}s',
              style: TextStyle(
                color: context.colors.textTertiary,
                fontSize: 12,
              ),
            )
          else
            TextButton(
              onPressed: _loading ? null : _sendOtp,
              child: Text(
                'Resend code',
                style: TextStyle(color: primary),
              ),
            ),
        ],
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.loading,
    this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.actionPrimaryBg;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.95),
            primary.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
