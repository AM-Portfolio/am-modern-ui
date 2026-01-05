import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrencyConfig {
  final String code;
  final String symbol;

  const CurrencyConfig({required this.code, required this.symbol});

  static const CurrencyConfig inr = CurrencyConfig(code: 'INR', symbol: '₹');
  static const CurrencyConfig usd = CurrencyConfig(code: 'USD', symbol: '\$');
}

class UserCurrencyNotifier extends Notifier<CurrencyConfig> {
  @override
  CurrencyConfig build() {
    return CurrencyConfig.inr;
  }

  void setCurrency(CurrencyConfig config) {
    state = config;
  }
}

final userCurrencyProvider = NotifierProvider<UserCurrencyNotifier, CurrencyConfig>(() {
  return UserCurrencyNotifier();
});
