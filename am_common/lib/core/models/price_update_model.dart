import 'package:json_annotation/json_annotation.dart';

part 'price_update_model.g.dart';

@JsonSerializable()
class MarketDataUpdate {
  final int? timestamp;
  final Map<String, QuoteChange>? quotes;

  MarketDataUpdate({this.timestamp, this.quotes});

  factory MarketDataUpdate.fromJson(Map<String, dynamic> json) =>
      _$MarketDataUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$MarketDataUpdateToJson(this);
}

@JsonSerializable()
class QuoteChange {
  final double? lastPrice;
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final double? previousClose;
  final double? change;
  final double? changePercent;

  QuoteChange({
    this.lastPrice,
    this.open,
    this.high,
    this.low,
    this.close,
    this.previousClose,
    this.change,
    this.changePercent,
  });

  factory QuoteChange.fromJson(Map<String, dynamic> json) =>
      _$QuoteChangeFromJson(json);

  Map<String, dynamic> toJson() => _$QuoteChangeToJson(this);
}
