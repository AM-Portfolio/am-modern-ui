import '../entities/cloudinary_resource.dart';

/// Repository interface for Cloudinary operations
///
/// Defines contract for data access, implementation handles API communication
abstract class CloudinaryRepository {
  /// Upload a file
  Future<UploadResult> uploadFile({
    required String fileContent,
    required String filename,
    String? folder,
    bool overwrite = false,
    String resourceType = 'image',
  });

  /// Get resource details
  Future<CloudinaryResource> getResource({
    required String publicId,
    String resourceType = 'image',
  });

  /// List resources in folder
  Future<List<CloudinaryResource>> listResources({
    String? folder,
    String resourceType = 'image',
    int maxResults = 100,
    String? nextCursor,
  });

  /// Delete a resource
  Future<bool> deleteResource({
    required String publicId,
    String resourceType = 'image',
  });

  /// Delete a file (alias for deleteResource)
  Future<void> deleteFile({required String publicId}) =>
      deleteResource(publicId: publicId);

  /// Generate upload signature
  Future<SignatureDetails> generateSignature({
    String? publicId,
    String? folder,
    String resourceType = 'image',
    Map<String, dynamic>? params,
  });
}
