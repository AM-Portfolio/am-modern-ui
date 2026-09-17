import 'dart:convert';

import 'package:flutter/material.dart';

import 'avatar_presets.dart';
import 'user_avatar_preference.dart';
import 'user_avatar_store.dart';

/// Renders the user's chosen avatar (preset, photo, remote URL, or initials).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.radius,
    this.userId,
    this.displayName,
    this.remotePhotoUrl,
    this.preference,
    this.showEditBadge = false,
    super.key,
  });

  final double radius;
  final String? userId;
  final String? displayName;
  final String? remotePhotoUrl;

  /// When null, listens to [UserAvatarStore.instance].
  final UserAvatarPreference? preference;
  final bool showEditBadge;

  @override
  Widget build(BuildContext context) {
    if (preference != null) {
      return _AvatarFace(
        radius: radius,
        preference: preference!,
        displayName: displayName,
        remotePhotoUrl: remotePhotoUrl,
        showEditBadge: showEditBadge,
      );
    }

    return ListenableBuilder(
      listenable: UserAvatarStore.instance,
      builder: (context, _) {
        return _AvatarFace(
          radius: radius,
          preference: UserAvatarStore.instance.preference,
          displayName: displayName,
          remotePhotoUrl: remotePhotoUrl,
          showEditBadge: showEditBadge,
        );
      },
    );
  }
}

class _AvatarFace extends StatelessWidget {
  const _AvatarFace({
    required this.radius,
    required this.preference,
    required this.showEditBadge,
    this.displayName,
    this.remotePhotoUrl,
  });

  final double radius;
  final UserAvatarPreference preference;
  final String? displayName;
  final String? remotePhotoUrl;
  final bool showEditBadge;

  @override
  Widget build(BuildContext context) {
    final face = ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: _buildContent(context),
      ),
    );

    if (!showEditBadge) return face;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        face,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (preference.kind) {
      case UserAvatarKind.photo:
        final b64 = preference.photoBase64;
        if (b64 != null && b64.isNotEmpty) {
          try {
            return Image.memory(
              base64Decode(b64),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => _initials(context),
            );
          } catch (_) {
            return _initials(context);
          }
        }
        return _initials(context);
      case UserAvatarKind.preset:
        final preset = preference.preset ?? kAvatarPresets.first;
        return ColoredBox(
          color: preset.background,
          child: Icon(
            preset.icon,
            color: preset.foreground,
            size: radius * 1.05,
          ),
        );
      case UserAvatarKind.remote:
        final url = remotePhotoUrl?.trim();
        if (url != null && url.isNotEmpty) {
          return Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initials(context),
          );
        }
        return _initials(context);
      case UserAvatarKind.initials:
        return _initials(context);
    }
  }

  Widget _initials(BuildContext context) {
    final raw = (displayName ?? 'U').trim();
    final letter = raw.isEmpty ? 'U' : raw[0].toUpperCase();
    return ColoredBox(
      color: const Color(0xFF2C2F36),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.85,
          ),
        ),
      ),
    );
  }
}
