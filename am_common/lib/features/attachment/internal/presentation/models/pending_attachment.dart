import 'dart:typed_data';

/// Represents an attachment that hasn't been uploaded yet
class PendingAttachment {
  PendingAttachment({
    required this.fileName,
    required this.filePath,
    this.fileBytes,
    this.previewUrl,
  });

  final String fileName;
  final String? filePath; // For mobile/desktop file picker
  final Uint8List? fileBytes; // For web drag-and-drop
  final String? previewUrl; // Local preview URL

  String get extension => fileName.split('.').last.toLowerCase();

  bool get isImage {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
    return imageExtensions.contains(extension);
  }

  bool get isVideo {
    const videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'];
    return videoExtensions.contains(extension);
  }

  bool get isDocument {
    const documentExtensions = [
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    ];
    return documentExtensions.contains(extension);
  }
}

/// Represents the state of an attachment (either pending or uploaded)
class AttachmentItem {
  AttachmentItem.pending(this.pendingAttachment)
    : uploadedUrl = null,
      isUploaded = false;

  AttachmentItem.uploaded(this.uploadedUrl)
    : pendingAttachment = null,
      isUploaded = true;

  final PendingAttachment? pendingAttachment;
  final String? uploadedUrl;
  final bool isUploaded;

  String get displayName {
    if (isUploaded) {
      return uploadedUrl!.split('/').last.split('?').first;
    } else {
      return pendingAttachment!.fileName;
    }
  }

  String? get previewUrl {
    if (isUploaded) return uploadedUrl;
    return pendingAttachment?.previewUrl;
  }
}
