import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class JournalMoodOptions {
  static Map<String, Map<String, dynamic>> getMoods(BuildContext context) => {
    'confident': {'emoji': '😊', 'label': 'Confident', 'color': context.colors.statusSuccess},
    'neutral': {'emoji': '😐', 'label': 'Neutral', 'color': context.colors.statusNeutral},
    'anxious': {'emoji': '😰', 'label': 'Anxious', 'color': context.colors.statusWarning},
    'frustrated': {'emoji': '😤', 'label': 'Frustrated', 'color': context.colors.statusError},
    'focused': {'emoji': '🎯', 'label': 'Focused', 'color': context.colors.actionPrimaryBg},
    'tired': {'emoji': '😴', 'label': 'Tired', 'color': context.colors.border}, // Fallback for purple
  };

  static Map<String, Map<String, dynamic>> getSentiments(BuildContext context) => {
    'very_bearish': {'icon': Icons.trending_down, 'label': 'Very Bearish', 'color': context.colors.statusError},
    'bearish': {'icon': Icons.south_east, 'label': 'Bearish', 'color': context.colors.statusWarning},
    'neutral': {'icon': Icons.remove, 'label': 'Neutral', 'color': context.colors.statusNeutral},
    'bullish': {'icon': Icons.north_east, 'label': 'Bullish', 'color': context.colors.statusSuccess},
    'very_bullish': {'icon': Icons.trending_up, 'label': 'Very Bullish', 'color': context.colors.statusSuccess},
  };

  static List<Map<String, dynamic>> getTags(BuildContext context) => [
    {'label': 'Breakout', 'color': context.colors.actionPrimaryBg},
    {'label': 'Breakdown', 'color': context.colors.statusError},
    {'label': 'Profit', 'color': context.colors.statusSuccess},
    {'label': 'Loss', 'color': context.colors.statusError},
    {'label': 'Lesson', 'color': context.colors.actionPrimaryBg},
    {'label': 'Mistake', 'color': context.colors.statusWarning},
    {'label': 'Good Entry', 'color': context.colors.statusSuccess},
    {'label': 'Bad Entry', 'color': context.colors.statusError},
    {'label': 'Patience', 'color': context.colors.statusNeutral},
    {'label': 'FOMO', 'color': context.colors.statusError},
    {'label': 'Revenge', 'color': context.colors.statusError},
    {'label': 'Discipline', 'color': context.colors.actionPrimaryBg},
    {'label': 'Analysis', 'color': context.colors.actionPrimaryBg},
    {'label': 'Pattern', 'color': context.colors.statusWarning},
    {'label': 'Support/Resistance', 'color': context.colors.actionPrimaryBg},
  ];

  // Helper properties to access without context if color is not needed
  static const Map<String, Map<String, dynamic>> moodsStatic = {
    'confident': {'emoji': '😊', 'label': 'Confident'},
    'neutral': {'emoji': '😐', 'label': 'Neutral'},
    'anxious': {'emoji': '😰', 'label': 'Anxious'},
    'frustrated': {'emoji': '😤', 'label': 'Frustrated'},
    'focused': {'emoji': '🎯', 'label': 'Focused'},
    'tired': {'emoji': '😴', 'label': 'Tired'},
  };
}
