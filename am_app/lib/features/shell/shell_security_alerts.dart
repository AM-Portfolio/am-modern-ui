part of 'app_shell.dart';

/// Web security-alert banner + feature-flag gating.
mixin ShellSecurityAlerts on State<AppShell> {
  Timer? _securityAlertHideTimer;
  StreamSubscription<List<SecurityEventModel>>? _securityEventsSub;
  StreamSubscription<void>? _featureFlagServiceSub;
  SecurityEventModel? _securityAlert;

  bool get _isSecurityAlertBannerEnabled {
    if (FeatureFlags().enableSecurityAlertBanner) {
      return true;
    }
    if (GetIt.instance.isRegistered<common.FeatureFlagService>()) {
      return GetIt.instance<common.FeatureFlagService>().isOn(
        common.FeatureFlagKeys.securityAlertBannerEnabled,
        defaultValue: false,
      );
    }
    return false;
  }

  void _listenToFeatureFlagChanges() {
    if (!GetIt.instance.isRegistered<common.FeatureFlagService>()) return;
    _featureFlagServiceSub ??= GetIt.instance<common.FeatureFlagService>()
        .changes
        .listen((_) {
      if (!mounted) return;
      if (!_isSecurityAlertBannerEnabled) {
        _securityAlertHideTimer?.cancel();
        if (kIsWeb) {
          AuthProviders.securityAlertService.stop();
        }
        if (_securityAlert != null) {
          setState(() => _securityAlert = null);
        }
      } else {
        _startSecurityAlertsIfWeb();
      }
    });
  }

  void _startSecurityAlertsIfWeb() {
    if (!kIsWeb) return;
    if (!_isSecurityAlertBannerEnabled) {
      AuthProviders.securityAlertService.stop();
      _securityAlertHideTimer?.cancel();
      if (_securityAlert != null) {
        setState(() => _securityAlert = null);
      }
      return;
    }
    // Local demo-login review runs: skip new-sign-in banner.
    if (common.DemoLoginConfig.isDevSectionVisible) return;
    final service = AuthProviders.securityAlertService;
    service.start();
    _securityEventsSub ??= service.events.listen((events) {
      if (!mounted) return;
      if (!_isSecurityAlertBannerEnabled) {
        _securityAlertHideTimer?.cancel();
        setState(() => _securityAlert = null);
        return;
      }
      final next = events.isNotEmpty ? events.first : null;
      if (next == null) {
        _securityAlertHideTimer?.cancel();
        setState(() => _securityAlert = null);
        return;
      }
      if (_securityAlert?.eventId == next.eventId) return;
      _presentSecurityAlert(next);
    });
  }

  void _presentSecurityAlert(SecurityEventModel event) {
    _securityAlertHideTimer?.cancel();
    setState(() => _securityAlert = event);
    _securityAlertHideTimer = Timer(const Duration(seconds: 5), () {
      unawaited(_acknowledgeSecurityAlert());
    });
  }

  Future<void> _acknowledgeSecurityAlert() async {
    final alert = _securityAlert;
    if (alert == null) return;
    _securityAlertHideTimer?.cancel();
    await AuthProviders.securityAlertService.acknowledge(alert.eventId);
    if (!mounted) return;
    setState(() => _securityAlert = null);
  }

  void _disposeSecurityAlerts() {
    _featureFlagServiceSub?.cancel();
    _featureFlagServiceSub = null;
    _securityAlertHideTimer?.cancel();
    _securityEventsSub?.cancel();
    _securityEventsSub = null;
    if (kIsWeb) {
      AuthProviders.securityAlertService.stop();
    }
  }
}
