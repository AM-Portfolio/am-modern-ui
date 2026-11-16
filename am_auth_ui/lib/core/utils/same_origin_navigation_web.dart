import 'dart:html' as html;

void navigateToSameOrigin(String path) {
  if (!path.startsWith('/qa/ui')) return;
  html.window.location.assign(Uri.base.resolve(path).toString());
}
