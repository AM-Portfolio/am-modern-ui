import 'dart:async';

import 'package:am_library/am_library.dart';
import 'package:growthbook_sdk_flutter/growthbook_sdk_flutter.dart';
import 'package:rxdart/rxdart.dart';

import 'feature_flag_config.dart';

/// Thin GrowthBook wrapper for product rollout flags.
/// Product flags fail closed (default false) when SDK is unavailable.
class FeatureFlagService {
  FeatureFlagService({FeatureFlagConfig config = FeatureFlagConfig.disabled})
      : _config = config;

  /// The GrowthBook SDK has no built-in request timeout, so a slow or
  /// unhealthy backend would otherwise block app startup indefinitely.
  static const _initTimeout = Duration(seconds: 2);

  FeatureFlagConfig _config;
  GrowthBookSDK? _sdk;
  bool _ready = false;
  Map<String, dynamic> _attributes = const {};

  final BehaviorSubject<int> _revision = BehaviorSubject<int>.seeded(0);

  bool get isReady => _ready;

  Stream<void> get changes => _revision.stream.map((_) {});

  FeatureFlagConfig get config => _config;

  Future<void> init({
    FeatureFlagConfig? config,
    Map<String, dynamic> attributes = const {},
  }) async {
    if (config != null) _config = config;
    _attributes = Map<String, dynamic>.from(attributes);

    if (!_config.enabled) {
      _ready = true;
      _bump();
      return;
    }

    final host = _config.apiHost.endsWith('/')
        ? _config.apiHost
        : '${_config.apiHost}/';
    final initFuture = GBSDKBuilderApp(
      apiKey: _config.clientKey,
      hostURL: host,
      attributes: _attributes,
      growthBookTrackingCallBack: (_) {},
      backgroundSync: true,
    ).initialize();

    try {
      _sdk = await initFuture.timeout(_initTimeout);
      _ready = true;
      AppLogger.info(
        'FeatureFlagService: GrowthBook ready (host=${_config.apiHost})',
        tag: 'FeatureFlagService',
      );
    } on TimeoutException {
      _sdk = null;
      _ready = true;
      AppLogger.warning(
        'FeatureFlagService: init exceeded ${_initTimeout.inSeconds}s — '
        'product flags stay off for now, app continues loading',
        tag: 'FeatureFlagService',
      );
      _adoptIfSlowInitSucceeds(initFuture);
    } catch (e, st) {
      _sdk = null;
      _ready = true;
      AppLogger.warning(
        'FeatureFlagService: init failed — product flags stay off',
        tag: 'FeatureFlagService',
        error: e,
        stackTrace: st,
      );
    }
    _bump();
  }

  /// After a startup timeout lets the app continue, still pick up the SDK
  /// if it finishes initializing late so flags can switch on without a
  /// reload.
  void _adoptIfSlowInitSucceeds(Future<GrowthBookSDK> initFuture) {
    initFuture.then((sdk) {
      _sdk = sdk;
      AppLogger.info(
        'FeatureFlagService: GrowthBook became ready after a slow init',
        tag: 'FeatureFlagService',
      );
      _bump();
    }).catchError((Object e, StackTrace st) {
      AppLogger.warning(
        'FeatureFlagService: late init failed',
        tag: 'FeatureFlagService',
        error: e,
        stackTrace: st,
      );
    });
  }

  Future<void> updateAttributes(Map<String, dynamic> attributes) async {
    _attributes = Map<String, dynamic>.from(attributes);
    final sdk = _sdk;
    if (sdk == null) {
      _bump();
      return;
    }
    try {
      sdk.setAttributes(_attributes);
    } catch (e, st) {
      AppLogger.warning(
        'FeatureFlagService: updateAttributes failed',
        tag: 'FeatureFlagService',
        error: e,
        stackTrace: st,
      );
    }
    _bump();
  }

  bool isOn(String key, {bool defaultValue = false}) {
    final sdk = _sdk;
    if (!_config.enabled || sdk == null) return defaultValue;
    try {
      return sdk.feature(key).on;
    } catch (_) {
      return defaultValue;
    }
  }

  void _bump() {
    if (_revision.isClosed) return;
    _revision.add(_revision.value + 1);
  }

  void dispose() {
    if (!_revision.isClosed) _revision.close();
  }
}
