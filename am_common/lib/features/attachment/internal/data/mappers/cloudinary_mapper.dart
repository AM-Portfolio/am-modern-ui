import '../../domain/entities/cloudinary_resource.dart';
import '../dtos/cloudinary_dto.dart';

/// Mapper for converting between Cloudinary DTOs and domain entities
class CloudinaryMapper {
  /// Map upload response DTO to UploadResult entity
  static UploadResult fromUploadResponseDto(UploadResponseDto dto) =>
      UploadResult(
        url: dto.url,
        secureUrl: dto.secureUrl,
        publicId: dto.publicId,
        format: dto.format,
        bytes: dto.bytes,
      );

  /// Map resource DTO to CloudinaryResource entity
  static CloudinaryResource fromResourceDto(CloudinaryResourceDto dto) =>
      CloudinaryResource(
        publicId: dto.publicId,
        url: dto.url,
        secureUrl: dto.secureUrl,
        format: dto.format,
        bytes: dto.bytes,
        width: dto.width,
        height: dto.height,
        resourceType: dto.resourceType,
        createdAt: dto.createdAt != null
            ? DateTime.parse(dto.createdAt!)
            : null,
        folder: dto.folder,
        metadata: dto.metadata,
      );

  /// Map list of resource DTOs to CloudinaryResource entities
  static List<CloudinaryResource> fromResourceDtoList(
    List<CloudinaryResourceDto> dtos,
  ) => dtos.map(fromResourceDto).toList();

  /// Map signature response DTO to SignatureDetails entity
  static SignatureDetails fromSignatureResponseDto(SignatureResponseDto dto) =>
      SignatureDetails(
        signature: dto.signature,
        timestamp: dto.timestamp,
        apiKey: dto.apiKey,
        cloudName: dto.cloudName,
        uploadUrl: dto.uploadUrl,
        publicId: dto.publicId,
        folder: dto.folder,
        params: dto.params,
      );

  /// Map upload request to DTO
  static UploadRequestDto toUploadRequestDto({
    required String fileContent,
    required String filename,
    String? folder,
    bool overwrite = false,
    String resourceType = 'auto',
  }) => UploadRequestDto(
    fileContent: fileContent,
    filename: filename,
    folder: folder,
    overwrite: overwrite,
    resourceType: resourceType,
  );

  /// Map signature request to DTO
  static SignatureRequestDto toSignatureRequestDto({
    String? publicId,
    String? folder,
    String resourceType = 'auto',
    int? timestamp,
    Map<String, dynamic>? params,
  }) => SignatureRequestDto(
    publicId: publicId,
    folder: folder,
    resourceType: resourceType,
    timestamp: timestamp,
    params: params,
  );
}
