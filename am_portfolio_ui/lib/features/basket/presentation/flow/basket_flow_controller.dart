import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/basket_opportunity.dart';

/// Shared basket-creation flow state across preview → customize → final review.
class BasketFlowState {
  final BasketOpportunity? originalOpportunity;
  final BasketOpportunity? currentOpportunity;
  final Set<String> excludedSymbols;
  final Map<String, int> manualQtyOverrides;
  final double? investmentAmount;
  final String? basketName;
  final bool hasCalculated;
  final String? draftId;
  final String? lastSavedFingerprint;

  const BasketFlowState({
    this.originalOpportunity,
    this.currentOpportunity,
    this.excludedSymbols = const {},
    this.manualQtyOverrides = const {},
    this.investmentAmount,
    this.basketName,
    this.hasCalculated = false,
    this.draftId,
    this.lastSavedFingerprint,
  });

  bool get isEmpty => currentOpportunity == null;

  bool get isDirty {
    if (currentOpportunity == null) return false;
    final current = fingerprint();
    if (lastSavedFingerprint == null) {
      return hasCalculated ||
          manualQtyOverrides.isNotEmpty ||
          excludedSymbols.isNotEmpty ||
          investmentAmount != null;
    }
    return current != lastSavedFingerprint;
  }

  String fingerprint() {
    final etf = currentOpportunity?.etfIsin ?? '';
    final amount = investmentAmount?.toStringAsFixed(2) ?? '';
    final name = basketName ?? '';
    final excluded = (excludedSymbols.toList()..sort()).join(',');
    final overrides = (manualQtyOverrides.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    final calc = hasCalculated ? '1' : '0';
    final score = currentOpportunity?.replicaScore.toStringAsFixed(2) ?? '';
    return '$etf|$amount|$name|$excluded|$overrides|$calc|$score';
  }

  BasketFlowState copyWith({
    BasketOpportunity? originalOpportunity,
    BasketOpportunity? currentOpportunity,
    Set<String>? excludedSymbols,
    Map<String, int>? manualQtyOverrides,
    double? investmentAmount,
    String? basketName,
    bool? hasCalculated,
    String? draftId,
    String? lastSavedFingerprint,
    bool clearExcluded = false,
    bool clearManualQtyOverrides = false,
    bool clearDraftId = false,
    bool clearLastSavedFingerprint = false,
  }) {
    return BasketFlowState(
      originalOpportunity: originalOpportunity ?? this.originalOpportunity,
      currentOpportunity: currentOpportunity ?? this.currentOpportunity,
      excludedSymbols:
          clearExcluded ? const {} : (excludedSymbols ?? this.excludedSymbols),
      manualQtyOverrides: clearManualQtyOverrides
          ? const {}
          : (manualQtyOverrides ?? this.manualQtyOverrides),
      investmentAmount: investmentAmount ?? this.investmentAmount,
      basketName: basketName ?? this.basketName,
      hasCalculated: hasCalculated ?? this.hasCalculated,
      draftId: clearDraftId ? null : (draftId ?? this.draftId),
      lastSavedFingerprint: clearLastSavedFingerprint
          ? null
          : (lastSavedFingerprint ?? this.lastSavedFingerprint),
    );
  }
}

class BasketFlowController extends Notifier<BasketFlowState> {
  @override
  BasketFlowState build() => const BasketFlowState();

  void startFlow(BasketOpportunity opportunity) {
    state = BasketFlowState(
      originalOpportunity: opportunity,
      currentOpportunity: opportunity,
      excludedSymbols: opportunity.excludedSymbols.toSet(),
    );
  }

  /// Resume an existing in-memory or draft snapshot without wiping unrelated fields.
  void restoreFromDraft({
    required BasketOpportunity opportunity,
    required Set<String> excludedSymbols,
    required Map<String, int> manualQtyOverrides,
    required double investmentAmount,
    required String basketName,
    required bool hasCalculated,
    String? draftId,
  }) {
    state = BasketFlowState(
      originalOpportunity: opportunity,
      currentOpportunity: opportunity,
      excludedSymbols: excludedSymbols,
      manualQtyOverrides: manualQtyOverrides,
      investmentAmount: investmentAmount,
      basketName: basketName,
      hasCalculated: hasCalculated,
      draftId: draftId,
    );
    markSaved();
  }

  void updateOpportunity(BasketOpportunity opportunity) {
    state = state.copyWith(currentOpportunity: opportunity);
  }

  void excludeSymbol(String symbol) {
    state = state.copyWith(excludedSymbols: {...state.excludedSymbols, symbol});
  }

  void includeSymbol(String symbol) {
    final next = {...state.excludedSymbols}..remove(symbol);
    state = state.copyWith(excludedSymbols: next);
  }

  void setManualQtyOverride(String symbol, int qty) {
    state = state.copyWith(
      manualQtyOverrides: {...state.manualQtyOverrides, symbol: qty},
    );
  }

  void clearManualQtyOverrides() {
    state = state.copyWith(clearManualQtyOverrides: true);
  }

  void setInvestmentAmount(double amount) {
    state = state.copyWith(investmentAmount: amount);
  }

  void setBasketName(String name) {
    state = state.copyWith(basketName: name);
  }

  void setHasCalculated(bool value) {
    state = state.copyWith(hasCalculated: value);
  }

  void setDraftId(String? draftId) {
    if (draftId == null || draftId.isEmpty) {
      state = state.copyWith(clearDraftId: true);
      return;
    }
    state = state.copyWith(draftId: draftId);
  }

  void markSaved() {
    state = state.copyWith(lastSavedFingerprint: state.fingerprint());
  }

  void resetFlow() {
    state = const BasketFlowState();
  }
}

final basketFlowControllerProvider =
    NotifierProvider<BasketFlowController, BasketFlowState>(
  BasketFlowController.new,
);
