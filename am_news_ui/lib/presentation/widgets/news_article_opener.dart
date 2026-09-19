import 'package:url_launcher/url_launcher.dart';

typedef NewsLinkLauncher = Future<bool> Function(Uri uri);

Future<bool> openNewsArticle(
  String articleLink, {
  NewsLinkLauncher? launcher,
}) async {
  final uri = Uri.tryParse(articleLink.trim());
  if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
    return false;
  }
  final launch = launcher ??
      (u) => launchUrl(
            u,
            mode: LaunchMode.platformDefault,
            webOnlyWindowName: '_blank',
          );
  return launch(uri);
}
