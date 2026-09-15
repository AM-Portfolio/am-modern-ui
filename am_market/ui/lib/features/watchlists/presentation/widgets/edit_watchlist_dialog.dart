import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class EditWatchlistDialog extends StatefulWidget {
  final String currentName;
  final ValueChanged<String> onSaved;

  const EditWatchlistDialog({
    super.key,
    required this.currentName,
    required this.onSaved,
  });

  static Future<void> show(BuildContext context, {
    required String currentName,
    required ValueChanged<String> onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditWatchlistDialog(
        currentName: currentName,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<EditWatchlistDialog> createState() => _EditWatchlistDialogState();
}

class _EditWatchlistDialogState extends State<EditWatchlistDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final text = _controller.text.trim();
    if (text.isEmpty || text == widget.currentName) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSaving = true);
    widget.onSaved(text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Watchlist Name',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Watchlist Name',
                  hintText: 'Enter new name...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: ModuleColors.market, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (_) => _handleSave(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ModuleColors.market,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
