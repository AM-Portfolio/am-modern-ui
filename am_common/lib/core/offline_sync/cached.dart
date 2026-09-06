class Cached<T> {
  const Cached({
    required this.value,
    required this.fetchedAt,
  });

  final T value;
  final DateTime fetchedAt;

  bool get isStale => true;

  Duration get age => DateTime.now().difference(fetchedAt);
}
