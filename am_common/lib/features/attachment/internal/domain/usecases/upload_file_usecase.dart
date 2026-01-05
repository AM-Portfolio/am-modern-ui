import 'dart:convert';
import 'dart:io';

import '../entities/cloudinary_resource.dart';
import '../repositories/cloudinary_repository.dart';

/// Use case for uploading a single file to cloud storage
class UploadFileUseCase {
  UploadFileUseCase(this._repository);

  final CloudinaryRepository _repository;

  Future<UploadResult> call({
    required String filePath,
    required String folder,
    Map<String, String>? metadata,
  }) async {
    // Read file content and encode to base64
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final base64Content = base64Encode(bytes);
    final filename = filePath.split('/').last;

    return _repository.uploadFile(
      fileContent: base64Content,
      filename: filename,
      folder: folder,
    );
  }
}
