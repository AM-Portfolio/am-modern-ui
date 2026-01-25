import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../domain/models/basket_opportunity.dart';

class ManualBasketCreatorPage extends ConsumerStatefulWidget {
  final BasketOpportunity opportunity;
  final String userId;
  final String portfolioId;

  const ManualBasketCreatorPage({
    super.key,
    required this.opportunity,
    required this.userId,
    required this.portfolioId,
  });

  @override
  ConsumerState<ManualBasketCreatorPage> createState() =>
      _ManualBasketCreatorPageState();
}

class _ManualBasketCreatorPageState
    extends ConsumerState<ManualBasketCreatorPage> {
  late List<BasketItem> _items;
  late double _totalInvestment;

  @override
  void initState() {
    super.initState();
    // Initialize with buy list and missing items, or full composition?
    // User wants to create a portfolio, so presumably they want the full basket.
    // However, the feature is "replicate", so we usually focus on what's missing + what's held?
    // Let's assume we show the FULL intended composition.
    _items = List.from(widget.opportunity.composition);
    
    // Calculate initial investment based on buyQuantity * price (if we had price).
    // SInce we don't have price in BasketItem, we might simulate or just show quantities.
    _totalInvestment = 0; 
  }

  void _updateQuantity(int index, double newQuantity) {
    setState(() {
      _items[index] = _items[index].copyWith(buyQuantity: newQuantity);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Basket'),
        actions: [
          TextButton(
            onPressed: _savePortfolio,
            child: const Text('Save Portfolio'),
          ),
        ],
      ),
      body: Column(
        children: [
          _SummaryHeader(
            itemCount: _items.length,
            etfName: widget.opportunity.etfName,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = _items[index];
                return _EditableBasketItemCard(
                  item: item,
                  onRemove: () => _removeItem(index),
                  onQuantityChanged: (val) => _updateQuantity(index, val),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _savePortfolio() {
    // TODO: Implement save logic when backend endpoint is available
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Portfolio Creation API not yet implemented'),
        backgroundColor: AppColors.warning,
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final int itemCount;
  final String etfName;

  const _SummaryHeader({
    required this.itemCount,
    required this.etfName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Portfolio based on $etfName',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(label: Text('$itemCount Assets')),
              // Add more summary stats here
            ],
          ),
        ],
      ),
    );
  }
}

class _EditableBasketItemCard extends StatelessWidget {
  final BasketItem item;
  final VoidCallback onRemove;
  final ValueChanged<double> onQuantityChanged;

  const _EditableBasketItemCard({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.stockSymbol,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    item.sector,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  if (item.status == ItemStatus.substitute)
                    Text(
                      'Substitute',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.info),
                    ),
                ],
              ),
            ),
            // Quantity Editor
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () {
                      if (item.buyQuantity > 0) {
                        onQuantityChanged(item.buyQuantity - 1);
                      }
                    },
                  ),
                  Text(
                    item.buyQuantity.toInt().toString(), // Assuming integer quantities for now
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () {
                        onQuantityChanged(item.buyQuantity + 1);
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
