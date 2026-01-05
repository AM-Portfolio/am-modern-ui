import 'package:flutter/material.dart';
import 'module_config.dart';
import 'module_context.dart';

/// Interface that all modules must implement
/// Defines the contract for embeddable, self-contained feature modules
abstract class IModule {
  /// Unique identifier for this module (e.g., 'market', 'trade', 'portfolio')
  String get moduleId;

  /// Module configuration (title, icon, color, routes, etc.)
  ModuleConfig get config;

  /// Build the main module UI
  /// @param context - Flutter build context
  /// @param moduleContext - Shared module context (auth, theme, routing)
  Widget build(BuildContext context, ModuleContext moduleContext);

  /// Initialize the module with shared context
  /// Called once when module is first loaded
  /// Use this for any async setup (data loading, service initialization, etc.)
  Future<void> configure(ModuleContext moduleContext);

  /// Cleanup module resources
  /// Called when module is disposed or app is closed
  void dispose();

  /// Module-specific routes
  /// Maps route names to widget builders
  /// Example: {'/holdings': (context) => HoldingsPage()}
  Map<String, WidgetBuilder> get routes => {};

  /// Whether this module requires authentication
  /// If true, module will not load unless user is authenticated
  bool get requiresAuth => true;

  /// Whether this module is enabled
  /// Can be used for feature flags or conditional loading
  bool get isEnabled => true;
}
