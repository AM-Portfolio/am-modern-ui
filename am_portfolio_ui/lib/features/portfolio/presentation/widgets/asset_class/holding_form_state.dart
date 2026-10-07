import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class HoldingFormState {
  final String id;
  final String name;
  final String symbol;
  final String? exchange;
  final String? segment;
  final String quantity;
  final String pricePerUnit;
  final String totalValue;

  HoldingFormState({
    required this.id,
    this.name = '',
    this.symbol = '',
    this.exchange,
    this.segment,
    this.quantity = '',
    this.pricePerUnit = '',
    this.totalValue = '',
  });

  HoldingFormState copyWith({
    String? name,
    String? symbol,
    String? exchange,
    String? segment,
    String? quantity,
    String? pricePerUnit,
    String? totalValue,
  }) {
    return HoldingFormState(
      id: id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      exchange: exchange ?? this.exchange,
      segment: segment ?? this.segment,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalValue: totalValue ?? this.totalValue,
    );
  }

  HoldingFormState updateQuantity(String newQuantity) {
    return copyWith(
      quantity: newQuantity,
      totalValue: _computeTotal(newQuantity, pricePerUnit),
    );
  }

  HoldingFormState updatePrice(String newPrice) {
    return copyWith(
      pricePerUnit: newPrice,
      totalValue: _computeTotal(quantity, newPrice),
    );
  }

  HoldingFormState updateTotalValue(String newTotal) {
    // If the user manually edits the total value, we clear qty and price to avoid mathematical conflicts.
    return copyWith(
      totalValue: newTotal,
      quantity: '',
      pricePerUnit: '',
    );
  }

  String _computeTotal(String qtyStr, String priceStr) {
    if (qtyStr.isEmpty || priceStr.isEmpty) return '';
    final qty = double.tryParse(qtyStr) ?? 0;
    final price = double.tryParse(priceStr) ?? 0;
    if (qty == 0 || price == 0) return '';
    return (qty * price).toStringAsFixed(2);
  }
}

class HoldingsNotifier extends Notifier<List<HoldingFormState>> {
  @override
  List<HoldingFormState> build() {
    return [_createEmptyRow()];
  }

  HoldingFormState _createEmptyRow() {
    // We read the type to apply smart defaults
    final type = ref.read(addAssetClassTypeProvider);
    String? defaultExchange;
    String? defaultSegment;
    
    if (type == 'bonds') {
      defaultExchange = 'NSE';
      defaultSegment = 'Government';
    } else if (type == 'commodities') {
      defaultExchange = 'MCX';
      defaultSegment = 'Precious Metals';
    }

    return HoldingFormState(
      id: const Uuid().v4(),
      exchange: defaultExchange,
      segment: defaultSegment,
    );
  }

  void addRow() {
    state = [...state, _createEmptyRow()];
  }

  void removeRow(String id) {
    if (state.length <= 1) return;
    state = state.where((h) => h.id != id).toList();
  }

  void updateRow(String id, HoldingFormState Function(HoldingFormState) updater) {
    state = state.map((h) {
      if (h.id == id) {
        return updater(h);
      }
      return h;
    }).toList();
  }
  
  void reset() {
    state = [_createEmptyRow()];
  }
}

class TypeNotifier extends Notifier<String> {
  @override
  String build() => 'bonds';

  void setType(String type) {
    state = type;
    // When type changes, we should reset the holdings to apply new smart defaults
    ref.read(addAssetClassHoldingsProvider.notifier).reset();
  }
}

final addAssetClassTypeProvider = NotifierProvider<TypeNotifier, String>(
  TypeNotifier.new,
);

final addAssetClassHoldingsProvider = NotifierProvider<HoldingsNotifier, List<HoldingFormState>>(
  HoldingsNotifier.new,
);

class AssetClassNameNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setName(String name) => state = name;
}

final addAssetClassNameProvider = NotifierProvider<AssetClassNameNotifier, String>(
  AssetClassNameNotifier.new,
);
