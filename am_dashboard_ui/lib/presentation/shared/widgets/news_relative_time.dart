import 'package:am_dashboard_ui/domain/models/news_models.dart';
import 'package:intl/intl.dart';

String formatNewsRelativeTime(String? publishedAt, {DateTime? now}) {
  final published = parseNewsPublishedAt(publishedAt);
  if (published == null) return '';
  final current = now ?? DateTime.now().toUtc();
  final stamp = published.isUtc ? published : published.toUtc();
  final delta = current.difference(stamp);
  if (delta.isNegative || delta.inMinutes < 2) return 'JUST NOW';
  if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
  if (delta.inHours < 24) return '${delta.inHours}h ago';
  return DateFormat('MMM d, h:mm a').format(stamp.toLocal());
}
