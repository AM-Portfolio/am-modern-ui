import 'package:freezed_annotation/freezed_annotation.dart';

part 'cloudinary_dto.freezed.dart';
part 'cloudinary_dto.g.dart';

/// DTO for upload request to backend API
@freezed
abstract class UploadRequestDto with _$UploadRequestDto {
  const factory UploadRequestDto({
    required String fileContent,
    required String filename,
    String? folder,
    @Default(false) bool overwrite,
    @Default('auto') String resourceType,
  }) = _UploadRequestDto;

  factory UploadRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UploadRequestDtoFromJson(json);
}

/// DTO for upload response from backend API
@freezed
abstract class UploadResponseDto with _$UploadResponseDto {
  const factory UploadResponseDto({
    required String publicId,
    required String url,
    required String secureUrl,
    String? originalFilename,
    String? format,
    int? bytes,
    String? resourceType,
    String? createdAt,
    Map<String, dynamic>? metadata,
  }) = _UploadResponseDto;

  factory UploadResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UploadResponseDtoFromJson(json);
}

/// DTO for signature request
@freezed
abstract class SignatureRequestDto with _$SignatureRequestDto {
  const factory SignatureRequestDto({
    String? publicId,
    String? folder,
    @Default('auto') String resourceType,
    int? timestamp,
    Map<String, dynamic>? params,
  }) = _SignatureRequestDto;

  factory SignatureRequestDto.fromJson(Map<String, dynamic> json) =>
      _$SignatureRequestDtoFromJson(json);
}

/// DTO for signature response
@freezed
abstract class SignatureResponseDto with _$SignatureResponseDto {
  const factory SignatureResponseDto({
    required String apiKey,
    required int timestamp,
    required String signature,
    required String cloudName,
    required String uploadUrl,
    String? publicId,
    String? folder,
    String? resourceType,
    Map<String, dynamic>? params,
  }) = _SignatureResponseDto;

  factory SignatureResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SignatureResponseDtoFromJson(json);
}

/// DTO for Cloudinary resource details
@freezed
abstract class CloudinaryResourceDto with _$CloudinaryResourceDto {
  const factory CloudinaryResourceDto({
    required String publicId,
    required String url,
    required String secureUrl,
    String? format,
    int? bytes,
    int? width,
    int? height,
    String? resourceType,
    String? createdAt,
    String? folder,
    Map<String, dynamic>? metadata,
  }) = _CloudinaryResourceDto;

  factory CloudinaryResourceDto.fromJson(Map<String, dynamic> json) =>
      _$CloudinaryResourceDtoFromJson(json);
}

/// DTO for delete response
@freezed
abstract class DeleteResponseDto with _$DeleteResponseDto {
  const factory DeleteResponseDto({required String result, String? publicId}) =
      _DeleteResponseDto;

  factory DeleteResponseDto.fromJson(Map<String, dynamic> json) =>
      _$DeleteResponseDtoFromJson(json);
}
