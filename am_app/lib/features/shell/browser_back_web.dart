// ignore: avoid_web_libraries_in_flutter, uri_does_not_exist
import 'dart:html' as html;

/// Prefer browser history when the 404 was opened via a deep link.
void browserHistoryBack({required void Function() fallback}) {
  try {
    if (html.window.history.length > 1) {
      html.window.history.back();
      return;
    }
  } catch (_) {}
  fallback();
}
