import '../repositories/cloudinary_repository.dart';

/// Use case for deleting a file from cloud storage
class DeleteFileUseCase {
  DeleteFileUseCase(this._repository);

  final CloudinaryRepository _repository;

  Future<void> call({required String publicId}) =>
      _repository.deleteFile(publicId: publicId);
}
