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

bool _isBrokerPortfolioEntry({
  String? kind,
  String? brokerType,
  bool isDemo = false,
  bool isPaper = false,
}) {
  if (isDemo || isPaper) return false;
  final k = kind?.toUpperCase();
  if (k == 'DELETED' || k == 'DEMO' || k == 'DUMMY' || k == 'PAPER' || k == 'BASKET') {
    return false;
  }
  final broker = brokerType?.trim() ?? '';
  // Any concrete broker book (Zerodha, CDSL CAS, CAS_DEMAT, …) retires Demo chrome.
  return broker.isNotEmpty && (k == null || k == 'BROKER' || k == 'LIVE');
}

/// True only when a demo/DUMMY row exists **and** there is no broker portfolio yet.
/// Uploading/linking a broker book must hide Demo Account chrome.
bool parseHasDemoPortfolio(dynamic data) {
  final List<dynamic> items;
  if (data is List) {
    items = data;
  } else if (data is Map && data['portfolios'] is List) {
    items = data['portfolios'] as List;
  } else {
    return false;
  }

  var hasDemo = false;
  var hasBroker = false;
  for (final raw in items) {
    if (raw is! Map) continue;
    final map = Map<String, dynamic>.from(raw);
    final kind = map['kind'] as String?;
    if (kind?.toUpperCase() == 'DELETED') continue;
    final name = (map['portfolioName'] as String?) ??
        (map['name'] as String?) ??
        '';
    final dummyFlag = map['isDummy'] == true || map['dummy'] == true;
    final isDemo = isDemoPortfolioEntry(kind: kind, name: name, isDummy: dummyFlag);
    final isPaper = kind?.toUpperCase() == 'PAPER' || name.toLowerCase() == 'paper';
    if (isDemo) {
      hasDemo = true;
      continue;
    }
    final brokerType =
        (map['brokerType'] ?? map['broker'])?.toString();
    if (_isBrokerPortfolioEntry(
      kind: kind,
      brokerType: brokerType,
      isDemo: isDemo,
      isPaper: isPaper,
    )) {
      hasBroker = true;
    }
  }
  return hasDemo && !hasBroker;
}

/// True when the signed-in user still needs Demo chrome (demo seed, no broker yet).
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
