import 'package:json_annotation/json_annotation.dart';

part 'gmail_status_dto.g.dart';

/// DTO for Gmail connection status response
@JsonSerializable()
class GmailStatusDto {
  const GmailStatusDto({
    required this.connected,
    this.email,
    this.name,
  });

  factory GmailStatusDto.fromJson(Map<String, dynamic> json) =>
      _$GmailStatusDtoFromJson(json);

  final bool connected;
  final String? email;
  final String? name;

  Map<String, dynamic> toJson() => _$GmailStatusDtoToJson(this);
}
