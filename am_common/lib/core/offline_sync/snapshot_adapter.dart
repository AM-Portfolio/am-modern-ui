import 'cached.dart';

abstract class SnapshotAdapter<T> {
  String get domainId;

  Future<void> put(T value, {required DateTime fetchedAt});

  Future<Cached<T>?> get();

  Future<int> approximateBytes();

  Future<void> clearUser(String userId);
}
