import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/core/config/upload_config.dart';
import 'package:am_common/features/attachment/internal/presentation/models/pending_attachment.dart';
import '../../domain/usecases/delete_file_usecase.dart';
import '../../domain/usecases/upload_batch_files_usecase.dart';
import '../../domain/usecases/upload_file_usecase.dart';
import 'attachment_state.dart';

/// Cubit for managing attachment upload state and operations
class AttachmentCubit extends Cubit<AttachmentState> {
  AttachmentCubit({
    required this.uploadFileUseCase,
    required this.uploadBatchFilesUseCase,
    required this.deleteFileUseCase,
  }) : super(const AttachmentState.initial());

  final UploadFileUseCase uploadFileUseCase;
  final UploadBatchFilesUseCase uploadBatchFilesUseCase;
  final DeleteFileUseCase deleteFileUseCase;

  final List<String> _uploadedUrls = [];
  final List<PendingAttachment> _pendingAttachments = [];

  List<String> get uploadedUrls => List.unmodifiable(_uploadedUrls);
  List<PendingAttachment> get pendingAttachments =>
      List.unmodifiable(_pendingAttachments);

  /// Add a pending attachment (not uploaded yet)
  void addPending(PendingAttachment attachment) {
    _pendingAttachments.add(attachment);
    emit(
      AttachmentState.uploaded(
        urls: _uploadedUrls,
        pending: _pendingAttachments,
      ),
    );
  }

  /// Add multiple pending attachments
  void addPendingBatch(List<PendingAttachment> attachments) {
    _pendingAttachments.addAll(attachments);
    emit(
      AttachmentState.uploaded(
        urls: _uploadedUrls,
        pending: _pendingAttachments,
      ),
    );
  }

  /// Remove a pending attachment
  void removePending(PendingAttachment attachment) {
    _pendingAttachments.remove(attachment);
    emit(
      AttachmentState.uploaded(
        urls: _uploadedUrls,
        pending: _pendingAttachments,
      ),
    );
  }

  /// Upload a single pending attachment
  Future<void> uploadSingleFile({
    required PendingAttachment attachment,
    required String featureName,
    String? userId,
  }) async {
    if (attachment.filePath == null && attachment.fileBytes == null) {
      emit(
        AttachmentState.error(
          message: 'No file data available',
          uploadedUrls: _uploadedUrls,
          pending: _pendingAttachments,
        ),
      );
      return;
    }

    emit(const AttachmentState.loading());

    try {
      final folder = UploadConfig.getFolderForFeature(featureName);
      final metadata = {
        'feature': featureName,
        'uploadedAt': DateTime.now().toIso8601String(),
        if (userId != null) 'userId': userId,
      };

      final result = await uploadFileUseCase(
        filePath: attachment.filePath ?? attachment.fileName,
        folder: '$folder/${DateTime.now().year}',
        metadata: metadata,
      );

      _uploadedUrls.add(result.secureUrl);
      _pendingAttachments.remove(attachment);

      emit(
        AttachmentState.uploaded(
          urls: _uploadedUrls,
          pending: _pendingAttachments,
        ),
      );
    } catch (e) {
      emit(
        AttachmentState.error(
          message: 'Upload failed: ${e.toString()}',
          uploadedUrls: _uploadedUrls,
          pending: _pendingAttachments,
        ),
      );
    }
  }

  /// Upload all pending attachments in batch
  Future<void> uploadPendingFiles({
    required String featureName,
    String? userId,
  }) async {
    if (_pendingAttachments.isEmpty) return;

    final filePaths = _pendingAttachments
        .where((a) => a.filePath != null)
        .map((a) => a.filePath!)
        .toList();

    if (filePaths.isEmpty) {
      emit(
        AttachmentState.error(
          message: 'No valid file paths to upload',
          uploadedUrls: _uploadedUrls,
          pending: _pendingAttachments,
        ),
      );
      return;
    }

    try {
      final folder = UploadConfig.getFolderForFeature(featureName);
      final metadata = {
        'feature': featureName,
        'uploadedAt': DateTime.now().toIso8601String(),
        if (userId != null) 'userId': userId,
      };

      final results = await uploadBatchFilesUseCase(
        filePaths: filePaths,
        folder: '$folder/${DateTime.now().year}',
        metadata: metadata,
        onProgress: (current, total) {
          emit(
            AttachmentState.uploading(
              currentFile: current,
              totalFiles: total,
              progress: current / total,
            ),
          );
        },
      );

      // Add all uploaded URLs
      _uploadedUrls.addAll(results.map((r) => r.secureUrl));
      _pendingAttachments.clear();

      emit(
        AttachmentState.uploaded(
          urls: _uploadedUrls,
          pending: _pendingAttachments,
        ),
      );
    } catch (e) {
      emit(
        AttachmentState.error(
          message: 'Batch upload failed: ${e.toString()}',
          uploadedUrls: _uploadedUrls,
          pending: _pendingAttachments,
        ),
      );
    }
  }

  /// Delete an uploaded file
  Future<void> deleteFile(String url) async {
    emit(const AttachmentState.loading());

    try {
      // Extract public ID from URL
      final publicId = _extractPublicId(url);
      await deleteFileUseCase(publicId: publicId);

      _uploadedUrls.remove(url);

      emit(
        AttachmentState.uploaded(
          urls: _uploadedUrls,
          pending: _pendingAttachments,
        ),
      );
    } catch (e) {
      emit(
        AttachmentState.error(
          message: 'Delete failed: ${e.toString()}',
          uploadedUrls: _uploadedUrls,
          pending: _pendingAttachments,
        ),
      );
    }
  }

  /// Initialize with existing URLs
  void initializeWithUrls(List<String> urls) {
    _uploadedUrls.clear();
    _uploadedUrls.addAll(urls);
    _pendingAttachments.clear();

    emit(
      AttachmentState.uploaded(
        urls: _uploadedUrls,
        pending: _pendingAttachments,
      ),
    );
  }

  /// Reset state
  void reset() {
    _uploadedUrls.clear();
    _pendingAttachments.clear();
    emit(const AttachmentState.initial());
  }

  /// Extract public ID from Cloudinary URL
  String _extractPublicId(String url) {
    // Example: https://res.cloudinary.com/demo/image/upload/v1234567890/folder/filename.jpg
    // Public ID: folder/filename
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;

    // Find the index after 'upload'
    final uploadIndex = segments.indexOf('upload');
    if (uploadIndex == -1 || uploadIndex >= segments.length - 1) {
      return url.split('/').last.split('.').first;
    }

    // Skip version number if present (starts with 'v' followed by digits)
    var startIndex = uploadIndex + 1;
    if (segments[startIndex].startsWith('v') &&
        segments[startIndex].length > 1 &&
        int.tryParse(segments[startIndex].substring(1)) != null) {
      startIndex++;
    }

    // Join remaining segments and remove extension
    final pathWithExtension = segments.sublist(startIndex).join('/');
    return pathWithExtension.split('.').first;
  }
}
