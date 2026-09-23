import 'package:flutter/material.dart';

/// Caps News section height so siblings in a [Column] (e.g. holdings lists)
/// are not crushed when many story cards load.
class NewsSectionViewport extends StatelessWidget {
  const NewsSectionViewport({
    super.key,
    required this.child,
    this.maxHeightFraction = 0.36,
  });

  final Widget child;
  final double maxHeightFraction;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final maxH = (screenH * maxHeightFraction).clamp(160.0, 420.0);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: ListView(
        primary: false,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [child],
      ),
    );
  }
}
