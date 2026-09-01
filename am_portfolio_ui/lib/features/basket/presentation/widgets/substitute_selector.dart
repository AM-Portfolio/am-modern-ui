import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart'; // Assuming specific design system
import '../../data/services/stock_search_service.dart';
import '../../domain/models/stock_search_result.dart';
import '../../domain/models/basket_opportunity.dart';
import 'dart:async';

class SubstituteSelector extends ConsumerStatefulWidget {
  final String originalSymbol;
  final String requiredMarketCap;
  final List<Alternative> alternatives;
  final Function(StockSearchResult) onSelected;

  const SubstituteSelector({
    super.key,
    required this.originalSymbol,
    required this.requiredMarketCap,
    this.alternatives = const [],
    required this.onSelected,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.actionPrimaryBg.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colors.actionPrimaryBg.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: context.colors.actionPrimaryBg),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _detectedMarketCap != null 
                        ? 'Recommendation: Select a $_detectedMarketCap stock.'
                        : 'Fetching original stock details...',
                    style: TextStyle(color: context.colors.actionPrimaryBg),
                  ),
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
                      color: context.colors.actionPrimaryBg)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.alternatives.length,
                itemBuilder: (context, index) {
                  final alt = widget.alternatives[index];
                  return ListTile(
                    leading: Icon(Icons.star, color: context.colors.actionPrimaryBg, size: 20),
                    title: Text(alt.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(alt.sector != null
                        ? '${alt.sector} • ₹${alt.lastPrice?.toStringAsFixed(2) ?? "—"}'
                        : '₹${alt.lastPrice?.toStringAsFixed(2) ?? "—"}'),
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
                    onTap: () {
                      final stock = StockSearchResult(
                        symbol: alt.symbol,
                        isin: alt.isin,
                        name: alt.symbol,
                        sector: alt.sector,
                      );
                      widget.onSelected(stock);
                      Navigator.pop(context);
                    },
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
        
        return ListTile(
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
            if (!isMatch && !unknownCap) {
              _showMismatchWarning(context, stock);
            } else if (unknownCap && _detectedMarketCap != null) {
              // Target market cap is known, but the substitute's cap is unknown. Show warning.
              _showMismatchWarning(context, stock);
            } else {
              widget.onSelected(stock);
              Navigator.pop(context);
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
              Navigator.pop(ctx); // Close dialog
              widget.onSelected(stock);
              Navigator.pop(context); // Close sheet
            },
            child: const Text('Select Anyway'),
          ),
        ],
      ),
    );
  }
}
