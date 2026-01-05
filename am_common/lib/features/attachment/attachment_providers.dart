// Stubbed for Phase 1
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StubFileUploadService {
  Future<String> uploadFile(
    dynamic file, {
    String? folder,
    Map<String, dynamic>? metadata,
  }) async {
    return 'https://via.placeholder.com/150';
  }
  
  Future<void> deleteFile(String url) async {
    return;
  }
}

final fileUploadServiceProvider = FutureProvider<StubFileUploadService>((ref) async {
  return StubFileUploadService();
});

final attachmentProvider = Provider((ref) => null);
