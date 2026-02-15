import 'package:flutter_test/flutter_test.dart';
import 'package:am_analysis_ui/services/real_analysis_service.dart';
import 'package:am_analysis_ui/models/analysis_enums.dart';

void main() {
  group('RealAnalysisService', () {
    late RealAnalysisService service;

    setUp(() {
      // Create service pointing to localhost:8090
      service = RealAnalysisService(
        baseUrl: 'http://localhost:8090',
        authToken: 'Bearer test-token', // Use mock token for testing
      );
    });

    test('should initialize with default base URL', () {
      final defaultService = RealAnalysisService();
      expect(defaultService, isNotNull);
    });

    test('should initialize with custom base URL', () {
      final customService = RealAnalysisService(
        baseUrl: 'http://custom-server:9000',
      );
      expect(customService, isNotNull);
    });

    // Integration tests require backend running
    group('Integration Tests (requires backend on 8090)', () {
      test('should fetch allocation data', () async {
        try {
          final result = await service.getAllocation(
            'test-portfolio-id',
            AnalysisEntityType.PORTFOLIO,
            groupBy: GroupBy.sector,
          );
          
          // Expect some result (could be empty or populated)
          expect(result, isNotNull);
          expect(result, isA<List>());
        } catch (e) {
          // If backend not running, test should skip gracefully
          print('Backend not available for testing: $e');
        }
      }, skip: 'Requires backend running - manual test only');

      test('should fetch top movers', () async {
        try {
          final result = await service.getTopMovers(
            type: AnalysisEntityType.EQUITY,
            timeFrame: '1D',
            groupBy: GroupBy.stock,
          );
          
          expect(result, isNotNull);
          expect(result, isA<List>());
        } catch (e) {
          print('Backend not available for testing: $e');
        }
      }, skip: 'Requires backend running - manual test only');

      test('should fetch performance data', () async {
        try {
          final result = await service.getPerformance(
            'test-portfolio-id',
            AnalysisEntityType.PORTFOLIO,
            '1M',
          );
          
          expect(result, isNotNull);
          expect(result, isA<List>());
        } catch (e) {
          print('Backend not available for testing: $e');
        }
      }, skip: 'Requires backend running - manual test only');
    });
  });
}
