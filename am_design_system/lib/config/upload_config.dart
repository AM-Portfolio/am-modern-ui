/// Configuration for file upload across the application
class UploadConfig {
  // File size limits (in MB)
  static const int maxImageSizeMB = 10;
  static const int maxDocumentSizeMB = 50;
  static const int maxVideoSizeMB = 100;

  // Allowed file types
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];

  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'txt'];

  static const List<String> allowedVideoTypes = ['mp4', 'mov', 'avi', 'mkv', 'webm'];

  // Compression settings for images
  static const int imageMaxWidth = 1920;
  static const int imageMaxHeight = 1920;
  static const int imageQuality = 85;

  static const int thumbnailSize = 200;

  // Cloudinary folders (organization by feature)
  static const Map<String, String> folders = {
    'journal': 'journal-attachments',
    'portfolio': 'portfolio-documents',
    'trade': 'trade-screenshots',
    'documents': 'user-documents',
    'profile': 'profile-images',
    'reports': 'reports',
  };

  /// Get folder path for a specific feature
  static String getFolderForFeature(String feature) => folders[feature] ?? 'misc';

  /// Check if file extension is allowed for images
  static bool isImageExtension(String extension) => allowedImageTypes.contains(extension.toLowerCase());

  /// Check if file extension is allowed for documents
  static bool isDocumentExtension(String extension) => allowedDocumentTypes.contains(extension.toLowerCase());

  /// Check if file extension is allowed for videos
  static bool isVideoExtension(String extension) => allowedVideoTypes.contains(extension.toLowerCase());

  /// Get max file size in bytes for a specific type
  static int getMaxFileSizeBytes(String fileType) {
    if (isImageExtension(fileType)) {
      return maxImageSizeMB * 1024 * 1024;
    } else if (isDocumentExtension(fileType)) {
      return maxDocumentSizeMB * 1024 * 1024;
    } else if (isVideoExtension(fileType)) {
      return maxVideoSizeMB * 1024 * 1024;
    }
    return maxDocumentSizeMB * 1024 * 1024; // Default
  }
}
