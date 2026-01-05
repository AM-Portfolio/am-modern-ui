/// Categories for journal templates
enum JournalTemplateCategory {
  dailyCheckin('DAILY_CHECKIN', 'Daily Check-in'),
  preMarket('PRE_MARKET', 'Pre-Market'),
  postMarket('POST_MARKET', 'Post-Market'),
  tradeRecap('TRADE_RECAP', 'Trade Recap'),
  weeklyReview('WEEKLY_REVIEW', 'Weekly Review'),
  monthlyReview('MONTHLY_REVIEW', 'Monthly Review'),
  quarterlyReview('QUARTERLY_REVIEW', 'Quarterly Review'),
  custom('CUSTOM', 'Custom');

  const JournalTemplateCategory(this.value, this.displayName);

  final String value;
  final String displayName;

  static JournalTemplateCategory fromString(String value) {
    return JournalTemplateCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => JournalTemplateCategory.custom,
    );
  }
}
