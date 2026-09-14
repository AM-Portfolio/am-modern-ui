import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarginCalculatorView extends ConsumerStatefulWidget {
  const MarginCalculatorView({super.key});

  @override
  ConsumerState<MarginCalculatorView> createState() => _MarginCalculatorViewState();
}

class _MarginCalculatorViewState extends ConsumerState<MarginCalculatorView> {
  final TextEditingController _quantityController = TextEditingController(text: '50');
  final TextEditingController _priceController = TextEditingController(text: '2203.50');
  String _selectedType = 'Buy';
  String _selectedProduct = 'NRML';

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;
    final activeSymbol = ref.watch(foActiveSymbolProvider) ?? 'NIFTY';
    final selectedContract = ref.watch(selectedFutureContractProvider);

    final contractTitle = selectedContract != null
        ? (selectedContract['trading_symbol'] ?? selectedContract['tradingSymbol'] ?? '$activeSymbol FUT 24 SEP 26').toString()
        : '$activeSymbol FUT 24 SEP 26';

    // Parse inputs for calculation
    final qty = int.tryParse(_quantityController.text) ?? 50;
    final price = double.tryParse(_priceController.text) ?? 2203.50;
    final notionalValue = qty * price;
    
    final spanMargin = notionalValue * 0.15;
    final exposureMargin = notionalValue * 0.03;
    final totalMargin = spanMargin + exposureMargin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_rounded, color: ModuleColors.market, size: 22),
              const SizedBox(width: 8),
              Text(
                'Margin Calculator',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                '· Estimate SPAN & Exposure Margins for $activeSymbol Futures',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Form Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.5),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Position Details', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Contract dropdown / display
                    _buildInputGroup('Contract', Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(contractTitle, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_drop_down, color: colors.textSecondary),
                        ],
                      ),
                    ), colors),

                    // Quantity input
                    _buildInputGroup('Quantity', SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _quantityController,
                        style: TextStyle(color: colors.textPrimary),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
                        ),
                      ),
                    ), colors),

                    // Type toggle (Buy/Sell)
                    _buildInputGroup('Type', Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildChoiceChip('Buy', _selectedType == 'Buy', marketTheme.positive, () => setState(() => _selectedType = 'Buy')),
                        const SizedBox(width: 8),
                        _buildChoiceChip('Sell', _selectedType == 'Sell', marketTheme.negative, () => setState(() => _selectedType = 'Sell')),
                      ],
                    ), colors),

                    // Product toggle (NRML/MIS)
                    _buildInputGroup('Product', Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildChoiceChip('NRML', _selectedProduct == 'NRML', ModuleColors.market, () => setState(() => _selectedProduct = 'NRML')),
                        const SizedBox(width: 8),
                        _buildChoiceChip('MIS', _selectedProduct == 'MIS', ModuleColors.market, () => setState(() => _selectedProduct = 'MIS')),
                      ],
                    ), colors),

                    // Price input
                    _buildInputGroup('Price (₹)', SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _priceController,
                        style: TextStyle(color: colors.textPrimary),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
                        ),
                      ),
                    ), colors),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Margin Summary Cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMarginCard('SPAN Margin', '₹${spanMargin.toStringAsFixed(2)}', colors),
              _buildMarginCard('Exposure Margin', '₹${exposureMargin.toStringAsFixed(2)}', colors),
              _buildMarginCard('Additional Margin', '₹0.00', colors),
              _buildMarginCard('Total Margin Required', '₹${totalMargin.toStringAsFixed(2)}', colors, isHighlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputGroup(String label, Widget child, AppColorsTheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, Color activeColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? activeColor : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildMarginCard(String label, String amount, AppColorsTheme colors, {bool isHighlight = false}) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? ModuleColors.market.withValues(alpha: 0.15) : colors.surface.withValues(alpha: 0.5),
        border: Border.all(color: isHighlight ? ModuleColors.market : colors.border.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              color: isHighlight ? ModuleColors.market : colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
