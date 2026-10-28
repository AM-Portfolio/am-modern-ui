import 'package:am_common/core/di/network_providers.dart';
import 'package:am_library/am_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'internal/data/datasources/cloudinary_remote_data_source.dart';
import 'internal/data/repositories/cloudinary_repository_impl.dart';
import 'internal/services/cloudinary_upload_service.dart';
import 'internal/services/file_upload_service.dart';

/// Authenticated API client scoped to the cloudinary-manager gateway path.
final cloudinaryApiClientProvider = FutureProvider<ApiClient>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  final cloudinary = config.api.cloudinary;
  if (cloudinary == null ||
      !cloudinary.enabled ||
      cloudinary.baseUrl.trim().isEmpty) {
    throw FileUploadException(
      'Cloudinary upload is not configured for this environment.',
      code: 'CLOUDINARY_DISABLED',
    );
  }
  return ApiClient(baseUrl: cloudinary.baseUrl, category: 'cloudinary');
});

/// Real [FileUploadService] (Cloudinary via backend). Never returns stub URLs.
final fileUploadServiceProvider = FutureProvider<FileUploadService>((ref) async {
  final client = await ref.watch(cloudinaryApiClientProvider.future);
  final remote = CloudinaryRemoteDataSource(apiClient: client);
  final repository = CloudinaryRepositoryImpl(remoteDataSource: remote);
  return CloudinaryUploadService(repository: repository);
});

final attachmentProvider = Provider((ref) => null);
