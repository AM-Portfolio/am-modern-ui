import 'package:freezed_annotation/freezed_annotation.dart';

part 'cloudinary_resource.freezed.dart';

/// Domain entity representing a Cloudinary resource
@freezed
abstract class CloudinaryResource with _$CloudinaryResource {
  const factory CloudinaryResource({
    required String publicId,
    required String url,
    required String secureUrl,
    String? format,
    int? bytes,
    int? width,
    int? height,
    String? resourceType,
    DateTime? createdAt,
    String? folder,
    Map<String, dynamic>? metadata,
  }) = _CloudinaryResource;
}

/// Domain entity for upload result
@freezed
abstract class UploadResult with _$UploadResult {
  const factory UploadResult({
    required String url,
    required String secureUrl,
    required String publicId,
    String? format,
    int? bytes,
  }) = _UploadResult;
}

/// Domain entity for signature details
@freezed
abstract class SignatureDetails with _$SignatureDetails {
  const factory SignatureDetails({
    required String signature,
    required int timestamp,
    required String apiKey,
    required String cloudName,
    required String uploadUrl,
    String? publicId,
    String? folder,
    Map<String, dynamic>? params,
  }) = _SignatureDetails;
}
