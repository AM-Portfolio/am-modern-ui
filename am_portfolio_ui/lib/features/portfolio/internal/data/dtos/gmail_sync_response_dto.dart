import 'package:json_annotation/json_annotation.dart';
import 'portfolio_holdings_dto.dart';

part 'gmail_sync_response_dto.g.dart';

/// DTO for Gmail sync response
@JsonSerializable()
class GmailSyncResponseDto {
  const GmailSyncResponseDto({
    required this.success,
    required this.broker,
    required this.count,
    this.dbId,
    this.holdings = const [],
  });

  factory GmailSyncResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GmailSyncResponseDtoFromJson(json);

  final bool success;
  final String broker;
  final int count;

  @JsonKey(name: 'db_id')
  final String? dbId;

  // Reuse existing EquityHoldingDto
  final List<EquityHoldingDto> holdings;

  Map<String, dynamic> toJson() => _$GmailSyncResponseDtoToJson(this);
}
