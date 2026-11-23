import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mf_api_client.dart';
import '../data/mf_dto.dart';

final mfApiClientProvider = Provider<MfApiClient>((ref) => MfApiClient());

/// Explore search key — pass [purchaseAllowed] when Buyable filter is on.
typedef MfSchemeSearchKey = ({String query, bool? purchaseAllowed});

final mfSchemeSearchProvider =
    FutureProvider.family<MfCatalogResult, MfSchemeSearchKey>((ref, key) async {
  final client = ref.watch(mfApiClientProvider);
  return client.searchSchemes(
    query: key.query.isEmpty ? null : key.query,
    purchaseAllowed: key.purchaseAllowed,
  );
});

final mfSchemeDetailProvider =
    FutureProvider.family<MfSchemeSummary, String>((ref, isin) async {
  final client = ref.watch(mfApiClientProvider);
  return client.getScheme(isin);
});

/// NAV history for ~1Y ending today (YYYY-MM-DD).
final mfSchemeNavProvider =
    FutureProvider.family<List<MfNavPoint>, String>((ref, isin) async {
  final client = ref.watch(mfApiClientProvider);
  final to = DateTime.now();
  final from = to.subtract(const Duration(days: 365));
  String fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  return client.getNav(isin: isin, from: fmt(from), to: fmt(to));
});

final mfSchemePerformanceProvider =
    FutureProvider.family<MfPerformance, String>((ref, isin) async {
  final client = ref.watch(mfApiClientProvider);
  final raw = await client.getPerformance(isin);
  return MfPerformance.fromJson(raw);
});

/// Latest catalog NAV for a holding ISIN (performance → scheme fallback).
final mfLatestNavProvider =
    FutureProvider.family<double?, String>((ref, isin) async {
  final key = isin.trim().toUpperCase();
  if (key.isEmpty) return null;
  try {
    final perf = await ref.watch(mfSchemePerformanceProvider(key).future);
    if (perf.latestNav != null) return perf.latestNav;
  } catch (_) {}
  try {
    final scheme = await ref.watch(mfSchemeDetailProvider(key).future);
    final raw = scheme.raw;
    final nav = raw['nav'] ?? raw['latest_nav'] ?? raw['latestNav'];
    if (nav is num) return nav.toDouble();
    return double.tryParse(nav?.toString() ?? '');
  } catch (_) {
    return null;
  }
});

final mfOrderProvider =
    FutureProvider.family<MfOrder, String>((ref, orderId) async {
  final client = ref.watch(mfApiClientProvider);
  return client.getOrder(orderId);
});

final mfHoldingsProvider = FutureProvider<List<MfHoldingLot>>((ref) async {
  final client = ref.watch(mfApiClientProvider);
  return client.getHoldings();
});

final mfOrdersHistoryProvider = FutureProvider<List<MfOrder>>((ref) async {
  final client = ref.watch(mfApiClientProvider);
  return client.listOrders();
});

final mfSipsHistoryProvider = FutureProvider<List<MfSip>>((ref) async {
  final client = ref.watch(mfApiClientProvider);
  return client.listSips();
});

final mfMandatesHistoryProvider = FutureProvider<List<MfMandate>>((ref) async {
  final client = ref.watch(mfApiClientProvider);
  return client.listMandates();
});

/// Draft onboarding fields kept in-memory until BFF status API (Ship B).
class MfOnboardingDraft {
  const MfOnboardingDraft({
    this.pan = '',
    this.clientCode = '',
    this.name = '',
    this.dob = '',
    this.email = '',
    this.mobile = '',
    this.bankAccountNo = '',
    this.bankIfsc = '',
    this.accountType = 'SB',
    this.ekycOk = false,
    this.uccOk = false,
    this.fatcaOk = false,
    this.bankOk = false,
    this.lastMessage,
  });

  final String pan;
  final String clientCode;
  final String name;
  final String dob;
  final String email;
  final String mobile;
  final String bankAccountNo;
  final String bankIfsc;
  final String accountType;
  final bool ekycOk;
  final bool uccOk;
  final bool fatcaOk;
  final bool bankOk;
  final String? lastMessage;

  MfOnboardingDraft copyWith({
    String? pan,
    String? clientCode,
    String? name,
    String? dob,
    String? email,
    String? mobile,
    String? bankAccountNo,
    String? bankIfsc,
    String? accountType,
    bool? ekycOk,
    bool? uccOk,
    bool? fatcaOk,
    bool? bankOk,
    String? lastMessage,
  }) {
    return MfOnboardingDraft(
      pan: pan ?? this.pan,
      clientCode: clientCode ?? this.clientCode,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      bankAccountNo: bankAccountNo ?? this.bankAccountNo,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      accountType: accountType ?? this.accountType,
      ekycOk: ekycOk ?? this.ekycOk,
      uccOk: uccOk ?? this.uccOk,
      fatcaOk: fatcaOk ?? this.fatcaOk,
      bankOk: bankOk ?? this.bankOk,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class MfOnboardingDraftNotifier extends Notifier<MfOnboardingDraft> {
  @override
  MfOnboardingDraft build() => const MfOnboardingDraft();

  void patch(MfOnboardingDraft Function(MfOnboardingDraft) fn) {
    state = fn(state);
  }

  void reset() => state = const MfOnboardingDraft();
}

final mfOnboardingDraftProvider =
    NotifierProvider<MfOnboardingDraftNotifier, MfOnboardingDraft>(
  MfOnboardingDraftNotifier.new,
);

/// Last successful local mandate id (required by SIP ownership check).
class MfSessionIds {
  const MfSessionIds({
    this.mandateId,
    this.mandateStatus,
    this.distributorSipRef,
    this.sipStatus,
    this.lastOrderId,
  });

  final String? mandateId;
  final String? mandateStatus;
  final String? distributorSipRef;
  final String? sipStatus;
  final String? lastOrderId;

  bool get mandateUsableForXsip {
    final s = (mandateStatus ?? '').toLowerCase();
    if (mandateId == null || mandateId!.isEmpty) return false;
    // Industry path: XSIP only after ACTIVE (or dry_run local).
    return s == 'active' || s == 'dry_run';
  }

  MfSessionIds copyWith({
    String? mandateId,
    String? mandateStatus,
    String? distributorSipRef,
    String? sipStatus,
    String? lastOrderId,
  }) {
    return MfSessionIds(
      mandateId: mandateId ?? this.mandateId,
      mandateStatus: mandateStatus ?? this.mandateStatus,
      distributorSipRef: distributorSipRef ?? this.distributorSipRef,
      sipStatus: sipStatus ?? this.sipStatus,
      lastOrderId: lastOrderId ?? this.lastOrderId,
    );
  }
}

class MfSessionIdsNotifier extends Notifier<MfSessionIds> {
  @override
  MfSessionIds build() => const MfSessionIds();

  void setMandate({required String id, required String status}) =>
      state = state.copyWith(mandateId: id, mandateStatus: status);

  void setSip({required String ref, required String status}) =>
      state = state.copyWith(distributorSipRef: ref, sipStatus: status);

  void setSipStatus(String status) =>
      state = state.copyWith(sipStatus: status);

  void setOrderId(String id) => state = state.copyWith(lastOrderId: id);

  /// Prefer usable mandate + SIP from History lists (survives page reopen).
  void hydrateFromLists({
    List<MfMandate> mandates = const [],
    List<MfSip> sips = const [],
  }) {
    MfMandate? mandate;
    for (final m in mandates) {
      final s = m.status.toLowerCase();
      if (s == 'active' || s == 'dry_run') {
        mandate = m;
        break;
      }
    }
    mandate ??= () {
      for (final m in mandates) {
        final s = m.status.toLowerCase();
        if (s == 'rejected' || s == 'cancelled' || s == 'failed') continue;
        return m;
      }
      return null;
    }();
    MfSip? sip;
    for (final s in sips) {
      final ref = s.distributorSipRef;
      if (ref == null || ref.isEmpty) continue;
      final st = s.status.toLowerCase();
      if (st == 'cancelled' || st == 'failed') continue;
      sip = s;
      break;
    }
    var next = state;
    if (mandate != null) {
      next = next.copyWith(
        mandateId: mandate.id,
        mandateStatus: mandate.status,
      );
    }
    if (sip != null) {
      next = next.copyWith(
        distributorSipRef: sip.distributorSipRef,
        sipStatus: sip.status,
      );
    }
    state = next;
  }
}

final mfSessionIdsProvider =
    NotifierProvider<MfSessionIdsNotifier, MfSessionIds>(
  MfSessionIdsNotifier.new,
);
