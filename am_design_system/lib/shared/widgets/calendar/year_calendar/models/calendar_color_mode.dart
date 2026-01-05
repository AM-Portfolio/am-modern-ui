/// Color modes for calendar visualization
enum CalendarColorMode {
  /// Color by win/loss status (green/red/gray)
  winLoss,

  /// Color by profit intensity (more profit = darker green, more loss = darker red)
  profitIntensity,
}

/// Extension methods for CalendarColorMode
extension CalendarColorModeExtension on CalendarColorMode {
  String get displayName {
    switch (this) {
      case CalendarColorMode.winLoss:
        return 'Win/Loss';
      case CalendarColorMode.profitIntensity:
        return 'Profit Intensity';
    }
  }

  String get description {
    switch (this) {
      case CalendarColorMode.winLoss:
        return 'Green for wins, red for losses';
      case CalendarColorMode.profitIntensity:
        return 'Color intensity based on profit/loss amount';
    }
  }
}
