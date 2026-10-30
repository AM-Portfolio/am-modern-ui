/// Configuration for file upload across the application
class UploadConfig {
  // File size limits (in MB)
  static const int maxImageSizeMB = 10;
  static const int maxDocumentSizeMB = 50;
  static const int maxVideoSizeMB = 100;

  // Allowed file types
  static const List<String> allowedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
  ];

  static const List<String> allowedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'csv',
    'txt',
  ];

  static const List<String> allowedVideoTypes = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
  ];

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
  static String getFolderForFeature(String feature) =>
      folders[feature] ?? 'misc';

  /// Check if file extension is allowed for images
  static bool isImageExtension(String extension) =>
      allowedImageTypes.contains(extension.toLowerCase());

  /// Check if file extension is allowed for documents
  static bool isDocumentExtension(String extension) =>
      allowedDocumentTypes.contains(extension.toLowerCase());

  /// Check if file extension is allowed for videos
  static bool isVideoExtension(String extension) =>
      allowedVideoTypes.contains(extension.toLowerCase());

  /// Path extension from a URL/path (ignores query). Empty when missing/invalid.
  static String extensionFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = (uri != null && uri.path.isNotEmpty) ? uri.path : url;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final last = segments.isNotEmpty ? segments.last : path;
    final dot = last.lastIndexOf('.');
    if (dot <= 0 || dot >= last.length - 1) return '';
    final ext = last.substring(dot + 1).toLowerCase();
    // Reject bogus "extensions" like "com/150" from host/path mishandling.
    if (ext.contains('/') || ext.length > 5) return '';
    return ext;
  }

  /// Stub / Phase-1 fake URLs that must never be shown as real attachments.
  static bool isStubOrPlaceholderUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('via.placeholder.com') ||
        lower.contains('placeholder.com/150') ||
        lower.contains('placehold.co') ||
        lower == 'https://via.placeholder.com/150';
  }

  /// True when we should try [Image.network] for this URL.
  /// Extension-less CDN / signed URLs still count as images unless clearly a doc/video.
  static bool looksLikeImageUrl(String url) {
    if (isStubOrPlaceholderUrl(url)) return false;
    final ext = extensionFromUrl(url);
    if (isImageExtension(ext)) return true;
    if (isDocumentExtension(ext) || isVideoExtension(ext)) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https' && uri.scheme != 'blob') {
      return false;
    }
    // No usable extension — journal uploads often store bare CDN paths.
    return ext.isEmpty;
  }

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
