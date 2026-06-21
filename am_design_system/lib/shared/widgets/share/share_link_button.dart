import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:am_design_system/am_design_system.dart';

/// Copies the current deep-link URL to the clipboard.
class ShareLinkButton extends StatefulWidget {
  const ShareLinkButton({super.key, this.showLabel = false});

  final bool showLabel;

  @override
  State<ShareLinkButton> createState() => _ShareLinkButtonState();
}

class _ShareLinkButtonState extends State<ShareLinkButton> {
  bool _copied = false;

  Future<void> _copyLink() async {
    final link = Uri.base.toString();
    await Clipboard.setData(ClipboardData(text: link));

    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );

    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final icon = _copied ? Icons.check_rounded : Icons.link_rounded;

    if (widget.showLabel) {
      return TextButton.icon(
        onPressed: _copyLink,
        icon: Icon(icon, size: 18),
        label: const Text('Copy link'),
      );
    }

    return IconButton(
      tooltip: 'Copy link',
      onPressed: _copyLink,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(icon, key: ValueKey(_copied)),
      ),
    );
  }
}

/// Copies a module default URL (used by global sidebar long-press).
Future<void> copyShareLink(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Link copied: $url')),
  );
}
