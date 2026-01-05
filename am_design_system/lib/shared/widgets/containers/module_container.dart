
import 'package:flutter/material.dart';

import '../../../core/module/i_module.dart';
import '../../../core/module/module_context.dart';


/// Container widget that wraps a module and handles lifecycle
/// Provides consistent error handling, loading states, and context passing
class ModuleContainer extends StatefulWidget {
  const ModuleContainer({
    required this.module,
    required this.moduleContext,
    super.key,
    this.onModuleError,
    this.loadingWidget,
    this.errorWidget,
  });

  /// The module to wrap
  final IModule module;

  /// Shared context for the module
  final ModuleContext moduleContext;

  /// Callback when module encounters an error
  final Function(Object error, StackTrace stackTrace)? onModuleError;

  /// Custom loading widget (shown during module configuration)
  final Widget? loadingWidget;

  /// Custom error widget builder
  final Widget Function(Object error)? errorWidget;

  @override
  State<ModuleContainer> createState() => _ModuleContainerState();
}

class _ModuleContainerState extends State<ModuleContainer> {
  bool _isConfigured = false;
  bool _isConfiguring = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _configureModule();
  }

  @override
  void dispose() {
    try {
      widget.module.dispose();
    } catch (e) {
      // Silently handle dispose errors
      debugPrint('Error disposing module ${widget.module.moduleId}: $e');
    }
    super.dispose();
  }

  Future<void> _configureModule() async {
    try {
      await widget.module.configure(widget.moduleContext);
      if (mounted) {
        setState(() {
          _isConfigured = true;
          _isConfiguring = false;
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _error = error;
          _isConfiguring = false;
        });
        widget.onModuleError?.call(error, stackTrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state during configuration
    if (_isConfiguring) {
      return widget.loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    // Show error state if configuration failed
    if (_error != null) {
      return widget.errorWidget?.call(_error!) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load module',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isConfiguring = true;
                    });
                    _configureModule();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    // Build the module
    try {
      return widget.module.build(context, widget.moduleContext);
    } catch (error, stackTrace) {
      widget.onModuleError?.call(error, stackTrace);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Module error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}
