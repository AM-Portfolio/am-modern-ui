import '../entities/cloudinary_resource.dart';
import '../repositories/cloudinary_repository.dart';

/// Use case for listing resources with optional filtering
class ListResourcesUseCase {
  ListResourcesUseCase(this._repository);

  final CloudinaryRepository _repository;

  Future<List<CloudinaryResource>> call({
    String? folder,
    int? limit,
    String? nextCursor,
  }) => _repository.listResources(
    folder: folder,
    maxResults: limit ?? 100,
    nextCursor: nextCursor,
  );
}
