import 'dart:async';

import 'package:am_news_ui/domain/models/news_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Schedules a single invalidate when insight reports [InsightNews.pendingIngest]
/// and filtered holdings cards are still empty.
mixin NewsPendingRetryMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _pendingRetryScheduled = false;
  bool _pendingRetryCompleted = false;

  /// True after the one-shot pending-ingest invalidate has fired (or was skipped).
  bool get pendingIngestRetryDone => _pendingRetryCompleted;

  void schedulePendingIngestRetry({
    required InsightNews data,
    required List<NewsCard> cards,
    required void Function() invalidate,
    Duration delay = const Duration(milliseconds: 2500),
  }) {
    if (!data.pendingIngest || cards.isNotEmpty) {
      if (!data.pendingIngest) _pendingRetryCompleted = true;
      return;
    }
    if (_pendingRetryScheduled) return;
    _pendingRetryScheduled = true;
    unawaited(Future<void>.delayed(delay, () {
      if (!mounted) return;
      _pendingRetryCompleted = true;
      invalidate();
    }));
  }
}

String holdingsNewsEmptyLabel({
  required InsightNews data,
  required String fallback,
  bool pendingRetryDone = false,
}) {
  // Only show "Fetching…" while the first auto-retry is outstanding.
  if (data.pendingIngest && !pendingRetryDone) return 'Fetching news…';
  return fallback;
}
