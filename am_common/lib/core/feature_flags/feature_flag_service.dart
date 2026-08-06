import 'package:am_library/am_library.dart';
import 'package:growthbook_sdk_flutter/growthbook_sdk_flutter.dart';
import 'package:rxdart/rxdart.dart';

import 'feature_flag_config.dart';

/// Thin GrowthBook wrapper for product rollout flags.
/// Product flags fail closed (default false) when SDK is unavailable.
class FeatureFlagService {
  FeatureFlagService({FeatureFlagConfig config = FeatureFlagConfig.disabled})
      : _config = config;

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

    try {
      final host = _config.apiHost.endsWith('/')
          ? _config.apiHost
          : '${_config.apiHost}/';
      _sdk = await GBSDKBuilderApp(
        apiKey: _config.clientKey,
        hostURL: host,
        attributes: _attributes,
        growthBookTrackingCallBack: (_) {},
        backgroundSync: true,
      ).initialize();
      _ready = true;
      AppLogger.info(
        'FeatureFlagService: GrowthBook ready (host=${_config.apiHost})',
        tag: 'FeatureFlagService',
      );
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
