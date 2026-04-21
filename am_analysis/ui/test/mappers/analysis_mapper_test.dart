import 'package:flutter_test/flutter_test.dart';
import 'package:am_analysis_ui/mappers/analysis_mapper.dart';
import 'package:am_analysis_ui/models/analysis_enums.dart';
import 'package:am_analysis_sdk/api.dart' as sdk;

void main() {
  group('AnalysisMapper', () {
    group('toAllocationItems', () {
      test('should convert SDK AllocationResponse with sector data', () {
        final sdkResponse = sdk.AllocationResponse(
          sectors: [
            sdk.AllocationItem(name: 'Technology', percentage: 45.0, value: 45000.0),
            sdk.AllocationItem(name: 'Finance', percentage: 25.0, value: 25000.0),
          ],
        );

        final result = AnalysisMapper.toAllocationItems(sdkResponse, GroupBy.sector);

        expect(result.length, 2);
        expect(result[0].name, 'Technology');
        expect(result[0].percentage, 45.0);
        expect(result[0].value, 45000.0);
      });

      test('should handle null response', () {
        final result = AnalysisMapper.toAllocationItems(null, GroupBy.sector);
        expect(result, isEmpty);
      });

      test('should handle empty sectors list', () {
        final sdkResponse = sdk.AllocationResponse(sectors: []);
        final result = AnalysisMapper.toAllocationItems(sdkResponse, GroupBy.sector);
        expect(result, isEmpty);
      });

      test('should use fallback values for missing fields', () {
        final sdkResponse = sdk.AllocationResponse(
          sectors: [
            sdk.AllocationItem(), // All fields null
          ],
        );

        final result = AnalysisMapper.toAllocationItems(sdkResponse, GroupBy.sector);

        expect(result.length, 1);
        expect(result[0].name, 'Unknown');
        expect(result[0].percentage, 0.0);
        expect(result[0].value, 0.0);
      });

      test('should select stocks list for stock groupBy', () {
        final sdkResponse = sdk.AllocationResponse(
          stocks: [
            sdk.AllocationItem(name: 'AAPL', percentage: 10.0, value: 10000.0),
          ],
        );

        final result = AnalysisMapper.toAllocationItems(sdkResponse, GroupBy.stock);

        expect(result.length, 1);
        expect(result[0].name, 'AAPL');
      });
    });

    group('toMoverItems', () {
      test('should convert SDK TopMoversResponse with gainers and losers', () {
        final sdkResponse = sdk.TopMoversResponse(
          gainers: [
            sdk.MoverItem(
              symbol: 'AAPL',
              name: 'Apple Inc.',
              price: 175.50,
              changePercentage: 2.5,
              changeAmount: 4.30,
            ),
          ],
          losers: [
            sdk.MoverItem(
              symbol: 'TSLA',
              name: 'Tesla Inc.',
              price: 200.00,
              changePercentage: -1.5,
              changeAmount: -3.00,
            ),
          ],
        );

        final result = AnalysisMapper.toMoverItems(sdkResponse);

        expect(result.length, 2);
        expect(result[0].symbol, 'AAPL');
        expect(result[0].changePercentage, 2.5);
        expect(result[1].symbol, 'TSLA');
        expect(result[1].changePercentage, -1.5);
      });

      test('should handle null response', () {
        final result = AnalysisMapper.toMoverItems(null);
        expect(result, isEmpty);
      });

      test('should handle only gainers', () {
        final sdkResponse = sdk.TopMoversResponse(
          gainers: [
            sdk.MoverItem(symbol: 'GOOGL', name: 'Alphabet', price: 135.0),
          ],
        );

        final result = AnalysisMapper.toMoverItems(sdkResponse);
        expect(result.length, 1);
        expect(result[0].symbol, 'GOOGL');
      });
    });

    group('toPerformanceDataPoints', () {
      test('should convert SDK PerformanceResponse to DataPoints', () {
        final sdkResponse = sdk.PerformanceResponse(
          chartData: [
            sdk.DataPoint(date: DateTime.parse('2024-01-01T00:00:00Z'), value: 10000.0),
            sdk.DataPoint(date: DateTime.parse('2024-01-02T00:00:00Z'), value: 10100.0),
          ],
        );

        final result = AnalysisMapper.toPerformanceDataPoints(sdkResponse);

        expect(result.length, 2);
        expect(result[0].date, DateTime.parse('2024-01-01T00:00:00Z'));
        expect(result[0].value, 10000.0);
      });

      test('should handle null response', () {
        final result = AnalysisMapper.toPerformanceDataPoints(null);
        expect(result, isEmpty);
      });

      test('should handle null chartData', () {
        final sdkResponse = sdk.PerformanceResponse();
        final result = AnalysisMapper.toPerformanceDataPoints(sdkResponse);
        expect(result, isEmpty);
      });
    });
  });
}
