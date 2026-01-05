import 'dart:convert';

import 'package:am_common/core/config/app_config.dart';
import 'package:http/http.dart' as http;

import '../../../../../../core/utils/logger.dart';
import '../dtos/cloudinary_dto.dart';

/// Remote data source for Cloudinary operations via backend API
///
/// Calls backend endpoints instead of Cloudinary directly, providing abstraction
/// Backend can switch cloud providers without impacting frontend
class CloudinaryRemoteDataSource {
  CloudinaryRemoteDataSource({
    required http.Client client,
    required ApiConfig apiConfig,
  }) : _client = client,
       _apiConfig = apiConfig;
  final http.Client _client;
  final ApiConfig _apiConfig;

  /// Upload file to Cloudinary via backend API
  ///
  /// POST /api/cloudinary/upload
  /// Body: { fileContent: base64, filename, folder?, overwrite?, resourceType? }
  /// Returns: UploadResponseDto
  Future<UploadResponseDto> uploadFile({
    required String fileContent,
    required String filename,
    String? folder,
    bool overwrite = false,
    String resourceType = 'image',
  }) async {
    AppLogger.debug('🌐 Uploading to backend API...', tag: 'CloudinaryAPI');
    AppLogger.debug(
      '🔗 URL: ${_apiConfig.baseUrl}/api/cloudinary/upload',
      tag: 'CloudinaryAPI',
    );
    AppLogger.debug('📝 Filename: $filename', tag: 'CloudinaryAPI');
    AppLogger.debug('📂 Folder: ${folder ?? "none"}', tag: 'CloudinaryAPI');
    AppLogger.debug('🏷️ Resource type: $resourceType', tag: 'CloudinaryAPI');
    AppLogger.debug(
      '📏 Content length: ${fileContent.length} chars',
      tag: 'CloudinaryAPI',
    );

    try {
      final requestBody = {
        'fileContent': fileContent,
        'filename': filename,
        if (folder != null) 'folder': folder,
        'overwrite': overwrite,
        'resourceType': resourceType,
      };

      AppLogger.debug('📤 Sending POST request...', tag: 'CloudinaryAPI');
      final response = await _client.post(
        Uri.parse('${_apiConfig.baseUrl}/cloudinary/api/v1/cloudinary/upload'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      AppLogger.debug(
        '📥 Response status: ${response.statusCode}',
        tag: 'CloudinaryAPI',
      );
      AppLogger.debug(
        '📄 Response body: ${response.body}',
        tag: 'CloudinaryAPI',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.debug(
          '✅ Upload successful, parsing response...',
          tag: 'CloudinaryAPI',
        );
        final jsonData = json.decode(response.body);
        final dto = UploadResponseDto.fromJson(jsonData);
        AppLogger.debug('🆔 Public ID: ${dto.publicId}', tag: 'CloudinaryAPI');
        AppLogger.debug('🔗 URL: ${dto.url}', tag: 'CloudinaryAPI');
        return dto;
      } else {
        AppLogger.error(
          '❌ Upload failed with status ${response.statusCode}',
          tag: 'CloudinaryAPI',
        );
        throw Exception(
          'Upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.error('❌ Exception during upload: $e', tag: 'CloudinaryAPI');
      AppLogger.debug('🔍 Error type: ${e.runtimeType}', tag: 'CloudinaryAPI');
      throw Exception('Upload error: $e');
    }
  }

  /// Get resource details by public ID
  ///
  /// GET /api/cloudinary/resources/:publicId
  /// Returns: CloudinaryResourceDto
  Future<CloudinaryResourceDto> getResource({
    required String publicId,
    String resourceType = 'image',
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${_apiConfig.baseUrl}/cloudinary/api/v1/cloudinary/resources/$publicId?resourceType=$resourceType',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CloudinaryResourceDto.fromJson(jsonData);
      } else {
        throw Exception(
          'Get resource failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Get resource error: $e');
    }
  }

  /// List resources in a folder
  ///
  /// GET /api/cloudinary/resources?folder=xxx&resourceType=xxx&maxResults=xxx
  /// Returns: List<CloudinaryResourceDto>
  Future<List<CloudinaryResourceDto>> listResources({
    String? folder,
    String resourceType = 'image',
    int maxResults = 100,
  }) async {
    try {
      final queryParams = {
        if (folder != null) 'folder': folder,
        'resourceType': resourceType,
        'maxResults': maxResults.toString(),
      };

      final uri = Uri.parse(
        '${_apiConfig.baseUrl}/cloudinary/api/v1/cloudinary/resources',
      ).replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> resources = jsonData['resources'] ?? [];
        return resources.map((r) => CloudinaryResourceDto.fromJson(r)).toList();
      } else {
        throw Exception(
          'List resources failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('List resources error: $e');
    }
  }

  /// Delete resource by public ID
  ///
  /// DELETE /api/cloudinary/resources/:publicId
  /// Returns: DeleteResponseDto
  Future<DeleteResponseDto> deleteResource({
    required String publicId,
    String resourceType = 'image',
  }) async {
    try {
      final response = await _client.delete(
        Uri.parse(
          '${_apiConfig.baseUrl}/cloudinary/api/v1/cloudinary/resources/$publicId?resourceType=$resourceType',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DeleteResponseDto.fromJson(jsonData);
      } else {
        throw Exception(
          'Delete failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Delete error: $e');
    }
  }

  /// Generate upload signature
  ///
  /// POST /api/cloudinary/signature
  /// Body: { publicId?, folder?, resourceType?, params? }
  /// Returns: SignatureResponseDto
  Future<SignatureResponseDto> generateSignature({
    String? publicId,
    String? folder,
    String resourceType = 'image',
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(
          '${_apiConfig.baseUrl}/cloudinary/api/v1/cloudinary/signature',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          if (publicId != null) 'publicId': publicId,
          if (folder != null) 'folder': folder,
          'resourceType': resourceType,
          if (params != null) 'params': params,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return SignatureResponseDto.fromJson(jsonData);
      } else {
        throw Exception(
          'Signature generation failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Signature generation error: $e');
    }
  }
}
