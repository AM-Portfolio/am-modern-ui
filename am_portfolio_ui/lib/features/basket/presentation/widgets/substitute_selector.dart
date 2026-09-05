import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../data/services/stock_search_service.dart';
import '../../domain/models/stock_search_result.dart';
import '../../domain/models/basket_opportunity.dart';
import 'dart:async';

class SubstituteSelectionEntry {
  final String symbol;
  final String isin;
  final double? assignedWeight; // null = consume max available

  const SubstituteSelectionEntry({
    required this.symbol,
    required this.isin,
    this.assignedWeight,
  });
}

class SubstituteSelector extends ConsumerStatefulWidget {
  final String originalSymbol;
  final String? originalIsin;
  final String requiredMarketCap;
  final List<Alternative> alternatives;
  final double neededWeight;
  final int neededQty;
  final double neededValue;
  final bool isGapFill;
  final bool sectorialBasket;
  final String? dominantSector;
  final String? etfName;
  final List<String> etfConstituentIsins;
  final String? missingSector;
  final Function(List<SubstituteSelectionEntry>) onMultiSelected;

  const SubstituteSelector({
    super.key,
    required this.originalSymbol,
    this.originalIsin,
    required this.requiredMarketCap,
    this.alternatives = const [],
    required this.neededWeight,
    required this.neededQty,
    required this.neededValue,
    this.isGapFill = false,
    this.sectorialBasket = false,
    this.dominantSector,
    this.etfName,
    this.etfConstituentIsins = const [],
    this.missingSector,
    required this.onMultiSelected,
  });

  @override
  ConsumerState<SubstituteSelector> createState() => _SubstituteSelectorState();
}

class _SubstituteSelectorState extends ConsumerState<SubstituteSelector> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<StockSearchResult> _results = [];
  bool _isLoading = false;
  String? _error;

  String? _detectedMarketCap;

  // Track selection order and selected alternatives
  final List<Alternative> _selectedAlternatives = [];
  final Set<String> _selectedIsins = {};

  // We can also let the user search and select a stock that isn't in alternatives
  final Map<String, StockSearchResult> _selectedSearchedStocks = {};

  @override
  void initState() {
    super.initState();
    if (widget.requiredMarketCap.isEmpty) {
      _fetchOriginalDetails();
    } else {
      _detectedMarketCap = widget.requiredMarketCap;
    }
  }

  Future<void> _fetchOriginalDetails() async {
    try {
      final service = ref.read(stockSearchServiceProvider);
      final results = await service.searchStocks(widget.originalSymbol);
      if (results.isNotEmpty && mounted) {
        setState(() {
          _detectedMarketCap = results.first.marketCapCategory;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch original details: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(stockSearchServiceProvider);
      final results = await service.searchStocks(query);
      if (mounted) {
        setState(() {
          _results = _filterSearchResults(results);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to search stocks';
          _isLoading = false;
        });
      }
    }
  }

  void _toggleAlternativeSelection(Alternative alt) {
    final available = alt.userWeight > 0.01 && (alt.quantity ?? 0) > 0;
    if (!available) {
      return;
    }
    setState(() {
      if (_selectedIsins.contains(alt.isin)) {
        _selectedIsins.remove(alt.isin);
        _selectedAlternatives.removeWhere((a) => a.isin == alt.isin);
      } else {
        _selectedIsins.add(alt.isin);
        _selectedAlternatives.add(alt);
      }
    });
  }

  void _toggleSearchedStockSelection(StockSearchResult stock) {
    setState(() {
      if (_selectedIsins.contains(stock.isin ?? '')) {
        _selectedIsins.remove(stock.isin ?? '');
        _selectedSearchedStocks.remove(stock.isin ?? '');
      } else {
        _selectedIsins.add(stock.isin ?? '');
        _selectedSearchedStocks[stock.isin ?? ''] = stock;
      }
    });
  }

  double _calculateCoverageWeight() {
    double totalWeight = 0.0;
    for (final alt in _selectedAlternatives) {
      totalWeight += alt.userWeight;
    }
    if (_selectedSearchedStocks.isNotEmpty && _selectedIsins.isNotEmpty) {
      final perPick = widget.neededWeight / _selectedIsins.length;
      totalWeight += perPick * _selectedSearchedStocks.length;
    }
    return totalWeight;
  }

  String _recommendationBanner() {
    if (widget.sectorialBasket) {
      final sectorLabel = widget.dominantSector ?? widget.missingSector ?? 'same sector';
      return 'Recommendation: Select $sectorLabel stocks to fill the gap.';
    }
    final indexLabel = widget.etfName ?? 'index';
    return 'Select from your $indexLabel holdings (index constituents preferred).';
  }

  bool _sectorMatches(String? candidateSector) {
    if (!widget.sectorialBasket) return true;
    final missing = widget.missingSector?.trim().toLowerCase();
    final candidate = candidateSector?.trim().toLowerCase();
    if (missing == null || missing.isEmpty || candidate == null || candidate.isEmpty) {
      return true;
    }
    return missing == candidate ||
        missing.contains(candidate) ||
        candidate.contains(missing);
  }

  bool _isConstituent(String? isin) {
    if (isin == null || isin.isEmpty) return false;
    return widget.etfConstituentIsins.contains(isin);
  }

  List<Alternative> get _visibleAlternatives {
    var list = widget.alternatives.where((a) => a.effectiveRemainingQty > 0).toList();
    if (widget.sectorialBasket) {
      list = list
          .where((a) => a.isSameSector || _sectorMatches(a.sector))
          .toList();
    }
    // Live-decrement: hide or reduce remaining for already selected peer ISINs
    // (selection itself handles over-pick via coverage; UI shows residual remaining).
    return list;
  }

  String _remainingLabel(Alternative alt) {
    final rem = alt.effectiveRemainingQty;
    final physical = alt.physicalQuantity ?? rem;
    final usedHere = alt.usedInThisBasketQuantity ?? 0;
    final usedActive = alt.usedInActiveBasketsQuantity ?? 0;
    final remInt = rem.round();
    final physInt = physical.round();
    final buf = StringBuffer(
      'Remaining: $remInt of $physInt units (${alt.userWeight.toStringAsFixed(1)}%)',
    );
    if (usedHere > 0.01) {
      buf.write(' · ${usedHere.round()} already used in this basket');
    } else if (usedActive > 0.01) {
      buf.write(' · ${usedActive.round()} used in active baskets');
    }
    if (alt.indexEtf) {
      buf.write(' · Index ETF');
    }
    return buf.toString();
  }

  List<StockSearchResult> _filterSearchResults(List<StockSearchResult> results) {
    if (widget.sectorialBasket) {
      return results.where((r) => _sectorMatches(r.sector)).toList();
    }
    if (widget.etfConstituentIsins.isNotEmpty) {
      final constituents = results.where((r) => _isConstituent(r.isin)).toList();
      if (constituents.isNotEmpty) return constituents;
    }
    return results;
  }

  void _applySelection() {
    if (_selectedIsins.isEmpty) return;

    final List<SubstituteSelectionEntry> selections = [];
    
    // Add alternatives first, in the order they were selected
    for (final alt in _selectedAlternatives) {
      selections.add(SubstituteSelectionEntry(
        symbol: alt.symbol,
        isin: alt.isin,
        // null means consume up to available gap limit automatically on backend
      ));
    }

    // Add searched stocks
    for (final stock in _selectedSearchedStocks.values) {
      selections.add(SubstituteSelectionEntry(
        symbol: stock.symbol,
        isin: stock.isin ?? '',
      ));
    }

    widget.onMultiSelected(selections);
  }

  @override
  Widget build(BuildContext context) {
    final currentCoverage = _calculateCoverageWeight();
    final progress = widget.neededWeight > 0 ? (currentCoverage / widget.neededWeight).clamp(0.0, 1.0) : 1.0;
    final isFullyCovered = currentCoverage >= widget.neededWeight;

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isGapFill
                    ? 'Fill Gap for ${widget.originalSymbol}'
                    : 'Replace ${widget.originalSymbol}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Gap Tracking Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFullyCovered 
                  ? context.statusSuccess.withValues(alpha: 0.1)
                  : ModuleColors.portfolio.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFullyCovered 
                    ? context.statusSuccess.withValues(alpha: 0.3)
                    : ModuleColors.portfolio.withValues(alpha: 0.3)
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gap to Fill: ${widget.neededWeight.toStringAsFixed(2)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isFullyCovered ? 'Gap Filled ✓' : '${currentCoverage.toStringAsFixed(2)}% Selected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFullyCovered ? context.statusSuccess : context.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: context.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFullyCovered ? context.statusSuccess : ModuleColors.portfolio,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _recommendationBanner(),
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for a stock (e.g. RELIANCE)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: context.backgroundColor,
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _buildResultList(),
          ),
          
          const SizedBox(height: 16),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _selectedIsins.isEmpty ? null : _applySelection,
              style: FilledButton.styleFrom(
                backgroundColor: ModuleColors.portfolio,
                foregroundColor: context.colors.actionPrimaryFg,
                disabledBackgroundColor: ModuleColors.portfolio.withValues(alpha: 0.3),
              ),
              child: Text('Apply Selection (${_selectedIsins.length})'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: context.statusError)));
    }

    if (_results.isEmpty && _searchController.text.isEmpty) {
      if (_visibleAlternatives.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text('Recommended Substitutes',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.textSecondary)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _visibleAlternatives.length,
                itemBuilder: (context, index) {
                  final alt = _visibleAlternatives[index];
                  final isSelected = _selectedIsins.contains(alt.isin);
                  final available =
                      alt.userWeight > 0.01 && alt.effectiveRemainingQty > 0;

                  return ListTile(
                    enabled: available,
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: available
                          ? (bool? value) {
                              _toggleAlternativeSelection(alt);
                            }
                          : null,
                      activeColor: ModuleColors.portfolio,
                    ),
                    title: Text(alt.symbol,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alt.sector != null
                            ? '${alt.sector} • ₹${alt.lastPrice?.toStringAsFixed(2) ?? "—"}'
                            : '₹${alt.lastPrice?.toStringAsFixed(2) ?? "—"}'),
                        Text(
                          _remainingLabel(alt),
                          style: TextStyle(
                            fontSize: 11,
                            color: context.statusSuccess,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (alt.indexEtf)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ModuleColors.portfolio
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Index ETF',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: ModuleColors.portfolio),
                            ),
                          ),
                        if (alt.isSameSector)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  context.statusSuccess.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Same sector',
                              style: TextStyle(
                                  fontSize: 9, color: context.statusSuccess),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                context.statusSuccess.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Recommended',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: context.statusSuccess)),
                        ),
                      ],
                    ),
                    onTap: available
                        ? () => _toggleAlternativeSelection(alt)
                        : null,
                  );
                },
              ),
            ),
          ],
        );
      }
      return Center(
          child: Text(
              widget.sectorialBasket
                  ? 'No same-sector holdings with remaining units. Try search.'
                  : 'Type to search for a stock...',
              style: TextStyle(color: context.textTertiary)));
    }

    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text('No stocks found'));
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final stock = _results[index];
        final isConstituent = _isConstituent(stock.isin);
        final sectorOk = _sectorMatches(stock.sector);
        final isMatch = _detectedMarketCap != null && 
            stock.marketCapCategory?.toLowerCase() == _detectedMarketCap?.toLowerCase();
        final unknownCap = _detectedMarketCap == null || stock.marketCapCategory == null;
        final isSelected = _selectedIsins.contains(stock.isin);
        
        return ListTile(
          leading: Checkbox(
            value: isSelected,
            onChanged: (bool? value) {
              if (value == true) {
                _attemptSelectSearchedStock(context, stock, isMatch, unknownCap, sectorOk, isConstituent);
              } else {
                _toggleSearchedStockSelection(stock);
              }
            },
            activeColor: ModuleColors.portfolio,
          ),
          title: Text(stock.symbol),
          subtitle: Text(stock.name),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stock.marketCapCategory ?? '—',
                style: TextStyle(
                  color: unknownCap ? Colors.grey : (isMatch ? context.statusSuccess : context.statusWarning),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!unknownCap && !isMatch)
                Text('Mismatch', style: TextStyle(fontSize: 10, color: context.statusWarning)),
              if (!widget.sectorialBasket && widget.etfConstituentIsins.isNotEmpty && !isConstituent)
                Text('Not in index', style: TextStyle(fontSize: 10, color: context.statusWarning)),
            ],
          ),
          onTap: () {
            if (!isSelected) {
              _attemptSelectSearchedStock(context, stock, isMatch, unknownCap, sectorOk, isConstituent);
            } else {
              _toggleSearchedStockSelection(stock);
            }
          },
        );
      },
    );
  }

  void _attemptSelectSearchedStock(
    BuildContext context,
    StockSearchResult stock,
    bool isMatch,
    bool unknownCap,
    bool sectorOk,
    bool isConstituent,
  ) {
    if (widget.sectorialBasket && !sectorOk) {
      _showSectorWarning(context, stock);
      return;
    }
    if (!widget.sectorialBasket &&
        widget.etfConstituentIsins.isNotEmpty &&
        !isConstituent) {
      _showConstituentWarning(context, stock);
      return;
    }
    if (!isMatch && !unknownCap) {
      _showMismatchWarning(context, stock);
    } else if (unknownCap && _detectedMarketCap != null) {
      _showMismatchWarning(context, stock);
    } else {
      _toggleSearchedStockSelection(stock);
    }
  }

  void _showSectorWarning(BuildContext context, StockSearchResult stock) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: const Text('Sector Mismatch'),
        content: Text(
          '${stock.symbol} is not in the same sector as ${widget.originalSymbol}. Sectorial baskets require same-sector substitutes.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showConstituentWarning(BuildContext context, StockSearchResult stock) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: const Text('Not an Index Constituent'),
        content: Text(
          '${stock.symbol} is not part of ${widget.etfName ?? 'this index'}. You can still select it, but it may not match the basket profile.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _toggleSearchedStockSelection(stock);
            },
            style: FilledButton.styleFrom(
              backgroundColor: ModuleColors.portfolio,
              foregroundColor: Colors.white,
            ),
            child: const Text('Select Anyway'),
          ),
        ],
      ),
    );
  }

  void _showMismatchWarning(BuildContext context, StockSearchResult stock) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: const Text('Market Cap Mismatch'),
        content: Text(
          'You are replacing a $_detectedMarketCap stock with a ${stock.marketCapCategory} stock (${stock.symbol}).\n\nThis may affect the basket\'s risk profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _toggleSearchedStockSelection(stock);
            },
            style: FilledButton.styleFrom(
              backgroundColor: ModuleColors.portfolio,
              foregroundColor: Colors.white,
            ),
            child: const Text('Select Anyway'),
          ),
        ],
      ),
    );
  }
}
