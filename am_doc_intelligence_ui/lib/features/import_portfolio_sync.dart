import 'package:am_common/am_common.dart';
import 'package:am_doc_intelligence_ui/features/import_holdings_shared_controls.dart';
import 'package:am_doc_intelligence_ui/services/api_service.dart';
import 'package:am_library/am_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

class ImportedPortfolioRef {
  const ImportedPortfolioRef({
    required this.portfolioId,
    required this.portfolioName,
    this.familyMemberId,
    this.familyMemberName,
  });

  final String portfolioId;
  final String portfolioName;
  final String? familyMemberId;
  final String? familyMemberName;
}

/// Maps a synced import row to a [FavoritePersonaStore] key.
String personaKeyForImport({String? familyMemberId}) {
  final id = familyMemberId?.trim() ?? '';
  if (id.isEmpty) return FavoritePersonaStore.kYou;
  return id;
}

ImportedPortfolioRef importedPortfolioRefFromBrief(Map<String, String> e) {
  final familyId = e['familyMemberId']?.trim();
  final familyName = e['familyMemberName']?.trim();
  return ImportedPortfolioRef(
    portfolioId: e['portfolioId'] ?? '',
    portfolioName: e['portfolioName'] ?? '',
    familyMemberId: (familyId == null || familyId.isEmpty) ? null : familyId,
    familyMemberName:
        (familyName == null || familyName.isEmpty) ? null : familyName,
  );
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
        .map(importedPortfolioRefFromBrief)
        .where((p) => p.portfolioId.isNotEmpty)
        .toList();
  } catch (e, st) {
    debugPrint('[import_portfolio_sync] list failed: $e\n$st');
    return const [];
  }
}

Set<String> _familyIdsFromList(List<ImportedPortfolioRef> list) {
  return {
    for (final p in list)
      if ((p.familyMemberId?.trim() ?? '').isNotEmpty) p.familyMemberId!.trim(),
  };
}

/// Prefer the sync row's family stamp; else any newly stamped family member id.
Future<String?> resolveFamilyMemberIdAfterImport({
  required ImportedPortfolioRef sync,
  required Set<String> familyIdsBefore,
  Duration timeout = const Duration(seconds: 15),
  Duration interval = const Duration(seconds: 2),
}) async {
  final direct = sync.familyMemberId?.trim() ?? '';
  if (direct.isNotEmpty) return direct;

  final deadline = DateTime.now().add(timeout);
  while (true) {
    final list = await snapshotPortfolios();
    for (final p in list) {
      if (p.portfolioId != sync.portfolioId) continue;
      final fid = p.familyMemberId?.trim() ?? '';
      if (fid.isNotEmpty) return fid;
      break;
    }
    final after = _familyIdsFromList(list);
    final added = after.difference(familyIdsBefore);
    if (added.isNotEmpty) return added.first;
    // CAS often stamps a demat book other than the wait hit — any family stamp.
    if (after.isNotEmpty && familyIdsBefore.isEmpty) return after.first;
    if (!DateTime.now().isBefore(deadline)) break;
    await Future<void>.delayed(interval);
  }
  return null;
}

Future<String?> _sessionUserId() async {
  try {
    if (GetIt.I.isRegistered<SecureStorageService>()) {
      return GetIt.I<SecureStorageService>().getUserId();
    }
    return SecureStorageService().getUserId();
  } catch (e, st) {
    debugPrint('[import_portfolio_sync] userId read failed: $e\n$st');
    return null;
  }
}

/// Snapshot family member ids currently stamped on portfolio list rows.
Future<Set<String>> snapshotFamilyMemberIds() async {
  return _familyIdsFromList(await snapshotPortfolios());
}

/// After import sync: persist and select You or the FAMILY member stamped on books.
///
/// Pass [familyIdsBefore] from [snapshotFamilyMemberIds] taken before the wait
/// so a newly stamped member can be detected even when the wait hit is primary.
Future<void> applyPersonaFromImportedPortfolio({
  required BuildContext context,
  required ImportedPortfolioRef? sync,
  String? identityMatch,
  Set<String>? familyIdsBefore,
}) async {
  if (sync == null) return;

  final userId = (await _sessionUserId())?.trim() ?? '';
  if (userId.isEmpty) {
    debugPrint('[import_portfolio_sync] skip persona: empty userId');
    return;
  }

  final match = (identityMatch ?? '').trim().toUpperCase();
  if (match == 'SELF') {
    final personaKey = FavoritePersonaStore.kYou;
    await FavoritePersonaStore.instance.save(userId, personaKey);
    if (!context.mounted) return;
    try {
      ProviderScope.containerOf(context)
          .read(familyPortfolioFilterProvider.notifier)
          .select(personaKey);
    } catch (e, st) {
      debugPrint('[import_portfolio_sync] filter select failed: $e\n$st');
    }
    return;
  }

  final before = familyIdsBefore ?? const <String>{};
  var familyId = await resolveFamilyMemberIdAfterImport(
    sync: sync,
    familyIdsBefore: before,
  );
  // FAMILY extract whose wait hit stayed primary: still select a stamped member.
  if ((familyId == null || familyId.isEmpty) && match == 'FAMILY') {
    final after = await snapshotFamilyMemberIds();
    final added = after.difference(before);
    familyId = added.isNotEmpty
        ? added.first
        : (after.isNotEmpty ? after.first : null);
  }
  final personaKey = personaKeyForImport(familyMemberId: familyId);

  await FavoritePersonaStore.instance.save(userId, personaKey);
  if (!context.mounted) return;

  try {
    ProviderScope.containerOf(context)
        .read(familyPortfolioFilterProvider.notifier)
        .select(personaKey);
  } catch (e, st) {
    debugPrint('[import_portfolio_sync] filter select failed: $e\n$st');
  }
}
