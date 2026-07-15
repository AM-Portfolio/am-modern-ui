import 'package:equatable/equatable.dart';

class PortfolioIntradayDto extends Equatable {
  final String timestamp;       // "09:15", "09:30"
  final double totalWealth;
  final double changeFromOpen;
  final double changeFromOpenPct;
  final bool isLive;

  const PortfolioIntradayDto({
    required this.timestamp,
    required this.totalWealth,
    required this.changeFromOpen,
    required this.changeFromOpenPct,
    this.isLive = false,
  });

  factory PortfolioIntradayDto.fromJson(Map<String, dynamic> json) =>
      PortfolioIntradayDto(
        timestamp:          json['timestamp']         as String,
        totalWealth:        (json['totalWealth']       as num).toDouble(),
        changeFromOpen:     (json['changeFromOpen']    as num).toDouble(),
        changeFromOpenPct:  (json['changeFromOpenPct'] as num).toDouble(),
        isLive:             json['isLive']             as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'totalWealth': totalWealth,
        'changeFromOpen': changeFromOpen,
        'changeFromOpenPct': changeFromOpenPct,
        'isLive': isLive,
      };

  @override
  List<Object?> get props => [
        timestamp,
        totalWealth,
        changeFromOpen,
        changeFromOpenPct,
        isLive,
      ];
}
