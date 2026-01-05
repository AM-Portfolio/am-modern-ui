import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrencyConfig {
  const CurrencyConfig({required this.code, required this.symbol});
  final String code;
  final String symbol;

  static const CurrencyConfig inr = CurrencyConfig(code: 'INR', symbol: '₹');
  static const CurrencyConfig usd = CurrencyConfig(code: 'USD', symbol: r'$');
}

class UserCurrencyNotifier extends Notifier<CurrencyConfig> {
  @override
  CurrencyConfig build() => CurrencyConfig.inr;

  void setCurrency(CurrencyConfig config) {
    state = config;
  }
}

final userCurrencyProvider =
    NotifierProvider<UserCurrencyNotifier, CurrencyConfig>(
      UserCurrencyNotifier.new,
    );
