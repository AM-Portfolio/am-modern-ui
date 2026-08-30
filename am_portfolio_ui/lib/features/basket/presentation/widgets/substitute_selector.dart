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
          _results = results;
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
    // Search stocks usually don't have userWeight, so we just assume full gap if selected?
    // Actually, backend limits to available weight. If a user selects a searched stock that
    // isn't in their portfolio, backend handles it (it just fails to consume weight or throws warn).
    return totalWeight;
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
                'Replace ${widget.originalSymbol}',
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
                  : context.colors.actionPrimaryBg.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFullyCovered 
                    ? context.statusSuccess.withValues(alpha: 0.3)
                    : context.colors.actionPrimaryBg.withValues(alpha: 0.3)
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
                      isFullyCovered ? context.statusSuccess : context.colors.actionPrimaryBg,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _detectedMarketCap != null 
                      ? 'Recommendation: Select $_detectedMarketCap stocks to fill the gap.'
                      : 'Fetching original stock details...',
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
                backgroundColor: context.colors.actionPrimaryBg,
                foregroundColor: context.colors.actionPrimaryFg,
                disabledBackgroundColor: context.colors.actionPrimaryBg.withValues(alpha: 0.3),
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
      if (widget.alternatives.isNotEmpty) {
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
                itemCount: widget.alternatives.length,
                itemBuilder: (context, index) {
                  final alt = widget.alternatives[index];
                  final isSelected = _selectedIsins.contains(alt.isin);
                  
                  return ListTile(
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleAlternativeSelection(alt);
                      },
                      activeColor: context.colors.actionPrimaryBg,
                    ),
                    title: Text(alt.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alt.sector != null
                            ? '${alt.sector} • ₹${alt.lastPrice?.toStringAsFixed(2) ?? "—"}'
                            : '₹${alt.lastPrice?.toStringAsFixed(2) ?? "—"}'),
                        if (alt.quantity != null && alt.quantity! > 0)
                          Text('Available weight: ${alt.userWeight.toStringAsFixed(2)}% (${alt.quantity?.toInt()} units)',
                              style: TextStyle(fontSize: 11, color: context.statusSuccess, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.statusSuccess.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Recommended',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: context.statusSuccess)),
                    ),
                    onTap: () => _toggleAlternativeSelection(alt),
                  );
                },
              ),
            ),
          ],
        );
      }
      return Center(child: Text('Type to search for a stock...', style: TextStyle(color: context.textTertiary)));
    }

    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text('No stocks found'));
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final stock = _results[index];
        final isMatch = _detectedMarketCap != null && 
            stock.marketCapCategory?.toLowerCase() == _detectedMarketCap?.toLowerCase();
        final unknownCap = _detectedMarketCap == null || stock.marketCapCategory == null;
        final isSelected = _selectedIsins.contains(stock.isin);
        
        return ListTile(
          leading: Checkbox(
            value: isSelected,
            onChanged: (bool? value) {
              if (value == true) {
                if (!isMatch && !unknownCap) {
                  _showMismatchWarning(context, stock);
                } else if (unknownCap && _detectedMarketCap != null) {
                  _showMismatchWarning(context, stock);
                } else {
                  _toggleSearchedStockSelection(stock);
                }
              } else {
                _toggleSearchedStockSelection(stock);
              }
            },
            activeColor: context.colors.actionPrimaryBg,
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
            ],
          ),
          onTap: () {
            if (!isSelected) {
              if (!isMatch && !unknownCap) {
                _showMismatchWarning(context, stock);
              } else if (unknownCap && _detectedMarketCap != null) {
                _showMismatchWarning(context, stock);
              } else {
                _toggleSearchedStockSelection(stock);
              }
            } else {
              _toggleSearchedStockSelection(stock);
            }
          },
        );
      },
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
            child: const Text('Select Anyway'),
          ),
        ],
      ),
    );
  }
}
