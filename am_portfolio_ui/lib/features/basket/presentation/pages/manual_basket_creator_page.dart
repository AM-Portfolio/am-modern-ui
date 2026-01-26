import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:dio/dio.dart'; // Import Dio for API calls
import '../../domain/models/basket_opportunity.dart';
import '../../../../core/constants/basket_endpoints.dart';
import '../../domain/models/basket_opportunity.dart'; // Ensure this path is correct
import '../widgets/allocation_bar.dart'; // Import AllocationBar

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
  double? _investmentAmount;
  final TextEditingController _amountController = TextEditingController();
  bool _includeHeld = false;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.opportunity.composition);
    // Pre-fill amount if totalPortfolioValue is available, maybe default to 10%?
    // User requested quick sets. Let's start empty or 0.
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
  
  void _setAmountByPercentage(double percentage) {
    final totalPortfolioValue = widget.opportunity.totalPortfolioValue ?? 0.0;
    if (totalPortfolioValue > 0) {
      final amount = totalPortfolioValue * (percentage / 100.0);
      setState(() {
        _investmentAmount = amount;
        _amountController.text = amount.toStringAsFixed(0);
      });
      _calculateQuantities();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total Portfolio Value not available for percentage calculation')),
      );
    }
  }

  Future<void> _calculateQuantities() async {
    if (_amountController.text.isEmpty) return;
    
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      // Direct Dio call for now, ideally strictly use provider/repository
      final dio = Dio(); 
      final response = await dio.post(
        BasketEndpoints.calculateQuantities,
        data: {
          'investmentAmount': amount,
          'opportunity': widget.opportunity.toJson(), // Need toJson on model or recreate
          'includeHeld': _includeHeld,
        },
      );
      
      if (response.statusCode == 200) {
        final updatedOpportunity = BasketOpportunity.fromJson(response.data);
        setState(() {
           _items = updatedOpportunity.composition;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating quantities: $e')),
      );
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final heldItems = _items.where((i) => i.status == ItemStatus.held).toList();
    final otherItems = _items.where((i) => i.status != ItemStatus.held).toList();

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
            totalPortfolioValue: widget.opportunity.totalPortfolioValue,
          ),
          
          // Allocation Visualization
          if (_items.isNotEmpty)
            _AllocationSummary(items: _items, includeHeld: _includeHeld),
          
          // Investment Input Section
          Container(
             padding: const EdgeInsets.all(16),
             color: Theme.of(context).cardColor,
             child: Column(
               children: [
                 Row(
                   children: [
                     Expanded(
                       child: TextField(
                         controller: _amountController,
                         keyboardType: TextInputType.number,
                         decoration: const InputDecoration(
                           labelText: 'Investment Amount (₹)',
                           border: OutlineInputBorder(),
                           contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         ),
                         onChanged: (val) {
                           // Debounce could be added here
                         },
                       ),
                     ),
                     const SizedBox(width: 12),
                     FilledButton.icon(
                       onPressed: _isCalculating ? null : _calculateQuantities,
                       icon: _isCalculating 
                           ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                           : const Icon(Icons.calculate),
                       label: const Text('Calculate'),
                     ),
                   ],
                 ),
                 const SizedBox(height: 12),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     // Quick Percentages
                     Row(
                       children: [10, 25, 50, 100].map((p) => Padding(
                         padding: const EdgeInsets.only(right: 8.0),
                         child: OutlinedButton(
                           onPressed: () => _setAmountByPercentage(p.toDouble()),
                           style: OutlinedButton.styleFrom(
                             padding: const EdgeInsets.symmetric(horizontal: 12),
                             minimumSize: const Size(0, 32),
                           ),
                           child: Text('$p%'),
                         ),
                       )).toList(),
                     ),
                     // Include Held Toggle
                     Row(
                       children: [
                         const Text('Include Held', style: TextStyle(fontSize: 12)),
                         Switch(
                           value: _includeHeld,
                           onChanged: (val) {
                             setState(() {
                               _includeHeld = val;
                             });
                             if (_amountController.text.isNotEmpty) {
                               _calculateQuantities();
                             }
                           },
                         ),
                       ],
                     )
                   ],
                 )
               ],
             ),
          ),
          
          Expanded(
            child: ListView(
               padding: const EdgeInsets.all(16),
               children: [
                  if (otherItems.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text("Stocks to Buy", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...otherItems.map((item) => _EditableBasketItemCard(
                      item: item,
                      onRemove: () {
                         int realIndex = _items.indexOf(item);
                         _removeItem(realIndex);
                      },
                      onQuantityChanged: (val) {
                         int realIndex = _items.indexOf(item);
                         _updateQuantity(realIndex, val);
                      },
                    )),
                  ],
                  
                  if (heldItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Text("Already Held", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          if (!_includeHeld) 
                             const Text("(Excluded from calculation)", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    ...heldItems.map((item) => Opacity(
                      opacity: _includeHeld ? 1.0 : 0.6,
                      child: _EditableBasketItemCard(
                        item: item,
                        readOnly: !_includeHeld,
                        onRemove: () {
                           int realIndex = _items.indexOf(item);
                           _removeItem(realIndex);
                        },
                        onQuantityChanged: (val) {
                           int realIndex = _items.indexOf(item);
                           _updateQuantity(realIndex, val);
                        },
                      ),
                    )),
                  ]
               ],
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
  final double? totalPortfolioValue;

  const _SummaryHeader({
    required this.itemCount,
    required this.etfName,
    this.totalPortfolioValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Portfolio based on $etfName',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(label: Text('$itemCount Assets')),
              if (totalPortfolioValue != null && totalPortfolioValue! > 0)
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     Text(
                       'Portfolio Value',
                       style: Theme.of(context).textTheme.labelSmall,
                     ),
                     Text(
                       '₹${totalPortfolioValue!.toStringAsFixed(0)}', // Basic formatting
                       style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                     ),
                   ],
                 )
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
  final bool readOnly;

  const _EditableBasketItemCard({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
    this.readOnly = false,
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
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.stockSymbol,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${item.sector} • ${item.marketCapCategory ?? 'N/A'}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  // Price Calculation
                  if (item.lastPrice != null)
                   Text(
                     "₹${item.lastPrice!.toStringAsFixed(2)} x ${item.buyQuantity.toInt()} = ₹${(item.lastPrice! * item.buyQuantity).toStringAsFixed(2)}",
                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                       color: Theme.of(context).primaryColor,
                       fontWeight: FontWeight.bold,
                     ),
                   )
                  else
                    Text(
                      "Price unavailable",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),

                  if (item.status == ItemStatus.substitute)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Substitute',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.info),
                      ),
                    ),
                ],
              ),
            ),
            // Quantity Editor
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!readOnly)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () {
                      if (item.buyQuantity > 0) {
                        onQuantityChanged(item.buyQuantity - 1);
                      }
                    },
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      item.buyQuantity.toInt().toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: readOnly ? Colors.grey : null,
                      ),
                    ),
                  ),
                  if (!readOnly)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () {
                        onQuantityChanged(item.buyQuantity + 1);
                    },
                  ),
                ],
              ),
            ),
            if (!readOnly)
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
