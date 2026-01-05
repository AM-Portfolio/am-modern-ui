import 'package:flutter/material.dart';

class JournalMoodOptions {
  static const Map<String, Map<String, dynamic>> moods = {
    'confident': {'emoji': '😊', 'label': 'Confident', 'color': Color(0xFF10B981)},
    'neutral': {'emoji': '😐', 'label': 'Neutral', 'color': Color(0xFF6B7280)},
    'anxious': {'emoji': '😰', 'label': 'Anxious', 'color': Color(0xFFF59E0B)},
    'frustrated': {'emoji': '😤', 'label': 'Frustrated', 'color': Color(0xFFEF4444)},
    'focused': {'emoji': '🎯', 'label': 'Focused', 'color': Color(0xFF3B82F6)},
    'tired': {'emoji': '😴', 'label': 'Tired', 'color': Color(0xFF8B5CF6)},
  };

  static const Map<String, Map<String, dynamic>> sentiments = {
    'very_bearish': {'icon': Icons.trending_down, 'label': 'Very Bearish', 'color': Color(0xFFDC2626)},
    'bearish': {'icon': Icons.south_east, 'label': 'Bearish', 'color': Color(0xFFF97316)},
    'neutral': {'icon': Icons.remove, 'label': 'Neutral', 'color': Color(0xFF6B7280)},
    'bullish': {'icon': Icons.north_east, 'label': 'Bullish', 'color': Color(0xFF10B981)},
    'very_bullish': {'icon': Icons.trending_up, 'label': 'Very Bullish', 'color': Color(0xFF059669)},
  };

  static const List<Map<String, dynamic>> tags = [
    {'label': 'Breakout', 'color': Color(0xFF3B82F6)},
    {'label': 'Breakdown', 'color': Color(0xFFEF4444)},
    {'label': 'Profit', 'color': Color(0xFF10B981)},
    {'label': 'Loss', 'color': Color(0xFFDC2626)},
    {'label': 'Lesson', 'color': Color(0xFF8B5CF6)},
    {'label': 'Mistake', 'color': Color(0xFFF59E0B)},
    {'label': 'Good Entry', 'color': Color(0xFF059669)},
    {'label': 'Bad Entry', 'color': Color(0xFFEF4444)},
    {'label': 'Patience', 'color': Color(0xFF06B6D4)},
    {'label': 'FOMO', 'color': Color(0xFFDC2626)},
    {'label': 'Revenge', 'color': Color(0xFFB91C1C)},
    {'label': 'Discipline', 'color': Color(0xFF0891B2)},
    {'label': 'Analysis', 'color': Color(0xFF7C3AED)},
    {'label': 'Pattern', 'color': Color(0xFFDB2777)},
    {'label': 'Support/Resistance', 'color': Color(0xFF2563EB)},
  ];
}
