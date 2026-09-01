import 'package:am_dashboard_ui/data/repositories/dashboard_json_sanitizer.dart';
import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardJsonSanitizer.summary', () {
    test('coerces null numeric fields so Freezed parse succeeds', () {
      final parsed = DashboardSummary.fromJson(
        DashboardJsonSanitizer.summary({
          'totalValue': null,
          'totalInvested': null,
          'totalGainLoss': null,
          'totalGainLossPercentage': null,
          'dayChange': null,
          'dayChangePercentage': null,
          'totalPortfolios': null,
        }),
      );
      expect(parsed.totalValue, 0);
      expect(parsed.totalInvested, 0);
      expect(parsed.dayChange, 0);
      expect(parsed.totalPortfolios, 0);
    });

    test('maps investmentValue onto totalInvested', () {
      final parsed = DashboardSummary.fromJson(
        DashboardJsonSanitizer.summary({
          'totalValue': 1000,
          'investmentValue': 800,
          'totalGainLoss': 200,
          'totalGainLossPercentage': 25,
          'dayChange': 10,
          'dayChangePercentage': 1,
          'totalPortfolios': 2,
        }),
      );
      expect(parsed.totalInvested, 800);
      expect(parsed.totalValue, 1000);
    });

    test('unwraps a data envelope', () {
      final parsed = DashboardSummary.fromJson(
        DashboardJsonSanitizer.summary({
          'userId': 'user-1',
          'data': {
            'totalValue': 50,
            'totalInvested': 40,
            'totalGainLoss': 10,
            'totalGainLossPercentage': 25,
            'dayChange': 1.5,
            'dayChangePercentage': 3,
            'totalPortfolios': 1,
          },
        }),
      );
      expect(parsed.totalValue, 50);
      expect(parsed.dayChange, 1.5);
    });

    test('accepts currentValue and todayGainLoss aliases', () {
      final parsed = DashboardSummary.fromJson(
        DashboardJsonSanitizer.summary({
          'currentValue': 933243.69,
          'investmentValue': 854184.61,
          'totalGainLoss': 79059.08,
          'todayGainLoss': -120.5,
          'todayGainLossPercentage': -0.01,
        }),
      );
      expect(parsed.totalValue, 933243.69);
      expect(parsed.totalInvested, 854184.61);
      expect(parsed.dayChange, -120.5);
      expect(parsed.totalPortfolios, 0);
    });

    test('accepts Map<dynamic, dynamic> payloads from jsonDecode', () {
      final raw = <dynamic, dynamic>{
        'totalValue': 10,
        'totalInvested': 8,
        'totalGainLoss': 2,
        'totalGainLossPercentage': 25,
        'dayChange': 1,
        'dayChangePercentage': 0.5,
        'totalPortfolios': 1,
      };
      final parsed = DashboardSummary.fromJson(DashboardJsonSanitizer.summary(raw));
      expect(parsed.totalValue, 10);
      expect(parsed.totalPortfolios, 1);
    });

    test('raw Freezed parse throws when numbers are null', () {
      expect(
        () => DashboardSummary.fromJson({
          'totalValue': null,
          'totalInvested': null,
          'totalGainLoss': null,
          'totalGainLossPercentage': null,
          'dayChange': null,
          'dayChangePercentage': null,
          'totalPortfolios': null,
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
