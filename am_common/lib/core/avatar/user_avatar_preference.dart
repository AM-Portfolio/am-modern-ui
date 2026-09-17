import 'avatar_presets.dart';

enum UserAvatarKind {
  /// Letter initials / default person glyph.
  initials,

  /// One of [kAvatarPresets].
  preset,

  /// Locally picked JPEG/PNG (base64 in prefs).
  photo,

  /// Auth provider picture URL (`UserEntity.photoUrl`).
  remote,
}

/// Per-user avatar choice persisted on device / browser.
class UserAvatarPreference {
  const UserAvatarPreference({
    required this.kind,
    this.presetId,
    this.photoBase64,
    this.photoMime = 'image/jpeg',
  });

  final UserAvatarKind kind;
  final String? presetId;
  final String? photoBase64;
  final String photoMime;

  static const initials = UserAvatarPreference(kind: UserAvatarKind.initials);
  static const remote = UserAvatarPreference(kind: UserAvatarKind.remote);

  factory UserAvatarPreference.preset(String id) => UserAvatarPreference(
        kind: UserAvatarKind.preset,
        presetId: id,
      );

  factory UserAvatarPreference.photo({
    required String base64,
    String mime = 'image/jpeg',
  }) =>
      UserAvatarPreference(
        kind: UserAvatarKind.photo,
        photoBase64: base64,
        photoMime: mime,
      );

  AvatarPreset? get preset => avatarPresetById(presetId);

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        if (presetId != null) 'presetId': presetId,
        if (photoBase64 != null) 'photoBase64': photoBase64,
        'photoMime': photoMime,
      };

  factory UserAvatarPreference.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? 'initials';
    final kind = UserAvatarKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => UserAvatarKind.initials,
    );
    return UserAvatarPreference(
      kind: kind,
      presetId: json['presetId'] as String?,
      photoBase64: json['photoBase64'] as String?,
      photoMime: json['photoMime'] as String? ?? 'image/jpeg',
    );
  }
}
