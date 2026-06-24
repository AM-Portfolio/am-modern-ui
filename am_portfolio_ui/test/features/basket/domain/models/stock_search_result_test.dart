import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/stock_search_result.dart';

void main() {
  group('StockSearchResult.fromJson', () {
    test('parses symbol from json', () {
      final json = {'symbol': 'RELIANCE', 'name': 'Reliance Industries'};
      final result = StockSearchResult.fromJson(json);
      expect(result.symbol, equals('RELIANCE'));
    });

    test('defaults symbol to empty string when absent', () {
      final result = StockSearchResult.fromJson({'name': 'Some Company'});
      expect(result.symbol, equals(''));
    });

    test('uses name key when companyName is absent', () {
      final json = {'symbol': 'TCS', 'name': 'Tata Consultancy Services'};
      final result = StockSearchResult.fromJson(json);
      expect(result.name, equals('Tata Consultancy Services'));
    });

    test('uses companyName key and ignores name key when both present', () {
      // companyName takes priority over name (it's listed first in ?? chain)
      final json = {
        'symbol': 'INFY',
        'companyName': 'Infosys Limited',
        'name': 'Other Name',
      };
      final result = StockSearchResult.fromJson(json);
      expect(result.name, equals('Infosys Limited'));
    });

    test('uses name key when companyName is absent (search API format)', () {
      final json = {
        'symbol': 'WIPRO',
        'name': 'Wipro Ltd',
      };
      final result = StockSearchResult.fromJson(json);
      expect(result.name, equals('Wipro Ltd'));
    });

    test('defaults name to empty string when both companyName and name are absent', () {
      final result = StockSearchResult.fromJson({'symbol': 'UNKNOWN'});
      expect(result.name, equals(''));
    });

    test('uses marketCapType key for marketCapCategory when present', () {
      final json = {
        'symbol': 'HDFC',
        'name': 'HDFC Bank',
        'marketCapType': 'Large Cap',
      };
      final result = StockSearchResult.fromJson(json);
      expect(result.marketCapCategory, equals('Large Cap'));
    });

    test('uses market_cap_category key when marketCapType is absent', () {
      final json = {
        'symbol': 'HCLTECH',
        'name': 'HCL Technologies',
        'market_cap_category': 'Mid Cap',
      };
      final result = StockSearchResult.fromJson(json);
      expect(result.marketCapCategory, equals('Mid Cap'));
    });

    test('marketCapType takes priority over market_cap_category when both present', () {
      final json = {
        'symbol': 'AXIS',
        'name': 'Axis Bank',
        'marketCapType': 'Large Cap',
        'market_cap_category': 'Small Cap',
      };
      final result = StockSearchResult.fromJson(json);
      expect(result.marketCapCategory, equals('Large Cap'));
    });

    test('marketCapCategory is null when neither key is present', () {
      final json = {'symbol': 'TATA', 'name': 'Tata Motors'};
      final result = StockSearchResult.fromJson(json);
      expect(result.marketCapCategory, isNull);
    });

    test('parses isin correctly', () {
      final json = {
        'symbol': 'ICICI',
        'name': 'ICICI Bank',
        'isin': 'INE090A01021',
      };
      final result = StockSearchResult.fromJson(json);
      expect(result.isin, equals('INE090A01021'));
    });

    test('isin is null when absent', () {
      final result = StockSearchResult.fromJson({'symbol': 'X', 'name': 'Y'});
      expect(result.isin, isNull);
    });

    test('parses marketCapValue as double', () {
      final json = {
        'symbol': 'SBIN',
        'name': 'State Bank of India',
        'marketCapValue': 500000000000,
      };
      final result = StockSearchResult.fromJson(json);
      expect(result.marketCapValue, equals(500000000000.0));
    });

    test('marketCapValue is null when absent', () {
      final result = StockSearchResult.fromJson({'symbol': 'X', 'name': 'Y'});
      expect(result.marketCapValue, isNull);
    });

    test('parses sector correctly', () {
      final json = {
        'symbol': 'BAJFINANCE',
        'name': 'Bajaj Finance',
        'sector': 'Financial Services',
      };
      final result = StockSearchResult.fromJson(json);
      expect(result.sector, equals('Financial Services'));
    });

    test('sector is null when absent', () {
      final result = StockSearchResult.fromJson({'symbol': 'X', 'name': 'Y'});
      expect(result.sector, isNull);
    });

    test('parses batch API response format with companyName', () {
      // Batch API uses 'companyName' key
      final batchJson = {
        'symbol': 'ZOMATO',
        'companyName': 'Zomato Limited',
        'isin': 'INE758T01015',
        'marketCapType': 'Large Cap',
        'marketCapValue': 100000000000.0,
        'sector': 'Consumer Services',
      };
      final result = StockSearchResult.fromJson(batchJson);

      expect(result.symbol, equals('ZOMATO'));
      expect(result.name, equals('Zomato Limited'));
      expect(result.isin, equals('INE758T01015'));
      expect(result.marketCapCategory, equals('Large Cap'));
      expect(result.marketCapValue, equals(100000000000.0));
      expect(result.sector, equals('Consumer Services'));
    });

    test('parses search API response format with name', () {
      // Search API uses 'name' and 'market_cap_category' keys
      final searchJson = {
        'symbol': 'PAYTM',
        'name': 'One 97 Communications',
        'isin': 'INE982J01020',
        'market_cap_category': 'Small Cap',
        'sector': 'Fintech',
      };
      final result = StockSearchResult.fromJson(searchJson);

      expect(result.symbol, equals('PAYTM'));
      expect(result.name, equals('One 97 Communications'));
      expect(result.isin, equals('INE982J01020'));
      expect(result.marketCapCategory, equals('Small Cap'));
      expect(result.sector, equals('Fintech'));
    });
  });
}
