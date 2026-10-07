import 'package:flutter/material.dart';

/// Central semantic color tokens for IPO Center in the AM Design System.
///
/// Used across IPO screens, KPI stats bars, summary cards, timeline steppers,
/// filter toolbars, document cards, and registrar detail views.
abstract final class IpoColors {
  // ==========================================================================
  // BADGES & BOARD TYPES
  // ==========================================================================
  static const Color smeBadge = Color(0xFF06B6D4); // Cyan
  static const Color mainboardBadge = Color(0xFF8B5CF6); // Purple

  // ==========================================================================
  // KPI STATS & METRIC HIGHLIGHTS
  // ==========================================================================
  static const Color dotOpen = Color(0xFF06B6D4); // Cyan
  static const Color dotUpcoming = Color(0xFFFBBF24); // Amber
  static const Color dotClosed = Color(0xFF94A3B8); // Slate
  static const Color dotListed = Color(0xFF10B981); // Emerald
  static const Color dotRaised = Color(0xFF8B5CF6); // Violet

  // ==========================================================================
  // STATUS INDICATORS
  // ==========================================================================
  static const Color statusOpen = Color(0xFF06B6D4);
  static const Color statusClosingSoon = Color(0xFFFB923C);
  static const Color statusUpcoming = Color(0xFFFBBF24);
  static const Color statusClosed = Color(0xFF64748B);
  static const Color statusListed = Color(0xFF10B981);

  // ==========================================================================
  // SUBSCRIPTION PROGRESS
  // ==========================================================================
  static const Color progressTrack = Color(0xFF334155);
  static const Color progressSubscribed = Color(0xFF4ADE80);
  static const Color progressSubscribedLight = Color(0xFF16A34A);
  static const Color progressUnderSubscribed = Color(0xFFF87171);
  static const Color progressUnderSubscribedLight = Color(0xFFDC2626);

  // ==========================================================================
  // TIMELINE STEPPER & MILESTONES
  // ==========================================================================
  static const Color stepCompleted = Color(0xFF10B981);
  static const Color stepActive = Color(0xFF06B6D4);
  static const Color stepPending = Color(0xFF475569);
  static const Color stepLineCompleted = Color(0xFF059669);
  static const Color stepLinePending = Color(0xFF334155);

  // ==========================================================================
  // ICONS & ACCENTS
  // ==========================================================================
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color docRhpBg = Color(0xFF1E293B);
  static const Color docRhpText = Color(0xFF38BDF8);

  // ==========================================================================
  // CARD SURFACES & BORDERS (DARK MODE)
  // ==========================================================================
  static const Color darkCardBg = Color(0xFF0F172A);
  static const Color darkCardBorder = Color(0xFF1E293B);
  static const Color darkInnerCardBg = Color(0xFF131D31);

  // ==========================================================================
  // AVATAR DETERMINISTIC PALETTE
  // ==========================================================================
  static const List<Color> avatarColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF06B6D4), // Cyan
    Color(0xFF6366F1), // Indigo
    Color(0xFF14B8A6), // Teal
  ];

  /// Get deterministic avatar color from string identifier
  static Color avatarColorFor(String name) {
    if (name.isEmpty) return avatarColors.first;
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return avatarColors[hash.abs() % avatarColors.length];
  }
}
