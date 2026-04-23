import 'package:freezed_annotation/freezed_annotation.dart';

part 'performance_response.freezed.dart';
part 'performance_response.g.dart';

@freezed
abstract class PerformanceResponse with _$PerformanceResponse {
  const factory PerformanceResponse({
    required String portfolioId,
    required String timeFrame,
    required double totalReturnPercentage,
    required double totalReturnValue,
    @Default([]) List<DataPoint> chartData,
    String? errorMessage,
  }) = _PerformanceResponse;

  factory PerformanceResponse.fromJson(Map<String, dynamic> json) =>
      _$PerformanceResponseFromJson(json);
}

@freezed
abstract class DataPoint with _$DataPoint {
  const factory DataPoint({
    required String date, // LocalDate is usually serialized as String
    required double value,
  }) = _DataPoint;

  factory DataPoint.fromJson(Map<String, dynamic> json) =>
      _$DataPointFromJson(json);
}
