import '../models/journal_mood_options.dart';

class JournalHelpers {
  /// Convert sentiment key to numeric value (1-9)
  static int getSentimentValue(String? key) {
    if (key == null) return 5;
    switch (key) {
      case 'very_bearish':
        return 1;
      case 'bearish':
        return 3;
      case 'neutral':
        return 5;
      case 'bullish':
        return 7;
      case 'very_bullish':
        return 9;
      default:
        return 5;
    }
  }

  /// Convert mood key to display string (emoji + label)
  static String getMoodString(String? key) {
    if (key == null) return '';
    final mood = JournalMoodOptions.moods[key];
    if (mood == null) return '';
    return '${mood['emoji']} ${mood['label']}';
  }

  /// Map mood string from entry to key
  static String? mapMoodFromEntry(String? moodText) {
    if (moodText == null) return null;
    final lowerMood = moodText.toLowerCase();
    for (final key in JournalMoodOptions.moods.keys) {
      if (lowerMood.contains(key)) {
        return key;
      }
    }
    return null;
  }

  /// Map sentiment numeric value to key
  static String? mapSentimentFromValue(int? value) {
    if (value == null) return null;
    if (value <= 2) {
      return 'very_bearish';
    } else if (value <= 4) {
      return 'bearish';
    } else if (value <= 6) {
      return 'neutral';
    } else if (value <= 8) {
      return 'bullish';
    } else {
      return 'very_bullish';
    }
  }
}
