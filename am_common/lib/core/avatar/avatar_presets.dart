import 'package:flutter/material.dart';

/// Built-in avatar styles users can pick instead of a photo.
class AvatarPreset {
  const AvatarPreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
}

/// Curated preset set — no asset pack required.
const List<AvatarPreset> kAvatarPresets = [
  AvatarPreset(
    id: 'bolt',
    label: 'Bolt',
    icon: Icons.bolt_rounded,
    background: Color(0xFF1B3A4B),
    foreground: Color(0xFF5EEAD4),
  ),
  AvatarPreset(
    id: 'rocket',
    label: 'Rocket',
    icon: Icons.rocket_launch_rounded,
    background: Color(0xFF2A1F4D),
    foreground: Color(0xFFC4B5FD),
  ),
  AvatarPreset(
    id: 'star',
    label: 'Star',
    icon: Icons.star_rounded,
    background: Color(0xFF3D2A1A),
    foreground: Color(0xFFFBBF24),
  ),
  AvatarPreset(
    id: 'leaf',
    label: 'Leaf',
    icon: Icons.eco_rounded,
    background: Color(0xFF143528),
    foreground: Color(0xFF86EFAC),
  ),
  AvatarPreset(
    id: 'waves',
    label: 'Waves',
    icon: Icons.waves_rounded,
    background: Color(0xFF0F2A3A),
    foreground: Color(0xFF7DD3FC),
  ),
  AvatarPreset(
    id: 'flame',
    label: 'Flame',
    icon: Icons.local_fire_department_rounded,
    background: Color(0xFF3B1A1A),
    foreground: Color(0xFFFB7185),
  ),
  AvatarPreset(
    id: 'chess',
    label: 'Focus',
    icon: Icons.psychology_alt_rounded,
    background: Color(0xFF1E293B),
    foreground: Color(0xFF93C5FD),
  ),
  AvatarPreset(
    id: 'chart',
    label: 'Markets',
    icon: Icons.show_chart_rounded,
    background: Color(0xFF1A2E22),
    foreground: Color(0xFF6EE7B7),
  ),
  AvatarPreset(
    id: 'coffee',
    label: 'Coffee',
    icon: Icons.coffee_rounded,
    background: Color(0xFF2C2118),
    foreground: Color(0xFFD6B48C),
  ),
  AvatarPreset(
    id: 'music',
    label: 'Music',
    icon: Icons.music_note_rounded,
    background: Color(0xFF2A1838),
    foreground: Color(0xFFF0ABFC),
  ),
  AvatarPreset(
    id: 'travel',
    label: 'Travel',
    icon: Icons.flight_takeoff_rounded,
    background: Color(0xFF15253A),
    foreground: Color(0xFF67E8F9),
  ),
  AvatarPreset(
    id: 'pets',
    label: 'Pets',
    icon: Icons.pets_rounded,
    background: Color(0xFF2A2418),
    foreground: Color(0xFFFCD34D),
  ),
];

AvatarPreset? avatarPresetById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final p in kAvatarPresets) {
    if (p.id == id) return p;
  }
  return null;
}
