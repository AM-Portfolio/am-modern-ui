import 'package:am_library/am_library.dart';

import '../../services/file_upload_service.dart';
import '../dtos/cloudinary_dto.dart';

/// Remote data source for Cloudinary operations via backend API.
///
/// Uses authenticated [ApiClient] against the cloudinary-manager base URL
/// (typically `https://{host}/cloudinary`).
class CloudinaryRemoteDataSource {
  CloudinaryRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const _uploadTimeout = Duration(seconds: 90);

  /// POST /v1/cloudinary/upload
  Future<UploadResponseDto> uploadFile({
    required String fileContent,
    required String filename,
    String? folder,
    bool overwrite = false,
    String resourceType = 'image',
  }) async {
    AppLogger.debug('🌐 Uploading via cloudinary API...', tag: 'CloudinaryAPI');
    AppLogger.debug('📝 Filename: $filename', tag: 'CloudinaryAPI');
    AppLogger.debug('📂 Folder: ${folder ?? "none"}', tag: 'CloudinaryAPI');

    // Backend Base64 decoder expects raw base64 (no data: prefix).
    final rawBase64 = _stripDataUri(fileContent);

    return _apiClient.post<UploadResponseDto>(
      'v1/cloudinary/upload',
      body: {
        'fileContent': rawBase64,
        'filename': filename,
        if (folder != null) 'folder': folder,
        'overwrite': overwrite,
        'resourceType': resourceType,
      },
      timeout: _uploadTimeout,
      parser: (data) {
        if (data is! Map) {
          throw FileUploadException(
            'Unexpected upload response',
            code: 'BAD_RESPONSE',
          );
        }
        return UploadResponseDto.fromJson(Map<String, dynamic>.from(data));
      },
    );
  }

  /// GET /v1/cloudinary/resources/{publicId}
  Future<CloudinaryResourceDto> getResource({
    required String publicId,
    String resourceType = 'image',
  }) async {
    final encoded = Uri.encodeComponent(publicId);
    return _apiClient.get<CloudinaryResourceDto>(
      'v1/cloudinary/resources/$encoded',
      queryParams: {'resourceType': resourceType},
      parser: (data) {
        if (data is! Map) {
          throw Exception('Unexpected get-resource response');
        }
        return CloudinaryResourceDto.fromJson(Map<String, dynamic>.from(data));
      },
    );
  }

  /// GET /v1/cloudinary/resources
  Future<List<CloudinaryResourceDto>> listResources({
    String? folder,
    String resourceType = 'image',
    int maxResults = 100,
  }) async {
    return _apiClient.get<List<CloudinaryResourceDto>>(
      'v1/cloudinary/resources',
      queryParams: {
        if (folder != null) 'folder': folder,
        'resourceType': resourceType,
        'maxResults': '$maxResults',
      },
      parser: (data) {
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => CloudinaryResourceDto.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList();
        }
        if (data is Map) {
          final resources = data['resources'];
          if (resources is List) {
            return resources
                .whereType<Map>()
                .map((e) => CloudinaryResourceDto.fromJson(
                      Map<String, dynamic>.from(e),
                    ))
                .toList();
          }
        }
        return const <CloudinaryResourceDto>[];
      },
    );
  }

  /// DELETE /v1/cloudinary/resources/{publicId}
  Future<DeleteResponseDto> deleteResource({
    required String publicId,
    String resourceType = 'image',
  }) async {
    final encoded = Uri.encodeComponent(publicId);
    return _apiClient.delete<DeleteResponseDto>(
      'v1/cloudinary/resources/$encoded',
      queryParams: {'resourceType': resourceType},
      parser: (data) {
        if (data is! Map) {
          return const DeleteResponseDto(result: 'ok');
        }
        return DeleteResponseDto.fromJson(Map<String, dynamic>.from(data));
      },
    );
  }

  /// POST /v1/cloudinary/signature
  Future<SignatureResponseDto> generateSignature({
    String? publicId,
    String? folder,
    String resourceType = 'image',
    Map<String, dynamic>? params,
  }) async {
    return _apiClient.post<SignatureResponseDto>(
      'v1/cloudinary/signature',
      body: {
        if (publicId != null) 'publicId': publicId,
        if (folder != null) 'folder': folder,
        'resourceType': resourceType,
        if (params != null) 'params': params,
      },
      parser: (data) {
        if (data is! Map) {
          throw Exception('Unexpected signature response');
        }
        return SignatureResponseDto.fromJson(Map<String, dynamic>.from(data));
      },
    );
  }

  static String _stripDataUri(String content) {
    final idx = content.indexOf('base64,');
    if (idx >= 0) return content.substring(idx + 'base64,'.length);
    return content;
  }
}
