import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class CreateWatchlistDialog extends StatefulWidget {
  final ValueChanged<String> onCreated;

  const CreateWatchlistDialog({
    super.key,
    required this.onCreated,
  });

  static Future<void> show(BuildContext context, {required ValueChanged<String> onCreated}) {
    return showDialog(
      context: context,
      builder: (context) => CreateWatchlistDialog(onCreated: onCreated),
    );
  }

  @override
  State<CreateWatchlistDialog> createState() => _CreateWatchlistDialogState();
}

class _CreateWatchlistDialogState extends State<CreateWatchlistDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCreate() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onCreated(text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.playlist_add_rounded, color: ModuleColors.market, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Create Watchlist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Enter a name for your new watchlist.',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Bluechip Stocks, Energy',
                hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: colors.scaffoldBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: ModuleColors.market, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _handleCreate(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ModuleColors.market,
                    foregroundColor: colors.actionPrimaryFg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
