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
        ? (selectedContract['trading_symbol'] ??
                selectedContract['tradingSymbol'] ??
                '$activeSymbol FUT 24 SEP 26')
            .toString()
        : '$activeSymbol FUT 24 SEP 26';

    final qty = int.tryParse(_quantityController.text) ?? 50;
    final price = double.tryParse(_priceController.text) ?? 2203.50;
    final notionalValue = qty * price;

    final spanMargin = notionalValue * 0.15;
    final exposureMargin = notionalValue * 0.03;
    final totalMargin = spanMargin + exposureMargin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_rounded, color: ModuleColors.market, size: 20),
              const SizedBox(width: 8),
              Text(
                'Margin Calculator',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estimate SPAN & Exposure Margins for $activeSymbol Futures',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Form — full width
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.5),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Position Details',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    final fields = <Widget>[
                      _buildInputGroup(
                        'Contract',
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border.all(color: colors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contractTitle,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: colors.textSecondary),
                            ],
                          ),
                        ),
                        colors,
                      ),
                      _buildInputGroup(
                        'Quantity',
                        TextField(
                          controller: _quantityController,
                          style: TextStyle(color: colors.textPrimary),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.border),
                            ),
                          ),
                        ),
                        colors,
                      ),
                      _buildInputGroup(
                        'Type',
                        Row(
                          children: [
                            Expanded(
                              child: _buildChoiceChip(
                                'Buy',
                                _selectedType == 'Buy',
                                marketTheme.positive,
                                () => setState(() => _selectedType = 'Buy'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildChoiceChip(
                                'Sell',
                                _selectedType == 'Sell',
                                marketTheme.negative,
                                () => setState(() => _selectedType = 'Sell'),
                              ),
                            ),
                          ],
                        ),
                        colors,
                      ),
                      _buildInputGroup(
                        'Product',
                        Row(
                          children: [
                            Expanded(
                              child: _buildChoiceChip(
                                'NRML',
                                _selectedProduct == 'NRML',
                                ModuleColors.market,
                                () => setState(() => _selectedProduct = 'NRML'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildChoiceChip(
                                'MIS',
                                _selectedProduct == 'MIS',
                                ModuleColors.market,
                                () => setState(() => _selectedProduct = 'MIS'),
                              ),
                            ),
                          ],
                        ),
                        colors,
                      ),
                      _buildInputGroup(
                        'Price (₹)',
                        TextField(
                          controller: _priceController,
                          style: TextStyle(color: colors.textPrimary),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.border),
                            ),
                          ),
                        ),
                        colors,
                      ),
                    ];

                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < fields.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            fields[i],
                          ],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < fields.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(flex: i == 0 ? 2 : 1, child: fields[i]),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Margin cards — fill full width evenly
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _buildMarginCard(
                  'SPAN Margin',
                  '₹${spanMargin.toStringAsFixed(2)}',
                  colors,
                ),
                _buildMarginCard(
                  'Exposure Margin',
                  '₹${exposureMargin.toStringAsFixed(2)}',
                  colors,
                ),
                _buildMarginCard('Additional Margin', '₹0.00', colors),
                _buildMarginCard(
                  'Total Margin Required',
                  '₹${totalMargin.toStringAsFixed(2)}',
                  colors,
                  isHighlight: true,
                ),
              ];

              if (constraints.maxWidth < 640) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: cards
                      .map(
                        (c) => SizedBox(
                          width: (constraints.maxWidth - 10) / 2,
                          child: c,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputGroup(String label, Widget child, AppColorsTheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildChoiceChip(
    String label,
    bool isSelected,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMarginCard(
    String label,
    String amount,
    AppColorsTheme colors, {
    bool isHighlight = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlight
            ? ModuleColors.market.withValues(alpha: 0.15)
            : colors.surface.withValues(alpha: 0.5),
        border: Border.all(
          color: isHighlight ? ModuleColors.market : colors.border.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                color: isHighlight ? ModuleColors.market : colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
