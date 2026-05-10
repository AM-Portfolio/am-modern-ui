import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:dio/dio.dart'; // Import Dio for API calls
import '../../domain/models/basket_opportunity.dart';
import '../../../../core/constants/basket_endpoints.dart';
import '../../domain/models/basket_opportunity.dart'; // Ensure this path is correct
import '../widgets/allocation_bar.dart'; // Import AllocationBar
import '../../../portfolio/providers/portfolio_providers.dart';
import '../../../portfolio/internal/domain/entities/portfolio_holding.dart';
// import '../../../portfolio/internal/domain/entities/portfolio_holding.dart'; // Already imported implicitly or explicitly if needed

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

  // Enrich items with local holdings data
  List<BasketItem> _enrichItemsWithHoldings(
    List<BasketItem> items,
    PortfolioHoldings? localHoldings,
  ) {
    if (localHoldings == null) return items;

    return items
        .map((item) {
          // Find matching holding in local data
          final holding = localHoldings.holdings
              .where(
                (h) => h.symbol.toLowerCase() == item.stockSymbol.toLowerCase(),
              ) // simplistic match
              .firstOrNull;

          if (holding != null) {
            return item.copyWith(
              heldQuantity: holding.quantity,
              heldAveragePrice: holding.avgPrice,
            );
          }
          return item;
        })
        .cast<BasketItem>()
        .toList();
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
        const SnackBar(
          content: Text(
            'Total Portfolio Value not available for percentage calculation',
          ),
        ),
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
      double targetAmount = amount;

      // Cost Basis Adjustment Logic
      if (_includeHeld) {
        final holdingsAsync = ref.read(
          portfolioHoldingsProvider(widget.userId),
        );
        final localHoldings = holdingsAsync.asData?.value;

        if (localHoldings != null) {
          double totalHeldCost = 0;
          double totalHeldCurrentVal = 0;

          for (var item in _items) {
            final h = localHoldings.holdings
                .where(
                  (h) =>
                      h.symbol.toLowerCase() == item.stockSymbol.toLowerCase(),
                )
                .firstOrNull;
            if (h != null) {
              totalHeldCost += h.quantity * h.avgPrice;
              totalHeldCurrentVal +=
                  h.quantity * (item.lastPrice ?? h.currentPrice);
            }
          }

          // If Input Amount (Cost Basis) > Held Cost, we need to add the difference
          if (amount > totalHeldCost) {
            double netNewMoney = amount - totalHeldCost;
            targetAmount = totalHeldCurrentVal + netNewMoney;
          }
        }
      }

      final response = await dio.post(
        BasketEndpoints.calculateQuantities,
        data: {
          'investmentAmount': targetAmount,
          'opportunity': widget.opportunity.toJson(),
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
    // Watch local holdings
    final portfolioHoldingsAsync = ref.watch(
      portfolioHoldingsProvider(widget.userId),
    );
    final localHoldings = portfolioHoldingsAsync.asData?.value;

    // Enrich items with local data
    // We create a new list to avoid mutating the state directly in build if _items is modifying
    // But _items is our source of truth for "Buy Quantity". we need to merge.
    // Actually, best to just update _items in place or create a view?
    // If we update _items here, it might trigger rebuilds loops if we perform setState.
    // Better to create a "displayItems" list for rendering that combines _items (buy qty) + localHoldings (held qty)

    final displayItems = _enrichItemsWithHoldings(_items, localHoldings);

    final heldItems = displayItems
        .where(
          (i) =>
              i.status == ItemStatus.held ||
              (i.heldQuantity != null && i.heldQuantity! > 0),
        )
        .toList();
    // Logic update: If we found it in local holdings, it IS held, regardless of initial status

    // Filter for "Other Items" (Not held)
    // If enriched said it has qty, it is held.
    final otherItems = displayItems
        .where((i) => (i.heldQuantity == null || i.heldQuantity == 0))
        .toList();

    // Re-verify filtered lists to ensure no dups if logic is mixed
    // Actually, simpler:
    // heldItems = anything with heldQuantity > 0
    // otherItems = anything else

    // Update _items reference for callbacks? No, callbacks use index on _items.
    // We need to map interactions on displayItems back to _items.
    // Since map order is preserved, indices match if we don't filter first.

    double totalActiveInvestment = 0;
    final activeCalculationItems = _includeHeld ? displayItems : otherItems;
    for (var item in activeCalculationItems) {
      if (item.lastPrice != null) {
        totalActiveInvestment += item.lastPrice! * item.buyQuantity;
      }
    }

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
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.calculate),
                      label: const Text('Calculate'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Slider for Amount
                Slider(
                  value:
                      double.tryParse(
                        _amountController.text,
                      )?.clamp(5000.0, 1000000.0) ??
                      5000.0,
                  min: 5000.0,
                  max: 1000000.0,
                  divisions: 199,
                  label: _amountController.text,
                  onChanged: (val) {
                    setState(() {
                      _amountController.text = val.toInt().toString();
                    });
                  },
                  onChangeEnd: (val) {
                    _calculateQuantities();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quick Percentages
                    Row(
                      children: [10, 25, 50, 100]
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: OutlinedButton(
                                onPressed: () =>
                                    _setAmountByPercentage(p.toDouble()),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                child: Text('$p%'),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    // Include Held Toggle
                    Row(
                      children: [
                        const Text(
                          'Include Held',
                          style: TextStyle(fontSize: 12),
                        ),
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
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Info Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Quantities are optimized to match ETF weights. 'Match Score' shows how closely we can replicate the index given stock prices.",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Column Headers
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: _StockListHeader(),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (otherItems.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "Stocks to Buy",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...otherItems.map((item) {
                    // Find original index for callbacks
                    int realIndex = displayItems.indexOf(
                      item,
                    ); // safe if displayItems preserves order/instances copy

                    double pct = 0;
                    if (totalActiveInvestment > 0 && item.lastPrice != null) {
                      pct =
                          (item.lastPrice! *
                              item.buyQuantity /
                              totalActiveInvestment) *
                          100;
                    }

                    // Matching Score Logic
                    double targetPct = item.etfWeight;
                    double diff = (targetPct - pct).abs();
                    Widget? matchWidget;

                    // If difference is small enough, consider it perfect
                    if (diff < 0.1) {
                      matchWidget = Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Target: ${targetPct.toStringAsFixed(1)}%",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                        ],
                      );
                    } else {
                      double score = (100.0 - diff).clamp(0.0, 100.0);
                      Color scoreColor = score > 98
                          ? Colors.green
                          : (score > 90 ? Colors.orange : Colors.red);

                      matchWidget = Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Target: ${targetPct.toStringAsFixed(1)}%",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                          Container(
                            height: 1,
                            width: 40,
                            color: Colors.grey.shade300,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                          ),
                          Text(
                            "Match: ${score.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                        ],
                      );
                    }

                    return _EditableBasketItemCard(
                      item: item,
                      investmentPercentage: pct,
                      substituteOverride: matchWidget,
                      onRemove: () {
                        int realIndex = displayItems.indexOf(item);
                        _removeItem(realIndex);
                      },
                      onQuantityChanged: (val) {
                        int realIndex = displayItems.indexOf(item);
                        _updateQuantity(realIndex, val);
                      },
                    );
                  }),
                ],

                if (heldItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Text(
                          "Already Held",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (!_includeHeld)
                          const Text(
                            "(Excluded from calculation)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ...heldItems.map((item) {
                    double pct = 0;
                    if (totalActiveInvestment > 0 && item.lastPrice != null) {
                      pct =
                          (item.lastPrice! *
                              item.buyQuantity /
                              totalActiveInvestment) *
                          100;
                    }

                    // Calculation for Held Logic: Target% - Held% = Need%
                    // Updated Logic: Held% is relative to the Investment Amount (Proposed Basket Size)
                    double heldPct = 0;

                    // We use the investment amount from the controller as the denominator
                    double targetInvestment =
                        double.tryParse(_amountController.text) ??
                        totalActiveInvestment;

                    // Use Average Price (Cost Basis) for Held Value if available, as per user request
                    if (item.heldQuantity != null &&
                        item.heldAveragePrice != null &&
                        targetInvestment > 0) {
                      double heldValue =
                          item.heldQuantity! * item.heldAveragePrice!;
                      heldPct = (heldValue / targetInvestment) * 100;
                    } else if (item.heldQuantity != null &&
                        item.lastPrice != null &&
                        targetInvestment > 0) {
                      // Fallback to market value if avg price missing
                      double heldValue = item.heldQuantity! * item.lastPrice!;
                      heldPct = (heldValue / targetInvestment) * 100;
                    } else {
                      // Fallback to userWeight if heldQuantity is missing (backward compatibility)
                      heldPct = item.userWeight;
                    }

                    double targetPct = item.etfWeight;
                    double diff = targetPct - heldPct;

                    Widget? calcWidget;
                    if (diff > 0.1) {
                      // Under-held
                      calcWidget = Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Held: ${heldPct.toStringAsFixed(1)}%",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                          Container(
                            height: 1,
                            width: 40,
                            color: Colors.grey.shade300,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                          ),
                          Text(
                            "Need: ${diff.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      );
                    } else if (diff < -0.1) {
                      // Over-held
                      calcWidget = Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Held: ${heldPct.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          Container(
                            height: 1,
                            width: 40,
                            color: Colors.grey.shade300,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                          ),
                          const Text(
                            "Need: 0%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Fulfilled
                      calcWidget = Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            "Fulfilled",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    }

                    return Opacity(
                      opacity: _includeHeld ? 1.0 : 0.6,
                      child: _EditableBasketItemCard(
                        item: item,
                        investmentPercentage: _includeHeld ? pct : null,
                        substituteOverride: calcWidget,
                        readOnly: !_includeHeld,
                        onRemove: () {
                          int realIndex = displayItems.indexOf(item);
                          _removeItem(realIndex);
                        },
                        onQuantityChanged: (val) {
                          int realIndex = displayItems.indexOf(item);
                          _updateQuantity(realIndex, val);
                        },
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _InvestmentSummaryFooter(
        items: _items,
        includeHeld: _includeHeld,
        onInvest: _savePortfolio,
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
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
  final double? investmentPercentage;
  final Widget? substituteOverride;

  const _EditableBasketItemCard({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
    this.readOnly = false,
    this.investmentPercentage,
    this.substituteOverride,
  });

  Widget _buildIconBadge(
    BuildContext context,
    IconData icon,
    String tooltip,
    Color color,
  ) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Icon(icon, size: 12, color: color),
      ),
    );
  }

  IconData _getSectorIcon(String sectorData) {
    final sector = sectorData.toLowerCase();
    if (sector.contains('bank') || sector.contains('finance'))
      return Icons.account_balance;
    if (sector.contains('it') || sector.contains('tech')) return Icons.computer;
    if (sector.contains('auto')) return Icons.directions_car;
    if (sector.contains('pharma') || sector.contains('health'))
      return Icons.local_hospital;
    if (sector.contains('fmcg') || sector.contains('food'))
      return Icons.shopping_basket;
    if (sector.contains('metal') || sector.contains('steel'))
      return Icons.engineering;
    if (sector.contains('oil') ||
        sector.contains('energy') ||
        sector.contains('power'))
      return Icons.flash_on;
    return Icons.business;
  }

  Widget _buildCompactInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              label,
              style: const TextStyle(fontSize: 8, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              color: valueColor ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: [
            // Column 1: Symbol & Info (Flex 22)
            Expanded(
              flex: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.stockSymbol,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      _buildIconBadge(
                        context,
                        _getSectorIcon(item.sector),
                        item.sector,
                        Colors.blue.shade700,
                      ),
                      if (item.marketCapCategory != null)
                        _buildIconBadge(
                          context,
                          Icons.bar_chart,
                          item.marketCapCategory!,
                          Colors.purple.shade700,
                        ),
                    ],
                  ),
                  if (item.heldQuantity != null && item.heldQuantity! > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        "Held: ${item.heldQuantity!.toInt()} @ ₹${item.heldAveragePrice?.toStringAsFixed(0) ?? '-'}",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Column 2: Live Price (Flex 12)
            Expanded(
              flex: 12,
              child: item.lastPrice != null
                  ? Text(
                      "₹${item.lastPrice!.toStringAsFixed(1)}",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.right,
                    )
                  : const Text("-", textAlign: TextAlign.right),
            ),

            // Column 3: Target % (Flex 10)
            Expanded(
              flex: 10,
              child: Text(
                "${item.etfWeight.toStringAsFixed(1)}%",
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),

            // Column 4: Actual % (Flex 10)
            Expanded(
              flex: 10,
              child: investmentPercentage != null && investmentPercentage! > 0
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${investmentPercentage!.toStringAsFixed(1)}%",
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),

            // Column 5: Substitute (Flex 8)
            Expanded(
              flex: 8,
              child:
                  substituteOverride ??
                  (item.status == ItemStatus.substitute
                      ? const Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: AppColors.info,
                        )
                      : const SizedBox()),
            ),

            // Column 6: Quantity (Flex 18)
            Expanded(
              flex: 18,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!readOnly)
                        InkWell(
                          onTap: () {
                            if (item.buyQuantity > 0)
                              onQuantityChanged(item.buyQuantity - 1);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      Text(
                        item.buyQuantity.toInt().toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: readOnly ? Colors.grey : null,
                        ),
                      ),
                      if (!readOnly)
                        InkWell(
                          onTap: () => onQuantityChanged(item.buyQuantity + 1),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.add_circle_outline,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (item.heldQuantity != null && item.heldQuantity! > 0)
                    Text(
                      "Buy: ${(item.buyQuantity - item.heldQuantity!).clamp(0.0, 9999).toInt()}",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: (item.buyQuantity - item.heldQuantity!) > 0
                            ? Theme.of(context).primaryColor
                            : Colors.green,
                      ),
                    ),
                ],
              ),
            ),

            // Column 7: Actions (Flex 8)
            Expanded(
              flex: 8,
              child: !readOnly
                  ? IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.error,
                      ),
                      onPressed: onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockListHeader extends StatelessWidget {
  const _StockListHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildHeaderCell(context, "Asset", 22, TextAlign.start),
        _buildHeaderCell(context, "Price", 12, TextAlign.right),
        _buildHeaderCell(context, "Target", 10, TextAlign.center),
        _buildHeaderCell(context, "Actual", 10, TextAlign.center),
        _buildHeaderCell(context, "Swap", 8, TextAlign.center),
        _buildHeaderCell(context, "Qty", 18, TextAlign.center),
        _buildHeaderCell(context, "", 8, TextAlign.center),
      ],
    );
  }

  Widget _buildHeaderCell(
    BuildContext context,
    String label,
    int flex,
    TextAlign align,
  ) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
        textAlign: align,
      ),
    );
  }
}

class _AllocationSummary extends StatelessWidget {
  final List<BasketItem> items;
  final bool includeHeld;

  const _AllocationSummary({required this.items, required this.includeHeld});

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Sector Allocation
    final Map<String, double> sectorWeights = {};
    double totalWeight = 0;

    final activeItems = includeHeld
        ? items
        : items.where((i) => i.status != ItemStatus.held).toList();

    for (var item in activeItems) {
      double weight = 0;
      if (item.lastPrice != null && item.buyQuantity > 0) {
        weight = item.lastPrice! * item.buyQuantity;
      } else {
        weight = item.etfWeight; // Fallback to target weight
      }

      sectorWeights[item.sector] = (sectorWeights[item.sector] ?? 0) + weight;
      totalWeight += weight;
    }

    final sectorSegments = sectorWeights.entries.map((e) {
      return AllocationSegment(
        label: e.key,
        percentage: totalWeight > 0 ? e.value / totalWeight : 0,
        color: _getColorForSector(e.key),
      );
    }).toList();

    // Sort by percentage desc
    sectorSegments.sort((a, b) => b.percentage.compareTo(a.percentage));
    // Limit to top 4 + Other
    List<AllocationSegment> displaySegments = [];
    if (sectorSegments.length > 4) {
      displaySegments = sectorSegments.take(4).toList();
      double otherPct = sectorSegments
          .skip(4)
          .fold(0.0, (sum, s) => sum + s.percentage);
      displaySegments.add(
        AllocationSegment(
          label: "Others",
          percentage: otherPct,
          color: Colors.grey.shade400,
        ),
      );
    } else {
      displaySegments = sectorSegments;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sector Allocation",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              // Could toggle between Sector / Market Cap here
            ],
          ),
          const SizedBox(height: 8),
          AllocationBar(segments: displaySegments),
        ],
      ),
    );
  }

  Color _getColorForSector(String sector) {
    // deterministic color generation
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFE91E63), // Pink
    ];
    // Use hashcode of sector string for deterministic color assignment
    // Using codeUnitAt to behave similarly to index if possible, but hash is safer for unknowns
    return colors[sector.hashCode.abs() % colors.length];
  }
}

class _InvestmentSummaryFooter extends StatelessWidget {
  final List<BasketItem> items;
  final bool includeHeld;
  final VoidCallback onInvest;

  const _InvestmentSummaryFooter({
    required this.items,
    required this.includeHeld,
    required this.onInvest,
  });

  @override
  Widget build(BuildContext context) {
    double totalPayable = 0;

    // Logic:
    // If includeHeld is false: Payable = Sum(BuyQty * LTP) for only non-held items (BuyQty is total for them anyway)
    // If includeHeld is true: Payable = Sum(Max(0, BuyQty - HeldQty) * LTP) for ALL items

    // Current Implementation of `items`:
    // `_items` contains the valid BasketItems.
    // If we are in `includeHeld` mode, all items are active.
    // If not, only non-held are active.

    // Wait, the `buyQuantity` in `_items` (which comes from `displayItems` enrichment) represents the TOTAL DESIRED QUANTITY.

    final activeItems = includeHeld
        ? items
        : items.where((i) => i.status != ItemStatus.held).toList();

    for (var item in activeItems) {
      if (item.lastPrice != null) {
        double qtyToPayFor = item.buyQuantity;
        if (includeHeld && item.heldQuantity != null) {
          qtyToPayFor = (qtyToPayFor - item.heldQuantity!).clamp(0.0, 999999.0);
        }
        totalPayable += item.lastPrice! * qtyToPayFor;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payable Amount",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                Text(
                  "₹${totalPayable.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: totalPayable > 0 ? onInvest : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(140, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Pay & Invest"),
            ),
          ],
        ),
      ),
    );
  }
}
