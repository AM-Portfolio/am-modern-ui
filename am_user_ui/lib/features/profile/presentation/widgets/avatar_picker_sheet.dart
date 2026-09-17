import 'dart:convert';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Bottom sheet: pick a preset avatar or upload a photo.
Future<void> showAvatarPickerSheet({
  required BuildContext context,
  required String userId,
  String? displayName,
  String? remotePhotoUrl,
}) async {
  await UserAvatarStore.instance.loadForUser(userId);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AvatarPickerSheet(
      displayName: displayName,
      remotePhotoUrl: remotePhotoUrl,
    ),
  );
}

class _AvatarPickerSheet extends StatefulWidget {
  const _AvatarPickerSheet({
    this.displayName,
    this.remotePhotoUrl,
  });

  final String? displayName;
  final String? remotePhotoUrl;

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  bool _busy = false;

  UserAvatarPreference get _current => UserAvatarStore.instance.preference;

  Future<void> _apply(UserAvatarPreference next) async {
    setState(() => _busy = true);
    try {
      await UserAvatarStore.instance.setPreference(next);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto() async {
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 72,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      if (b64.length > UserAvatarStore.maxPhotoBase64Chars) {
        throw StateError('Photo is too large. Try a smaller image.');
      }
      final mime = (file.mimeType?.startsWith('image/') ?? false)
          ? file.mimeType!
          : 'image/jpeg';
      await _apply(UserAvatarPreference.photo(base64: b64, mime: mime));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('too large')
                ? 'Photo is too large. Try a smaller image.'
                : 'Could not use that photo. Try another.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasRemote =
        widget.remotePhotoUrl != null && widget.remotePhotoUrl!.trim().isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181D) : colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose your avatar',
                      style: context.text.sectionTitle().copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_busy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Use a photo or pick a style. Saved on this device.',
                style: context.text.bodyMuted().copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _pickPhoto,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Upload photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.button,
                        ),
                      ),
                    ),
                  ),
                  if (hasRemote) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _apply(UserAvatarPreference.remote),
                        icon: const Icon(Icons.account_circle_outlined, size: 18),
                        label: const Text('Account photo'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ModuleColors.portfolio,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.button,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _apply(UserAvatarPreference.initials),
              child: Text(
                'Use initials instead',
                style: context.text.body().copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'STYLES',
                  style: context.text.caption().copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            Flexible(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: kAvatarPresets.length,
                itemBuilder: (context, index) {
                  final preset = kAvatarPresets[index];
                  final selected = _current.kind == UserAvatarKind.preset &&
                      _current.presetId == preset.id;
                  return InkWell(
                    onTap: _busy
                        ? null
                        : () => _apply(UserAvatarPreference.preset(preset.id)),
                    borderRadius: AppRadii.button,
                    child: Column(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: preset.background,
                              border: Border.all(
                                color: selected
                                    ? ModuleColors.portfolio
                                    : colors.border.withValues(alpha: 0.4),
                                width: selected ? 3 : 1,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: ModuleColors.portfolio
                                            .withValues(alpha: 0.35),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              preset.icon,
                              color: preset.foreground,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          preset.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.caption().copyWith(
                            color: selected
                                ? ModuleColors.portfolio
                                : colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
