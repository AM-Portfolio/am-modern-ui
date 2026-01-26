
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../providers/custom_basket_provider.dart';
import '../../domain/models/custom_basket.dart';
import '../../domain/models/stock_search_result.dart';
import '../../widgets/substitute_selector.dart';
import '../widgets/creator/basket_summary_footer.dart';

class BasketCreatorPage extends ConsumerStatefulWidget {
  const BasketCreatorPage({Key? key}) : super(key: key);

  @override
  ConsumerState<BasketCreatorPage> createState() => _BasketCreatorPageState();
}

class _BasketCreatorPageState extends ConsumerState<BasketCreatorPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '100000');

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basket = ref.watch(customBasketNotifierProvider);
    final searchResults = ref.watch(stockSearchNotifierProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Custom Basket',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (basket.stocks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () {
                ref.read(customBasketNotifierProvider.notifier).clearBasket();
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A1128),
              const Color(0xFF001F54),
              Colors.blueGrey.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section with Investment Amount
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Investment Amount',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              prefixStyle: const TextStyle(
                                color: Colors.white70,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              border: InputBorder.none,
                              hintText: '100000',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            onChanged: (value) {
                              final amount = double.tryParse(value) ?? 0;
                              ref
                                  .read(customBasketNotifierProvider.notifier)
                                  .updateInvestmentAmount(amount);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search stocks...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (query) {
                          // Trigger search
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Stock List
              Expanded(
                child: _buildStockList(
                  _searchController.text.isEmpty
                      ? searchResults
                      : ref
                          .read(stockSearchNotifierProvider.notifier)
                          .search(_searchController.text),
                  basket,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BasketSummaryFooter(
        basket: basket,
        onBuildBasket: () {
          _showBuildConfirmation(context, basket);
        },
      ),
    );
  }

  Widget _buildStockList(List<CustomBasketStock> stocks, CustomBasket basket) {
    final selectedSymbols = basket.stocks.map((s) => s.symbol).toSet();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: stocks.length,
      itemBuilder: (context, index) {
        final stock = stocks[index];
        final isSelected = selectedSymbols.contains(stock.symbol);

        return _buildStockCard(stock, isSelected);
      },
    );
  }

  Widget _buildStockCard(CustomBasketStock stock, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.greenAccent.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getSectorColor(stock.sector ?? '').withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stock.symbol.substring(0, 1),
                    style: TextStyle(
                      color: _getSectorColor(stock.sector ?? ''),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              title: Text(
                stock.symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.name,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  if (stock.sector != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getSectorColor(stock.sector!).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stock.sector!,
                        style: TextStyle(
                          color: _getSectorColor(stock.sector!),
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Colors.blueAccent),
                    tooltip: 'Replace',
                    onPressed: () => _replaceStock(stock),
                  ),
                  IconButton(
                    icon: Icon(
                      isSelected ? Icons.remove_circle : Icons.add_circle,
                      color: isSelected ? Colors.red : Colors.greenAccent,
                    ),
                    onPressed: () {
                      if (isSelected) {
                        ref
                            .read(customBasketNotifierProvider.notifier)
                            .removeStock(stock.symbol);
                      } else {
                        ref
                            .read(customBasketNotifierProvider.notifier)
                            .addStock(stock);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _replaceStock(CustomBasketStock original) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SubstituteSelector(
          originalSymbol: original.symbol,
          requiredMarketCap: '', // Auto-detect
          onSelected: (StockSearchResult newStock) {
             final stockToAdd = CustomBasketStock(
               symbol: newStock.symbol,
               name: newStock.name,
               weight: original.weight,
               sector: newStock.sector,
             );
             
             // Remove then add to perform substitution
             // Note: This trigger weight recalculation based on current notifier logic
             ref.read(customBasketNotifierProvider.notifier).removeStock(original.symbol);
             ref.read(customBasketNotifierProvider.notifier).addStock(stockToAdd);
             
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Replaced ${original.symbol} with ${newStock.symbol}')),
             );
          },
        ),
      ),
    );
  }

  Color _getSectorColor(String sector) {
    switch (sector.toLowerCase()) {
      case 'it':
        return Colors.blue;
      case 'finance':
        return Colors.green;
      case 'fmcg':
        return Colors.orange;
      case 'oil & gas':
        return Colors.purple;
      case 'telecom':
        return Colors.pink;
      case 'construction':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  void _showBuildConfirmation(BuildContext context, CustomBasket basket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text(
          'Build Basket?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'You are about to create a basket with ${basket.stocks.length} stocks and an investment of ₹${basket.investmentAmount.toStringAsFixed(0)}.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual basket creation logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Basket created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
            ),
            child: const Text('Build'),
          ),
        ],
      ),
    );
  }
}
