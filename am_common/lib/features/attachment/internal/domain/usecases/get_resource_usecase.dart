import '../entities/cloudinary_resource.dart';
import '../repositories/cloudinary_repository.dart';

/// Use case for retrieving resource information
class GetResourceUseCase {
  GetResourceUseCase(this._repository);

  final CloudinaryRepository _repository;

  Future<CloudinaryResource> call({required String publicId}) =>
      _repository.getResource(publicId: publicId);
}
