import 'dart:async';

import 'package:am_news_ui/domain/models/news_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Schedules a single invalidate when insight reports [InsightNews.pendingIngest]
/// and filtered holdings cards are still empty.
mixin NewsPendingRetryMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _pendingRetryScheduled = false;

  void schedulePendingIngestRetry({
    required InsightNews data,
    required List<NewsCard> cards,
    required void Function() invalidate,
    Duration delay = const Duration(milliseconds: 2500),
  }) {
    if (!data.pendingIngest || cards.isNotEmpty || _pendingRetryScheduled) {
      return;
    }
    _pendingRetryScheduled = true;
    unawaited(Future<void>.delayed(delay, () {
      if (!mounted) return;
      invalidate();
    }));
  }
}

String holdingsNewsEmptyLabel({
  required InsightNews data,
  required String fallback,
}) {
  if (data.pendingIngest) return 'Fetching news…';
  return fallback;
}
