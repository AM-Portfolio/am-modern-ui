part of '../pages/manual_basket_creator_page.dart';

extension _ManualBasketCreatorPageLogic on _ManualBasketCreatorPageState {
  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------
  void _updateQuantity(int index, double newQuantity) {
    setState(() {
      _items[index] = _items[index].copyWith(buyQuantity: newQuantity);
      _hasCalculated = false;
    });
  }

  void _updateTargetQuantity(int index, int delta) {
    final item = _items[index];
    if (item.lastPrice == null || item.lastPrice! <= 0) return;

    final symbol = item.stockSymbol;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final heldMax = (item.heldQuantity ?? 0).toInt();
    final currentQty = _manualQtyOverrides[symbol]?.toInt() ??
        BasketAllocationMath.allocatedUnits(item, amount).toInt();

    if (delta > 0 && !BasketAllocationMath.canIncreaseAllocation(
          item,
          amount,
          manualOverrideQty: currentQty,
        )) {
      return;
    }

    final newQty = (currentQty + delta).clamp(0, heldMax);

    setState(() {
      _manualQtyOverrides[symbol] = newQty;
      _items[index] = item.copyWith(
        targetQuantity: newQty.toDouble(),
        targetQuantityLocked: true,
      );
    });
    ref.read(basketFlowControllerProvider.notifier).setManualQtyOverride(symbol, newQty);
    _scheduleRecalculate();
  }

  void _setDirectTargetQuantity(int index, int qty) {
    final item = _items[index];
    if (item.lastPrice == null || item.lastPrice! <= 0) return;
    final heldMax = (item.heldQuantity ?? 0).toInt();
    final clampedQty = qty.clamp(0, heldMax);
    setState(() {
      _manualQtyOverrides[item.stockSymbol] = clampedQty;
      _items[index] = item.copyWith(
        targetQuantity: clampedQty.toDouble(),
        targetQuantityLocked: true,
      );
    });
    ref.read(basketFlowControllerProvider.notifier).setManualQtyOverride(item.stockSymbol, clampedQty);
    _scheduleRecalculate();
  }

  double _allocatedUnits(BasketItem item, double investmentAmount) {
    return BasketAllocationMath.allocatedUnits(
      item,
      investmentAmount,
      manualOverrideQty: _manualQtyOverrides[item.stockSymbol],
    );
  }

  /// Sum of target qty × price for non-excluded lines (live custom allocation denominator).
  double _totalCustomInvestment(List<BasketItem> items) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return BasketAllocationMath.totalCustomInvestment(
      items,
      amount,
      _excludedItems,
      manualQtyForSymbol: (symbol) => _manualQtyOverrides[symbol],
    );
  }

  double _heldCoverageValue() {
    final live = _totalCustomInvestment(_items);
    if (live > 0) return live;
    return _currentOpportunity.heldCoverageValue ?? 0.0;
  }

  double _computeResidualCash() {
    final investmentAmount = double.tryParse(_amountController.text) ?? 0.0;
    final actual = _actualCost ?? 0.0;
    return BasketAllocationMath.leftoverCash(
      investmentAmount: investmentAmount,
      heldCoverageValue: _heldCoverageValue(),
      actualInvestmentCost: actual,
    );
  }

  double? _customWeightFor(BasketItem item, double investmentAmount) {
    return BasketAllocationMath.customWeightPercent(
      item,
      investmentAmount,
      manualOverrideQty: _manualQtyOverrides[item.stockSymbol],
    );
  }

  double _totalCustomWeightPercent(List<BasketItem> items, double investmentAmount) {
    return BasketAllocationMath.totalCustomWeightPercent(
      items,
      investmentAmount,
      _excludedItems,
      manualQtyForSymbol: (symbol) => _manualQtyOverrides[symbol],
    );
  }

  /// ETF index target weights — prefer backend-rebalanced weights; normalize to 100%.
  double _targetWeightSum(List<BasketItem> items) {
    return BasketAllocationMath.targetWeightSum(items, _excludedItems);
  }
  void _removeItem(int index) {
    setState(() {
      _excludedItems.add(_items[index].stockSymbol);
    });
    ref.read(basketFlowControllerProvider.notifier).excludeSymbol(_items[index].stockSymbol);
    _scheduleRecalculate();
  }

  void _addItem(int index) {
    setState(() {
      _excludedItems.remove(_items[index].stockSymbol);
    });
    ref.read(basketFlowControllerProvider.notifier).includeSymbol(_items[index].stockSymbol);
    _scheduleRecalculate();
  }

  void _resetBasket() {
    setState(() {
      _excludedItems.clear();
      _manualQtyOverrides.clear();
      _items = List.from(widget.opportunity.composition);
    });
    ref.read(basketFlowControllerProvider.notifier)
      ..clearManualQtyOverrides()
      ..startFlow(widget.opportunity);
    _scheduleRecalculate();
  }

  void _setFixedAmount(int amountRs) {
    setState(() {
      _amountController.text = amountRs.toString();
      _isCustomAmount = false;
    });
    _scheduleRecalculate();
  }

  void _scheduleRecalculate({bool immediate = false}) {
    _debounceTimer?.cancel();
    _calcEpoch++;
    final delay = immediate
        ? Duration.zero
        : const Duration(milliseconds: 350);
    _debounceTimer = Timer(delay, _runRecalculate);
  }

  Future<void> _runRecalculate() async {
      final epoch = _calcEpoch;
      if (!mounted) return;
      if (_amountController.text.isEmpty) {
        if (_isCalculating) setState(() => _isCalculating = false);
        return;
      }
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) return;

      setState(() {
        _isCalculating = true;
        _hasStaleData = false;
      });

      try {
        final List<BasketItem> itemsToSend = _items.map((item) {
          final overrideQty = _manualQtyOverrides[item.stockSymbol];
          if (overrideQty != null) {
            return item.copyWith(
              targetQuantity: overrideQty.toDouble(),
              targetQuantityLocked: true,
            );
          }
          return item;
        }).toList();

        final updatedOpportunity =
            await ref.read(calculateBasketQuantitiesProvider(
          request: {
            'investmentAmount': amount,
            'opportunity':
                _currentOpportunity.copyWith(composition: itemsToSend).toJson(),
            'includeHeld': true,
            'excludedSymbols': _excludedItems.toList(),
          },
        ).future);

        if (!mounted || epoch != _calcEpoch) return;
        setState(() {
          _currentOpportunity = updatedOpportunity;
          _items = updatedOpportunity.composition.map((item) {
            if (_excludedItems.contains(item.stockSymbol)) {
              return item.copyWith(clearBuyQuantity: true);
            }
            final overrideQty = _manualQtyOverrides[item.stockSymbol];
            if (overrideQty != null) {
              return item.copyWith(
                targetQuantity: overrideQty.toDouble(),
                targetQuantityLocked: true,
              );
            }
            return item;
          }).toList();
          _hasCalculated = true;
          _actualCost = updatedOpportunity.actualInvestmentCost;
          _budgetVariance = updatedOpportunity.budgetVariance;
        });
        final flow = ref.read(basketFlowControllerProvider.notifier);
        flow.updateOpportunity(updatedOpportunity);
        flow.setInvestmentAmount(amount);
        flow.setHasCalculated(true);
        final baseline = _resumeRefreshBaseline;
        if (baseline != null) {
          _resumeRefreshBaseline = null;
          _maybeShowResumeRefreshBanner(baseline, updatedOpportunity);
        }
      } catch (e) {
        if (!mounted || epoch != _calcEpoch) return;
        setState(() => _hasStaleData = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(basketApiErrorMessage(e)),
            backgroundColor: context.statusError,
          ),
        );
      } finally {
        if (mounted && epoch == _calcEpoch) {
          setState(() => _isCalculating = false);
        }
      }
  }

  void _openSubstituteSelectorFor(int originalIdx, {bool isGapFill = false}) {
    final item = _items[originalIdx];
    final targetQty = item.targetQuantity ?? 0;
    final heldQty = item.heldQuantity ?? 0;
    
    double gapQtyDouble = targetQty.toDouble();
    double neededWeight = item.etfWeight;
    
    if (isGapFill && (item.status == ItemStatus.held || item.status == ItemStatus.substitute)) {
      neededWeight = (item.etfWeight - item.replicaWeight).clamp(0.0, double.infinity);
      gapQtyDouble = (targetQty - heldQty).clamp(0, double.infinity);
    }

    if (neededWeight <= 0) {
      return;
    }
    
    final targetVal = gapQtyDouble * (item.lastPrice ?? 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: SubstituteSelector(
        originalSymbol: item.stockSymbol,
        originalIsin: item.isin,
        requiredMarketCap: item.marketCapCategory ?? '',
        alternatives: item.alternatives.toList(),
        neededWeight: neededWeight,
        neededQty: gapQtyDouble.toInt(),
        neededValue: targetVal.toDouble(),
        isGapFill: isGapFill,
        sectorialBasket: _currentOpportunity.sectorialBasket ?? false,
        dominantSector: _currentOpportunity.dominantSector,
        etfName: _currentOpportunity.etfName,
        etfConstituentIsins: _currentOpportunity.etfConstituentIsins,
        missingSector: item.sector,

        onMultiSelected: (selections) async {
          Navigator.of(ctx).pop();
          final subCountBefore =
              _items.where((i) => i.status == ItemStatus.substitute).length;
          setState(() {
            _isCalculating = true;
          });
          try {
            final assignments = selections.map((s) {
              final isin = s.isin.trim();
              final symbol = s.symbol.trim();
              return {
                'missingIsin':
                    item.isin.isNotEmpty ? item.isin : item.stockSymbol,
                'substituteIsin': isin.isNotEmpty ? isin : symbol,
                if (symbol.isNotEmpty) 'substituteSymbol': symbol,
                if (s.assignedWeight != null) 'assignedWeight': s.assignedWeight,
              };
            }).toList();

            final updated = await ref.read(applySubstitutesProvider(request: {
              'userId': widget.userId,
              'portfolioId': widget.portfolioId,
              'etfIsin': _currentOpportunity.etfIsin,
              'currentOpportunity': _currentOpportunity.toJson(),
              'assignments': assignments,
            }).future);

            if (!mounted) return;
            final applied = updated.appliedSubstituteCount ??
                (updated.composition
                        .where((i) => i.status == ItemStatus.substitute)
                        .length -
                    subCountBefore);
            setState(() {
              _currentOpportunity = updated;
              _items = updated.composition.map((compItem) {
                if (_excludedItems.contains(compItem.stockSymbol)) {
                  return compItem.copyWith(clearBuyQuantity: true);
                }
                return compItem;
              }).toList();
            });
            if (applied <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    substituteApplyMessage(
                      appliedCount: applied,
                      warnings: updated.substituteWarnings,
                    ),
                  ),
                  backgroundColor: context.statusWarning,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    substituteApplyMessage(
                      appliedCount: applied,
                      warnings: updated.substituteWarnings,
                    ),
                  ),
                  backgroundColor: context.statusSuccess,
                ),
              );
      _scheduleRecalculate(immediate: true);
            }
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _hasStaleData = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to apply substitutes: ${basketApiErrorMessage(e)}'),
                backgroundColor: context.statusError,
              ),
            );
          } finally {
            if (mounted) setState(() => _isCalculating = false);
          }
        },
        ),
      ),
    );
  }

  void _openSubstituteSelector() {
    final missingIdx = _items.indexWhere((i) =>
        i.status == ItemStatus.missing &&
        !_excludedItems.contains(i.stockSymbol));
    if (missingIdx == -1) return;
    _openSubstituteSelectorFor(missingIdx);
  }

  void _goToFinalPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter an investment amount first'),
        backgroundColor: context.statusWarning,
      ));
      return;
    }
    if (_isCalculating) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please wait for allocation to finish updating'),
        backgroundColor: context.statusWarning,
      ));
      return;
    }
    final minInvestment = widget.opportunity.minimumInvestmentAmount ?? 50000.0;
    if (amount < minInvestment) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Minimum investment is ₹${minInvestment.toStringAsFixed(0)}'),
        backgroundColor: context.statusWarning,
      ));
      return;
    }

    final coverage = _currentOpportunity.replicaScore;
    if (coverage < 80.0) {
      _showCoverageGateDialog(coverage);
      return;
    }

    final basketName = _basketNameController.text.trim();
    final flow = ref.read(basketFlowControllerProvider);
    final flowNotifier = ref.read(basketFlowControllerProvider.notifier);
    flowNotifier.setInvestmentAmount(amount);
    flowNotifier.setBasketName(basketName);
    flowNotifier.setHasCalculated(_hasCalculated);

    final finalItems = _items.map((item) {
      final overrideQty = _manualQtyOverrides[item.stockSymbol];
      if (overrideQty == null) return item;
      return item.copyWith(
        targetQuantity: overrideQty.toDouble(),
        targetQuantityLocked: true,
      );
    }).toList();

    BasketNavigation.openFinalPreview(
      context,
      args: BasketFinalPreviewArgs(
        originalOpportunity: widget.opportunity,
        finalOpportunity: _currentOpportunity,
        finalItems: List.unmodifiable(finalItems),
        investmentAmount: amount,
        basketName: basketName,
        userId: widget.userId,
        portfolioId: widget.portfolioId,
        excludedItems: _excludedItems,
        idempotencyKey: DateTime.now().millisecondsSinceEpoch.toString(),
        trustCustomizeOutput: _hasCalculated && !_hasStaleData,
        draftId: flow.draftId,
      ),
    );
  }

  void _showCoverageGateDialog(double coverage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BasketCoverageGateDialog(coverage: coverage),
    );
  }

  Future<void> _saveDraft({bool exitAfter = false}) async {
    if (_isCalculating) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Wait for calculation to finish before saving'),
        backgroundColor: context.statusWarning,
      ));
      return;
    }
    if (_hasStaleData) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Composition is refreshing — try again in a moment'),
        backgroundColor: context.statusWarning,
      ));
      return;
    }
    if (!_hasCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Calculate quantities before saving a draft'),
        backgroundColor: context.statusWarning,
      ));
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Enter an investment amount before saving'),
        backgroundColor: context.statusWarning,
      ));
      return;
    }

    final flow = ref.read(basketFlowControllerProvider);
    final basketName = _basketNameController.text.trim();
    try {
      final repository = await ref.read(basketRepositoryProvider.future);
      final saved = await repository.upsertDraft({
        'userId': widget.userId,
        'sourcePortfolioId': widget.portfolioId,
        'etfIsin': _currentOpportunity.etfIsin,
        'etfName': _currentOpportunity.etfName,
        'basketName': basketName.isEmpty
            ? 'My ${_currentOpportunity.etfName} Basket'
            : basketName,
        'investmentAmount': amount,
        'replicaScore': _currentOpportunity.replicaScore,
        'hasCalculated': _hasCalculated,
        'excludedSymbols': _excludedItems.toList(),
        'manualQtyOverrides': _manualQtyOverrides,
        'opportunity': _currentOpportunity.copyWith(composition: _items).toJson(),
        if (flow.draftId != null) 'draftId': flow.draftId,
      });

      final notifier = ref.read(basketFlowControllerProvider.notifier);
      notifier.setDraftId(saved.id);
      notifier.setInvestmentAmount(amount);
      notifier.setBasketName(basketName);
      notifier.setHasCalculated(true);
      notifier.updateOpportunity(
        _currentOpportunity.copyWith(composition: _items),
      );
      notifier.markSaved();

      ref.invalidate(basketDraftsProvider((
        userId: widget.userId,
        portfolioId: widget.portfolioId,
      )));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Draft saved'),
        backgroundColor: context.statusSuccess,
      ));
      if (exitAfter && mounted) {
        _exitCreator();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(basketApiErrorMessage(e)),
        backgroundColor: context.statusError,
      ));
    }
  }

  /// PopScope uses canPop:false, so maybePop is a no-op — must pop explicitly.
  void _exitCreator() {
    final nested = BasketNavigation.navigatorKey.currentState;
    if (nested != null && nested.canPop()) {
      nested.pop();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleBack() async {
    final flow = ref.read(basketFlowControllerProvider);
    final dirty = flow.isDirty ||
        (_hasCalculated &&
            (flow.lastSavedFingerprint == null ||
                flow.fingerprint() != flow.lastSavedFingerprint));
    if (!dirty) {
      _exitCreator();
      return;
    }

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (c) => const BasketLeaveCustomizeDialog(),
    );

    if (!mounted) return;
    if (action == 'discard') {
      ref.read(basketFlowControllerProvider.notifier).resetFlow();
      _exitCreator();
    } else if (action == 'save') {
      await _saveDraft(exitAfter: true);
    }
  }

  /// Soft banner when background recalc changes composition/scores after draft resume.
  void _maybeShowResumeRefreshBanner(
    BasketOpportunity before,
    BasketOpportunity after,
  ) {
    final beforeScore = before.replicaScore;
    final afterScore = after.replicaScore;
    final beforeLen = before.composition.length;
    final afterLen = after.composition.length;
    if ((beforeScore - afterScore).abs() < 0.5 && beforeLen == afterLen) {
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text(
          'Holdings or prices changed — allocation refreshed from live data.'),
      backgroundColor: context.statusWarning,
    ));
  }
}
