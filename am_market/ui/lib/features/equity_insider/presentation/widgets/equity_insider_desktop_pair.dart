import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// 60/40 row.
///
/// [matchHeight] copies the left child's height onto the right.
/// [matchFromRight] copies the right child's height onto the left (stable
/// chart, KPIs fill the same box so row gaps stay even).
/// When both are false, each card sizes to its own content.
class EquityInsiderDesktopPair extends StatefulWidget {
  const EquityInsiderDesktopPair({
    super.key,
    required this.left,
    required this.right,
    this.gap = AppSpacing.md,
    this.fallbackHeight = 280,
    this.matchHeight = true,
    this.matchFromRight = false,
  });

  final Widget left;
  final Widget right;
  final double gap;
  final double fallbackHeight;
  final bool matchHeight;
  final bool matchFromRight;

  @override
  State<EquityInsiderDesktopPair> createState() =>
      _EquityInsiderDesktopPairState();
}

class _EquityInsiderDesktopPairState extends State<EquityInsiderDesktopPair> {
  final _leftKey = GlobalKey();
  final _rightKey = GlobalKey();
  double _height = 280;

  bool get _copiesRight => widget.matchFromRight;
  bool get _copiesLeft => widget.matchHeight && !widget.matchFromRight;

  @override
  void initState() {
    super.initState();
    _height = widget.fallbackHeight;
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  @override
  void didUpdateWidget(covariant EquityInsiderDesktopPair oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  void _measure(Duration _) {
    if (!_copiesLeft && !_copiesRight) return;
    if (!mounted) return;
    final key = _copiesRight ? _rightKey : _leftKey;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final h = box.size.height;
    if (h <= 0) return;
    final next = h < widget.fallbackHeight ? widget.fallbackHeight : h;
    if ((next - _height).abs() > 0.5) {
      setState(() => _height = next);
      WidgetsBinding.instance.addPostFrameCallback(_measure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 60,
          child: _copiesRight
              ? SizedBox(height: _height, child: widget.left)
              : KeyedSubtree(key: _leftKey, child: widget.left),
        ),
        SizedBox(width: widget.gap),
        Expanded(
          flex: 40,
          child: _copiesRight
              ? KeyedSubtree(key: _rightKey, child: widget.right)
              : _copiesLeft
                  ? SizedBox(height: _height, child: widget.right)
                  : widget.right,
        ),
      ],
    );
  }
}
