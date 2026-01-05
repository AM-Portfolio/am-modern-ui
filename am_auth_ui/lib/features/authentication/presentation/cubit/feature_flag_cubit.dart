import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/core/config/feature_flags.dart';
import 'feature_flag_state.dart';

/// Feature flag Cubit for managing developer controls
class FeatureFlagCubit extends Cubit<FeatureFlagState> {
  FeatureFlagCubit() : super(FeatureFlagState(FeatureFlags()));
  final FeatureFlags _featureFlags = FeatureFlags();

  /// Update a boolean feature flag
  void updateBoolFlag(String flagName, bool value) {
    switch (flagName) {
      case 'useRealGoogleAuth':
        _featureFlags.useRealGoogleAuth = value;
        break;
      case 'useRealBackendAPI':
        _featureFlags.useRealBackendAPI = value;
        break;
      case 'useRealEmailService':
        _featureFlags.useRealEmailService = value;
        break;
      case 'enableMockDelays':
        _featureFlags.enableMockDelays = value;
        break;
      case 'enableErrorSimulation':
        _featureFlags.enableErrorSimulation = value;
        break;
      case 'enableDebugLogging':
        _featureFlags.enableDebugLogging = value;
        break;
      case 'showDeveloperPanel':
        _featureFlags.showDeveloperPanel = value;
        break;
    }
    emit(FeatureFlagState(_featureFlags));
  }

  /// Update mock API delay
  void updateMockDelay(int milliseconds) {
    _featureFlags.mockApiDelayMs = milliseconds;
    emit(FeatureFlagState(_featureFlags));
  }

  /// Update error rates
  void updateErrorRate(String rateType, double rate) {
    switch (rateType) {
      case 'network':
        _featureFlags.networkErrorRate = rate;
        break;
      case 'server':
        _featureFlags.serverErrorRate = rate;
        break;
      case 'auth':
        _featureFlags.authErrorRate = rate;
        break;
    }
    emit(FeatureFlagState(_featureFlags));
  }

  /// Reset all flags to defaults
  void resetToDefaults() {
    _featureFlags.resetToDefaults();
    emit(FeatureFlagState(_featureFlags));
  }

  /// Export configuration
  Map<String, dynamic> exportConfig() => _featureFlags.toJson();

  /// Import configuration
  void importConfig(Map<String, dynamic> config) {
    _featureFlags.fromJson(config);
    emit(FeatureFlagState(_featureFlags));
  }
}
