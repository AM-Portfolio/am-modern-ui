import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
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
import 'auth_circular_timer.dart';
import 'auth_dual_glow_frame.dart';
import 'otp_digit_tiles.dart';

/// Prefetched QR session held by [LoginPage] so Scan QR can render instantly.
class PrefetchedQrSession {
  const PrefetchedQrSession({
    required this.session,
    required this.codeVerifier,
  });

  final DeviceLinkPollSession session;
  final String codeVerifier;

  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    return now >= session.expiresAt;
  }
}

Future<PrefetchedQrSession> prefetchQrSession(
  DeviceLinkPollService pollService,
) async {
  final codeVerifier = generateCodeVerifier();
  final challenge = codeChallengeFromVerifier(codeVerifier);
  final session = await pollService.startSession(
    codeVerifier: codeVerifier,
    codeChallenge: challenge,
    browser: kIsWeb ? 'Web' : null,
    os: defaultTargetPlatform.name,
  );
  return PrefetchedQrSession(session: session, codeVerifier: codeVerifier);
}

class WebQrLoginSection extends StatefulWidget {
  const WebQrLoginSection({
    super.key,
    this.prefetched,
    this.prefetchFuture,
    this.isActive = true,
    this.onSessionUpdated,
  });

  /// Session started by the login page (optional). When set and fresh, shown
  /// immediately without a network round-trip.
  final PrefetchedQrSession? prefetched;

  /// In-flight prefetch from [LoginPage]. Awaited instead of a second start.
  final Future<PrefetchedQrSession>? prefetchFuture;

  /// When false, polling is stopped (tab not visible).
  final bool isActive;

  /// Called when this widget creates or refreshes a session so the parent cache
  /// can stay in sync.
  final ValueChanged<PrefetchedQrSession>? onSessionUpdated;

  @override
  State<WebQrLoginSection> createState() => _WebQrLoginSectionState();
}

class _WebQrLoginSectionState extends State<WebQrLoginSection> {
  final FeatureFlags _flags = FeatureFlags();
  late final DeviceLinkPollService _pollService;
  DeviceLinkPollSession? _session;
  DeviceLinkPollState _state = DeviceLinkPollState.waiting;
  String? _errorMessage;
  bool _loading = true;
  bool _refreshing = false;
  Timer? _tickTimer;
  int _remainingSeconds = 0;
  int _totalSeconds = 60;

  /// Bumped when a session is adopted or a newer load starts so stale
  /// `_beginSession` work does not cancel a good QR and flash a spinner.
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _pollService = AuthProviders.deviceLinkPollService;
    if (!_flags.enableQrWebLogin) {
      _loading = false;
      return;
    }
    _adoptOrBegin(widget.prefetched);
  }

  @override
  void didUpdateWidget(covariant WebQrLoginSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prefetched != null &&
        _session == null &&
        !widget.prefetched!.isExpired) {
      _applySession(widget.prefetched!);
    }
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _ensurePolling();
      } else {
        _pollService.stopPolling();
      }
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    _tickTimer?.cancel();
    if (widget.isActive) {
      _pollService.stopPolling();
    }
    super.dispose();
  }

  void _adoptOrBegin(PrefetchedQrSession? prefetched) {
    if (prefetched != null && !prefetched.isExpired) {
      _applySession(prefetched);
      return;
    }
    // Await the login-page prefetch instead of starting a second /start.
    unawaited(_awaitPrefetchOrBegin());
  }

  Future<void> _awaitPrefetchOrBegin() async {
    final future = widget.prefetchFuture;
    if (future != null) {
      try {
        final session = await future;
        if (!mounted || _session != null) return;
        if (!session.isExpired) {
          _applySession(session);
          return;
        }
      } catch (_) {
        // Fall through to a local start.
      }
    }
    if (!mounted || _session != null) return;
    await _beginSession();
  }

  void _applySession(PrefetchedQrSession prefetched) {
    _loadGeneration++;
    _tickTimer?.cancel();
    setState(() {
      _session = prefetched.session;
      _loading = false;
      _refreshing = false;
      _errorMessage = null;
      _state = DeviceLinkPollState.waiting;
      _syncRemaining();
    });
    _startTicker();
    if (widget.isActive) {
      _ensurePolling();
    }
  }

  Future<void> _beginSession() async {
    final generation = ++_loadGeneration;
    // Keep the existing QR on screen while a replacement loads so it does not
    // flash away into a spinner for several hundred ms.
    final keepVisible = _session != null;
    setState(() {
      if (keepVisible) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _errorMessage = null;
      _state = DeviceLinkPollState.waiting;
    });

    try {
      if (generation != _loadGeneration) return;
      await _pollService.cancelActiveSession();
      if (!mounted || generation != _loadGeneration) return;
      final prefetched = await prefetchQrSession(_pollService);
      if (!mounted || generation != _loadGeneration) return;
      widget.onSessionUpdated?.call(prefetched);
      _applySession(prefetched);
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _errorMessage = _pollErrorMessage(error);
        _state = DeviceLinkPollState.error;
      });
    }
  }

  void _ensurePolling() {
    final session = _session;
    if (session == null || !widget.isActive) return;
    _pollService.startPolling(
      session: session,
      onUpdate: _handlePollUpdate,
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = _pollErrorMessage(error);
          _state = DeviceLinkPollState.error;
        });
      },
    );
  }

  void _syncRemaining() {
    final session = _session;
    if (session == null) {
      _remainingSeconds = 0;
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    _remainingSeconds = (session.expiresAt - now).clamp(0, 300).round();
    final createdSpan = _totalSeconds;
    if (_remainingSeconds > createdSpan) {
      _totalSeconds = _remainingSeconds;
    }
  }

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_syncRemaining);
      if (_remainingSeconds <= 0 &&
          widget.isActive &&
          !_refreshing &&
          !_loading) {
        unawaited(_beginSession());
      }
    });
  }

  String _pollErrorMessage(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 429) {
        return 'Too many requests. The QR code will refresh automatically.';
      }
      if (status != null && status >= 500) {
        return 'Sign-in service is temporarily unavailable. Please try again.';
      }
    }
    return 'Could not load the QR code. Please try again.';
  }

  Future<void> _handlePollUpdate(
    DeviceLinkPollState state,
    DeviceLinkPollUser? user, {
    WebSessionTokens? tokens,
  }) async {
    if (!mounted) return;
    if (state == DeviceLinkPollState.expired) {
      if (_refreshing || _loading) return;
      await _beginSession();
      return;
    }
    if (state == DeviceLinkPollState.approved && user != null) {
      await context.read<AuthCubit>().completeWebSession(
        userId: user.sub,
        email: user.email ?? user.preferredUsername ?? user.sub,
        displayName: user.preferredUsername,
        accessToken: tokens?.accessToken,
        refreshToken: tokens?.refreshToken,
        expiresInSeconds: tokens?.expiresIn,
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

    if (_errorMessage != null && _session == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.statusError),
            ),
            TextButton(onPressed: _beginSession, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_loading || _session == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final qrData = jsonEncode(_session!.qrPayload);
    final code = _session!.confirmationCode.replaceAll(RegExp(r'\D'), '');
    final digits = code.length >= 6
        ? code.substring(0, 6)
        : code.padRight(6).substring(0, 6);

    return Column(
      children: [
        AuthPaneFrame(
          footer: AuthCircularTimer(
            remainingSeconds: _remainingSeconds,
            totalSeconds: _totalSeconds,
          ),
          child: Column(
            children: [
              Text(
                'Open the AM app on your phone, scan the QR code, and approve the login.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: _refreshing ? 0.45 : 1,
                      child: AuthQrFrame(
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 160,
                        ),
                      ),
                    ),
                    if (_refreshing)
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: context.colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OtpDigitTiles(digits: digits),
              if (_state != DeviceLinkPollState.waiting) ...[
                const SizedBox(height: 8),
                Text(
                  _state.name,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ],
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
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _refreshing
              ? 'Refreshing QR…'
              : 'Auto-refreshes in ${_remainingSeconds}s',
          style: TextStyle(
            color: context.colors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
