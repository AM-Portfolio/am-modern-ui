import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';

/// A base widget that provides different implementations based on the platform.
///
/// This abstract class helps create widgets that adapt to different platforms
/// while maintaining a consistent API.
abstract class PlatformWidget<I extends Widget, M extends Widget>
    extends StatelessWidget {
  const PlatformWidget({super.key});

  /// Builds the iOS-specific implementation of the widget.
  I buildIosWidget(BuildContext context);

  /// Builds the Material implementation of the widget (Android, web, etc.).
  M buildMaterialWidget(BuildContext context);

  /// Builds the web-specific implementation of the widget.
  /// By default, uses the Material implementation.
  Widget buildWebWidget(BuildContext context) => buildMaterialWidget(context);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return buildWebWidget(context);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return buildIosWidget(context);
    }
    return buildMaterialWidget(context);
  }
}
