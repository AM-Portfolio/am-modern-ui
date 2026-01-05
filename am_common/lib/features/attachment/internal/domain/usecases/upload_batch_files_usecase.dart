import 'dart:convert';
import 'dart:io';

import '../entities/cloudinary_resource.dart';
import '../repositories/cloudinary_repository.dart';

/// Use case for uploading multiple files in batch
class UploadBatchFilesUseCase {
  UploadBatchFilesUseCase(this._repository);

  final CloudinaryRepository _repository;

  Future<List<UploadResult>> call({
    required List<String> filePaths,
    required String folder,
    Map<String, String>? metadata,
    Function(int current, int total)? onProgress,
  }) async {
    final results = <UploadResult>[];

    for (var i = 0; i < filePaths.length; i++) {
      onProgress?.call(i + 1, filePaths.length);

      // Read file content and encode to base64
      final file = File(filePaths[i]);
      final bytes = await file.readAsBytes();
      final base64Content = base64Encode(bytes);
      final filename = filePaths[i].split('/').last;

      final result = await _repository.uploadFile(
        fileContent: base64Content,
        filename: filename,
        folder: folder,
      );

      results.add(result);
    }

    return results;
  }
}
