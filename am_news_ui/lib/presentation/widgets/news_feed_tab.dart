enum NewsFeedTab { currentAffairs, holdings }

extension NewsFeedTabX on NewsFeedTab {
  String get label => switch (this) {
        NewsFeedTab.currentAffairs => 'Current affairs',
        NewsFeedTab.holdings => 'Your holdings',
      };

  String get emptyLabel => switch (this) {
        NewsFeedTab.currentAffairs => 'No current affairs yet.',
        NewsFeedTab.holdings => 'No holdings news yet.',
      };
}
