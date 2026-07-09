import 'package:flutter/material.dart';

/// Loads a deferred Dart library once, then builds [builder].
///
/// When [skeleton] is set, loading state fills the shell content area only
/// (no full-screen scaffold) so sidebar/nav stay visible.
class DeferredModuleLoader extends StatefulWidget {
  const DeferredModuleLoader({
    required this.load,
    required this.builder,
    this.skeleton,
    this.loadingMessage = 'Loading module…',
    super.key,
  });

  final Future<void> Function() load;
  final Widget Function() builder;
  final Widget? skeleton;
  final String loadingMessage;

  @override
  State<DeferredModuleLoader> createState() => _DeferredModuleLoaderState();
}

class _DeferredModuleLoaderState extends State<DeferredModuleLoader> {
  late final Future<void> _loadFuture = widget.load();

  Widget _defaultLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF6366F1)),
          const SizedBox(height: 16),
          Text(
            widget.loadingMessage,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.skeleton ?? _defaultLoading();
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                'Failed to load module:\n${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        return widget.builder();
      },
    );
  }
}
