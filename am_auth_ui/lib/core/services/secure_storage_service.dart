// Re-export from am_library — SecureStorageService now lives in the shared library.
// All local imports continue to resolve to the single canonical type, eliminating
// the 'imported from both' conflict that the Dart compiler would otherwise raise.
export 'package:am_library/core/services/secure_storage_service.dart';
