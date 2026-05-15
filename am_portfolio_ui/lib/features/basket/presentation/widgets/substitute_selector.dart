import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart'; // Assuming specific design system
import '../../data/services/stock_search_service.dart';
import '../../domain/models/stock_search_result.dart';
import 'dart:async';

class SubstituteSelector extends ConsumerStatefulWidget {
  final String originalSymbol;
  final String requiredMarketCap;
  final Function(StockSearchResult) onSelected;

  const SubstituteSelector({
    super.key,
    required this.originalSymbol,
    required this.requiredMarketCap,
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
      print('Failed to fetch original details: $e');
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _detectedMarketCap != null
                        ? 'Recommendation: Select a $_detectedMarketCap stock.'
                        : 'Fetching original stock details...',
                    style: const TextStyle(color: Colors.blueBytes),
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
              fillColor: Colors.grey.shade50,
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildResultList()),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text('No stocks found'));
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final stock = _results[index];
        final isMatch =
            _detectedMarketCap != null &&
            stock.marketCapCategory == _detectedMarketCap;
        final unknownCap =
            _detectedMarketCap == null || stock.marketCapCategory == null;

        return ListTile(
          title: Text(stock.symbol),
          subtitle: Text(stock.name),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stock.marketCapCategory ?? 'Unknown',
                style: TextStyle(
                  color: unknownCap
                      ? Colors.grey
                      : (isMatch ? Colors.green : Colors.orange),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!unknownCap && !isMatch)
                const Text(
                  'Mismatch',
                  style: TextStyle(fontSize: 10, color: Colors.orange),
                ),
            ],
          ),
          onTap: () {
            if (!unknownCap && !isMatch) {
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
