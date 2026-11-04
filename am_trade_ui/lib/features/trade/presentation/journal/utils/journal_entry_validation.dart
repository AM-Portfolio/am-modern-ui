import '../../../internal/domain/entities/journal_entry.dart';

/// Shared client validation for Log Day complete-save and Trade Journal steps.
///
/// Draft / autosave stay soft — call these only for Next / Save completely.
class JournalEntryValidation {
  const JournalEntryValidation._();

  static String? requiredText(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? positiveNumber(String? raw, {String label = 'Value'}) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    final n = double.tryParse(text);
    if (n == null) return '$label must be a number';
    if (n <= 0) return '$label must be greater than 0';
    return null;
  }

  static String? positiveOptional(String? raw, {String label = 'Value'}) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final n = double.tryParse(text);
    if (n == null) return '$label must be a number';
    if (n <= 0) return '$label must be greater than 0';
    return null;
  }

  /// Log Day — title + notes before Save / Update completes the entry.
  static String? validateLogDayComplete({
    required String title,
    required String notesPlain,
  }) {
    final titleError = requiredText(title, label: 'Title');
    if (titleError != null) return titleError;
    if (notesPlain.trim().isEmpty) {
      return 'Add notes before saving this log day';
    }
    return null;
  }

  /// Trade Journal — gate Next / final Save on the current wizard step.
  static String? validateTradeStep(JournalEntry entry, int step) {
    switch (step.clamp(0, 2)) {
      case 0:
        return validatePreTrade(entry);
      case 1:
        return validateExecute(entry);
      case 2:
      default:
        return validatePostTrade(entry);
    }
  }

  static String? validatePreTrade(JournalEntry entry) {
    final symbolError = requiredText(entry.symbol, label: 'Symbol');
    if (symbolError != null) return symbolError;

    final plan = entry.preTradePlan;
    final entryPx = plan?.plannedEntryPrice;
    final stop = plan?.plannedStopLoss;
    final target = plan?.plannedTarget;
    final qty = plan?.plannedQuantity;

    if (entryPx == null || entryPx <= 0) {
      return 'Planned entry must be greater than 0';
    }
    if (stop == null || stop <= 0) {
      return 'Planned stop must be greater than 0';
    }
    if (target == null || target <= 0) {
      return 'Planned target must be greater than 0';
    }
    if (qty == null || qty <= 0) {
      return 'Quantity must be greater than 0';
    }

    final isShort = (entry.tradeDirection ?? 'LONG').toUpperCase() == 'SHORT';
    if (isShort) {
      if (stop <= entryPx) {
        return 'For a short, stop must be above entry';
      }
      if (target >= entryPx) {
        return 'For a short, target must be below entry';
      }
    } else {
      if (stop >= entryPx) {
        return 'For a long, stop must be below entry';
      }
      if (target <= entryPx) {
        return 'For a long, target must be above entry';
      }
    }
    return null;
  }

  static String? validateExecute(JournalEntry entry) {
    final exec = entry.tradeExecution;
    final plan = entry.preTradePlan;
    // Require a real fill price on Execute — do not silently use the plan.
    final entryPx = exec?.actualEntryPrice;
    final qty = exec?.quantity ?? plan?.plannedQuantity;

    if (entryPx == null || entryPx <= 0) {
      return 'Actual entry price is required';
    }
    if (qty == null || qty <= 0) {
      return 'Executed quantity must be greater than 0';
    }
    return null;
  }

  static String? validatePostTrade(JournalEntry entry) {
    final review = entry.postTradeReview;
    final exit = review?.actualExitPrice;
    if (exit == null || exit <= 0) {
      return 'Actual exit price is required';
    }

    // Closed review: exit must be a real positive fill (already checked) and
    // notes capture the outcome context used by Insights.
    final lesson = review?.lessonLearned?.trim() ?? '';
    final wentWell = review?.whatWentWell?.trim() ?? '';
    final improve = review?.whatCouldBeImproved?.trim() ?? '';
    if (lesson.isEmpty && wentWell.isEmpty && improve.isEmpty) {
      return 'Add a lesson or review notes before completing';
    }
    return null;
  }
}
