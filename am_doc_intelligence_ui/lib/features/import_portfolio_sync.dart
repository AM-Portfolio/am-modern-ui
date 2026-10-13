import 'package:am_doc_intelligence_ui/features/import_holdings_shared_controls.dart';
import 'package:am_doc_intelligence_ui/services/api_service.dart';
import 'package:flutter/foundation.dart';

class ImportedPortfolioRef {
  const ImportedPortfolioRef({
    required this.portfolioId,
    required this.portfolioName,
  });

  final String portfolioId;
  final String portfolioName;
}

/// Poll portfolio list until a broker/name match appears or [timeout] elapses.
///
/// Ready criteria (first match wins):
/// 1. Name match on [targetPortfolioName]
/// 2. Broker-named portfolio that is new / renamed vs baseline
/// 3. Known [knownPortfolioId] appears or its name changed vs baseline
Future<ImportedPortfolioRef?> waitForImportedPortfolio({
  required String brokerKey,
  String? targetPortfolioName,
  String? knownPortfolioId,
  List<ImportedPortfolioRef>? baseline,
  Duration timeout = const Duration(seconds: 60),
  Duration interval = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  final base = baseline ?? await snapshotPortfolios();
  final baseIds = {for (final p in base) p.portfolioId};
  final baseById = {for (final p in base) p.portfolioId: p.portfolioName};

  final brokerNames = _brokerNameCandidates(brokerKey);
  final target = targetPortfolioName?.trim();

  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(interval);
    final list = await snapshotPortfolios();
    final hit = _pickReady(
      list: list,
      baseIds: baseIds,
      baseById: baseById,
      brokerNames: brokerNames,
      targetName: target,
      knownPortfolioId: knownPortfolioId,
    );
    if (hit != null) return hit;
  }

  final list = await snapshotPortfolios();
  return _pickReady(
    list: list,
    baseIds: baseIds,
    baseById: baseById,
    brokerNames: brokerNames,
    targetName: target,
    knownPortfolioId: knownPortfolioId,
  );
}

ImportedPortfolioRef? _pickReady({
  required List<ImportedPortfolioRef> list,
  required Set<String> baseIds,
  required Map<String, String> baseById,
  required Set<String> brokerNames,
  String? targetName,
  String? knownPortfolioId,
}) {
  if (targetName != null && targetName.isNotEmpty) {
    for (final p in list) {
      if (p.portfolioName.toLowerCase() == targetName.toLowerCase()) {
        return p;
      }
    }
  }

  if (knownPortfolioId != null && knownPortfolioId.isNotEmpty) {
    for (final p in list) {
      if (p.portfolioId != knownPortfolioId) continue;
      final prior = baseById[p.portfolioId];
      if (prior == null ||
          prior != p.portfolioName ||
          !baseIds.contains(p.portfolioId)) {
        return p;
      }
      if (brokerNames.contains(p.portfolioName.toLowerCase())) return p;
    }
  }

  for (final p in list) {
    final nameLc = p.portfolioName.toLowerCase();
    if (!brokerNames.contains(nameLc)) continue;
    if (!baseIds.contains(p.portfolioId)) return p;
    final prior = baseById[p.portfolioId];
    if (prior != null && prior != p.portfolioName) return p;
  }

  final newcomers =
      list.where((p) => !baseIds.contains(p.portfolioId)).toList();
  if (newcomers.length == 1 && (targetName == null || targetName.isEmpty)) {
    return newcomers.first;
  }

  return null;
}

Set<String> _brokerNameCandidates(String brokerKey) {
  final key = normalizeBrokerKey(brokerKey) ?? brokerKey.toLowerCase();
  final display = brokerKeyDisplayName(key).toLowerCase();
  final doc = brokerKeyToDocCode(key)?.toLowerCase();
  final email = brokerKeyToEmailId(key)?.toLowerCase();
  final out = <String>{display, key};
  if (doc != null) out.add(doc);
  if (email != null) out.add(email);
  if (key == 'groww') {
    out.addAll({'grow', 'groww'});
  }
  if (key == 'angelone') {
    out.addAll({'angel one', 'angel_one', 'angleone', 'angelone'});
  }
  return out;
}

/// Snapshot helper for callers that want an explicit baseline before extract.
Future<List<ImportedPortfolioRef>> snapshotPortfolios() async {
  try {
    final raw = await apiProvider.listPortfoliosBrief();
    return raw
        .map(
          (e) => ImportedPortfolioRef(
            portfolioId: e['portfolioId'] ?? '',
            portfolioName: e['portfolioName'] ?? '',
          ),
        )
        .where((p) => p.portfolioId.isNotEmpty)
        .toList();
  } catch (e, st) {
    debugPrint('[import_portfolio_sync] list failed: $e\n$st');
    return const [];
  }
}
