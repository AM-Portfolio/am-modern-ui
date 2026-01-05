import '../../domain/entities/cloudinary_resource.dart';
import '../../domain/repositories/cloudinary_repository.dart';
import '../datasources/cloudinary_remote_data_source.dart';
import '../mappers/cloudinary_mapper.dart';

/// Implementation of CloudinaryRepository
///
/// Coordinates between remote data source (API calls) and domain layer
/// Uses mappers to convert DTOs to domain entities
class CloudinaryRepositoryImpl implements CloudinaryRepository {
  CloudinaryRepositoryImpl({
    required CloudinaryRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;
  final CloudinaryRemoteDataSource _remoteDataSource;

  @override
  Future<UploadResult> uploadFile({
    required String fileContent,
    required String filename,
    String? folder,
    bool overwrite = false,
    String resourceType = 'image',
  }) async {
    try {
      final responseDto = await _remoteDataSource.uploadFile(
        fileContent: fileContent,
        filename: filename,
        folder: folder,
        overwrite: overwrite,
        resourceType: resourceType,
      );

      return CloudinaryMapper.fromUploadResponseDto(responseDto);
    } catch (e) {
      throw Exception('Repository upload failed: $e');
    }
  }

  @override
  Future<CloudinaryResource> getResource({
    required String publicId,
    String resourceType = 'image',
  }) async {
    try {
      final resourceDto = await _remoteDataSource.getResource(
        publicId: publicId,
        resourceType: resourceType,
      );

      return CloudinaryMapper.fromResourceDto(resourceDto);
    } catch (e) {
      throw Exception('Repository get resource failed: $e');
    }
  }

  @override
  Future<List<CloudinaryResource>> listResources({
    String? folder,
    String resourceType = 'image',
    int maxResults = 100,
    String? nextCursor,
  }) async {
    try {
      final resourceDtos = await _remoteDataSource.listResources(
        folder: folder,
        resourceType: resourceType,
        maxResults: maxResults,
      );

      return CloudinaryMapper.fromResourceDtoList(resourceDtos);
    } catch (e) {
      throw Exception('Repository list resources failed: $e');
    }
  }

  @override
  Future<void> deleteFile({required String publicId}) async {
    await deleteResource(publicId: publicId);
  }

  @override
  Future<bool> deleteResource({
    required String publicId,
    String resourceType = 'image',
  }) async {
    try {
      final deleteDto = await _remoteDataSource.deleteResource(
        publicId: publicId,
        resourceType: resourceType,
      );

      // Cloudinary returns 'ok' for successful deletion
      return deleteDto.result.toLowerCase() == 'ok';
    } catch (e) {
      throw Exception('Repository delete failed: $e');
    }
  }

  @override
  Future<SignatureDetails> generateSignature({
    String? publicId,
    String? folder,
    String resourceType = 'image',
    Map<String, dynamic>? params,
  }) async {
    try {
      final signatureDto = await _remoteDataSource.generateSignature(
        publicId: publicId,
        folder: folder,
        resourceType: resourceType,
        params: params,
      );

      return CloudinaryMapper.fromSignatureResponseDto(signatureDto);
    } catch (e) {
      throw Exception('Repository signature generation failed: $e');
    }
  }
}
