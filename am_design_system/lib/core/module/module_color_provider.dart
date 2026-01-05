import 'package:flutter/material.dart';
import 'module_type.dart';

/// Provides module-specific accent color to descendant widgets via InheritedWidget.
/// 
/// This allows any widget in the tree to access the current module's accent color
/// without explicit prop drilling.
/// 
/// Usage:
/// ```dart
/// ModuleColorProvider(
///   module: ModuleType.trade,
///   child: YourWidget(),
/// )
/// 
/// // In descendant widget:
/// final color = ModuleColorProvider.of(context);
/// ```
class ModuleColorProvider extends InheritedWidget {
  const ModuleColorProvider({
    required this.module,
    required super.child,
    super.key,
  });

  final ModuleType module;

  /// Get the module's accent color
  Color get accentColor => module.accentColor;

  /// Access the nearest ModuleColorProvider in the widget tree
  static Color? maybeOf(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ModuleColorProvider>();
    return provider?.accentColor;
  }

  /// Access the nearest ModuleColorProvider in the widget tree (non-null)
  /// Falls back to Theme primaryColor if no provider found
  static Color of(BuildContext context) {
    return maybeOf(context) ?? Theme.of(context).primaryColor;
  }

  @override
  bool updateShouldNotify(ModuleColorProvider oldWidget) {
    return oldWidget.module != module;
  }
}
