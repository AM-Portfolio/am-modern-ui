import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarginCalculatorView extends ConsumerStatefulWidget {
  const MarginCalculatorView({super.key});

  @override
  ConsumerState<MarginCalculatorView> createState() =>
      _MarginCalculatorViewState();
}

class _MarginCalculatorViewState extends ConsumerState<MarginCalculatorView> {
  final TextEditingController _quantityController =
      TextEditingController(text: '50');
  final TextEditingController _priceController =
      TextEditingController(text: '2203.50');
  String _selectedType = 'Buy';
  String _selectedProduct = 'NRML';

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_onInputChanged);
    _priceController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _quantityController
      ..removeListener(_onInputChanged)
      ..dispose();
    _priceController
      ..removeListener(_onInputChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;
    final activeSymbol = ref.watch(foActiveSymbolProvider) ?? 'NIFTY';
    final selectedContract = ref.watch(selectedFutureContractProvider);
    final contracts = ref.watch(futuresContractsProvider).maybeWhen(
          data: (d) => d,
          orElse: () => <dynamic>[],
        );

    final contractTitle = selectedContract != null
        ? (selectedContract['trading_symbol'] ??
                selectedContract['tradingSymbol'] ??
                '$activeSymbol FUT')
            .toString()
        : '$activeSymbol FUT';

    final qty = int.tryParse(_quantityController.text) ?? 50;
    final price = double.tryParse(_priceController.text) ?? 2203.50;
    final notionalValue = qty * price;

    final spanMargin = notionalValue * 0.15;
    final exposureMargin = notionalValue * 0.03;
    const additionalMargin = 0.0;
    final totalMargin = spanMargin + exposureMargin + additionalMargin;

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AmBreakpoints.mobile;
    final isNarrowMobile = width < 400;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 10 : 16,
        isMobile ? 8 : 16,
        isMobile ? 10 : 16,
        (isMobile ? 10 : 16) + viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 16),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.5),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Position Details',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 15,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                _buildInputGroup(
                  'Contract',
                  InkWell(
                    onTap: () => _openContractSheet(contracts, activeSymbol),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: isMobile ? 10 : 12,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 13 : 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  colors,
                  compact: isMobile,
                ),
                SizedBox(height: isMobile ? 8 : 12),
                if (isMobile && !isNarrowMobile)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildInputGroup(
                          'Quantity',
                          TextField(
                            controller: _quantityController,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                            ),
                            keyboardType: TextInputType.number,
                            decoration: _fieldDecoration(colors, compact: true),
                          ),
                          colors,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInputGroup(
                          'Price (₹)',
                          TextField(
                            controller: _priceController,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _fieldDecoration(colors, compact: true),
                          ),
                          colors,
                          compact: true,
                        ),
                      ),
                    ],
                  )
                else
                  _buildInputGroup(
                    'Quantity',
                    TextField(
                      controller: _quantityController,
                      style: TextStyle(color: colors.textPrimary),
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration(colors, compact: isMobile),
                    ),
                    colors,
                    compact: isMobile,
                  ),
                SizedBox(height: isMobile ? 8 : 12),
                _buildInputGroup(
                  'Type',
                  Row(
                    children: [
                      Expanded(
                        child: _buildSegment(
                          'Buy',
                          _selectedType == 'Buy',
                          marketTheme.positive,
                          () => setState(() => _selectedType = 'Buy'),
                          compact: isMobile,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSegment(
                          'Sell',
                          _selectedType == 'Sell',
                          marketTheme.negative,
                          () => setState(() => _selectedType = 'Sell'),
                          compact: isMobile,
                        ),
                      ),
                    ],
                  ),
                  colors,
                  compact: isMobile,
                ),
                SizedBox(height: isMobile ? 8 : 12),
                _buildInputGroup(
                  'Product',
                  Row(
                    children: [
                      Expanded(
                        child: _buildSegment(
                          'NRML',
                          _selectedProduct == 'NRML',
                          ModuleColors.market,
                          () => setState(() => _selectedProduct = 'NRML'),
                          compact: isMobile,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSegment(
                          'MIS',
                          _selectedProduct == 'MIS',
                          ModuleColors.market,
                          () => setState(() => _selectedProduct = 'MIS'),
                          compact: isMobile,
                        ),
                      ),
                    ],
                  ),
                  colors,
                  compact: isMobile,
                ),
                if (!(isMobile && !isNarrowMobile)) ...[
                  SizedBox(height: isMobile ? 8 : 12),
                  _buildInputGroup(
                    'Price (₹)',
                    TextField(
                      controller: _priceController,
                      style: TextStyle(color: colors.textPrimary),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _fieldDecoration(colors, compact: isMobile),
                    ),
                    colors,
                    compact: isMobile,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: isMobile ? 10 : 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final useSingleColumn = constraints.maxWidth < 400;
              final gap = isMobile ? 8.0 : 12.0;
              final cardWidth = useSingleColumn
                  ? constraints.maxWidth
                  : (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _buildMarginCard(
                    width: cardWidth,
                    label: 'SPAN Margin',
                    amount: '₹${spanMargin.toStringAsFixed(2)}',
                    icon: Icons.shield_outlined,
                    colors: colors,
                    compact: isMobile,
                  ),
                  _buildMarginCard(
                    width: cardWidth,
                    label: 'Exposure Margin',
                    amount: '₹${exposureMargin.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_outlined,
                    colors: colors,
                    compact: isMobile,
                  ),
                  _buildMarginCard(
                    width: cardWidth,
                    label: 'Additional Margin',
                    amount: '₹${additionalMargin.toStringAsFixed(2)}',
                    icon: Icons.currency_exchange_rounded,
                    colors: colors,
                    compact: isMobile,
                  ),
                  _buildMarginCard(
                    width: cardWidth,
                    label: 'Total Margin Required',
                    amount: '₹${totalMargin.toStringAsFixed(2)}',
                    icon: Icons.calculate_rounded,
                    colors: colors,
                    isHighlight: true,
                    compact: isMobile,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openContractSheet(
    List<dynamic> contracts,
    String activeSymbol,
  ) async {
    if (contracts.isEmpty) return;
    final colors = context.colors;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: contracts.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: colors.border.withValues(alpha: 0.4),
            ),
            itemBuilder: (context, index) {
              final raw = contracts[index];
              if (raw is! Map) return const SizedBox.shrink();
              final map = Map<String, dynamic>.from(raw);
              final title = (map['trading_symbol'] ??
                      map['tradingSymbol'] ??
                      map['name'] ??
                      '$activeSymbol FUT')
                  .toString();
              return ListTile(
                title: Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  ref.read(selectedFutureContractProvider.notifier).state = {
                    ...map,
                    'trading_symbol': title,
                  };
                  final ltp = (map['ltp'] as num?)?.toDouble();
                  if (ltp != null && ltp > 0) {
                    _priceController.text = ltp.toStringAsFixed(2);
                  }
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        );
      },
    );
  }

  InputDecoration _fieldDecoration(
    AppColorsTheme colors, {
    bool compact = false,
  }) {
    return InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 10 : 12,
      ),
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ModuleColors.market),
      ),
    );
  }

  Widget _buildInputGroup(
    String label,
    Widget child,
    AppColorsTheme colors, {
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: compact ? 11 : 12,
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        child,
      ],
    );
  }

  Widget _buildSegment(
    String label,
    bool isSelected,
    Color activeColor,
    VoidCallback onTap, {
    bool compact = false,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.22)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? activeColor
                : colors.border.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : colors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: compact ? 12 : 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMarginCard({
    required double width,
    required String label,
    required String amount,
    required IconData icon,
    required AppColorsTheme colors,
    bool isHighlight = false,
    bool compact = false,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: isHighlight
            ? ModuleColors.market.withValues(alpha: 0.15)
            : colors.surface.withValues(alpha: 0.5),
        border: Border.all(
          color: isHighlight
              ? ModuleColors.market
              : colors.border.withValues(alpha: 0.5),
          width: isHighlight ? 1.4 : 1,
        ),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        boxShadow: isHighlight
            ? [
                BoxShadow(
                  color: ModuleColors.market.withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: compact ? 14 : 16,
                color: isHighlight ? ModuleColors.market : colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: TextStyle(
                color: isHighlight ? ModuleColors.market : colors.textPrimary,
                fontSize: compact
                    ? (isHighlight ? 16 : 14)
                    : (isHighlight ? 18 : 16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
