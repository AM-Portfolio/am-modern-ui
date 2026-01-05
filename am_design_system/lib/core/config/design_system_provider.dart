import 'package:flutter/material.dart';
import 'design_system_config.dart';

/// Provider to expose [DesignSystemConfig] to the widget tree.
class DesignSystemProvider extends InheritedWidget {
  final DesignSystemConfig config;

  const DesignSystemProvider({
    required this.config,
    required super.child,
    super.key,
  });

  static DesignSystemConfig of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<DesignSystemProvider>();
    if (provider == null) {
      // Fallback to default if not provided (safety net)
      return DefaultDesignSystem();
    }
    return provider.config;
  }

  @override
  bool updateShouldNotify(DesignSystemProvider oldWidget) {
    return config != oldWidget.config;
  }
}
