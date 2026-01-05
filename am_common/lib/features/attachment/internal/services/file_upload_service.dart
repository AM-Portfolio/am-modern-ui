/// Abstract service for file upload operations
///
/// This interface allows easy swapping of upload providers
/// (Cloudinary, AWS S3, Azure Blob, Firebase Storage, etc.)
abstract class FileUploadService {
  /// Upload a single file and return its public URL
  ///
  /// [filePath] - Local file path or XFile
  /// [folder] - Optional folder/category (e.g., 'journal-images')
  ///
  /// Returns the public URL of uploaded file
  /// Throws [FileUploadException] on failure
  Future<String> uploadFile(
    String filePath, {
    String? folder,
    Map<String, dynamic>? metadata,
  });

  /// Upload multiple files
  ///
  /// Returns list of public URLs in same order as input
  Future<List<String>> uploadMultipleFiles(
    List<String> filePaths, {
    String? folder,
    Map<String, dynamic>? metadata,
    void Function(int uploaded, int total)? onProgress,
  });

  /// Delete a file by its URL or public ID
  Future<bool> deleteFile(String fileUrl);

  /// Delete multiple files
  Future<bool> deleteMultipleFiles(List<String> fileUrls);

  /// Get optimized/transformed URL
  ///
  /// Useful for generating thumbnails, resizing, etc.
  String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String? format,
    int? quality,
  });
}

/// Exception thrown when file upload fails
class FileUploadException implements Exception {
  FileUploadException(this.message, {this.code, this.originalError});
  final String message;
  final String? code;
  final dynamic originalError;

  @override
  String toString() => 'FileUploadException: $message';
}
