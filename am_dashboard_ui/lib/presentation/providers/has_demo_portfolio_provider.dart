import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_library/am_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Portfolio list path used by portfolio module ([PortfolioEndpoints.list]).
const _portfolioListPath = '/v1/portfolios/list';

bool isDemoPortfolioEntry({
  String? kind,
  String? name,
  bool? isDummy,
}) {
  if (isDummy == true) return true;
  final k = kind?.toUpperCase();
  if (k == 'DUMMY' || k == 'DEMO') return true;
  final n = name?.toLowerCase() ?? '';
  return n.contains('demo');
}

bool parseHasDemoPortfolio(dynamic data) {
  final List<dynamic> items;
  if (data is List) {
    items = data;
  } else if (data is Map && data['portfolios'] is List) {
    items = data['portfolios'] as List;
  } else {
    return false;
  }

  for (final raw in items) {
    if (raw is! Map) continue;
    final map = Map<String, dynamic>.from(raw);
    final kind = map['kind'] as String?;
    if (kind?.toUpperCase() == 'DELETED') continue;
    final name = (map['portfolioName'] as String?) ??
        (map['name'] as String?) ??
        '';
    final dummyFlag = map['isDummy'] == true || map['dummy'] == true;
    if (isDemoPortfolioEntry(kind: kind, name: name, isDummy: dummyFlag)) {
      return true;
    }
  }
  return false;
}

/// True when the signed-in user has any demo/DUMMY portfolio (first-time seed).
/// Soft-fails to `false` so the badge never blocks the dashboard.
///
/// On API/auth failure the keepAlive link is closed so a later rebuild can retry
/// (avoids permanently caching `false` from a pre-token race).
final hasDemoPortfolioProvider = FutureProvider<bool>((ref) async {
  final keepAliveLink = ref.keepAlive();
  try {
    final client = await ref.watch(portfolioApiClientProvider.future);
    final data = await client.get<dynamic>(
      _portfolioListPath,
      parser: (raw) => raw,
    );
    final hasDemo = parseHasDemoPortfolio(data);
    AppLogger.info(
      'hasDemoPortfolioProvider → $hasDemo',
      tag: 'DemoAccount',
    );
    return hasDemo;
  } catch (e, st) {
    keepAliveLink.close();
    AppLogger.warning(
      'hasDemoPortfolioProvider failed; hiding demo badge (will retry)',
      error: e,
      stackTrace: st,
      tag: 'DemoAccount',
    );
    return false;
  }
});
