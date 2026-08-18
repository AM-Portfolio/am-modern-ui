
enum BasketItemStatus {
  held,
  missing,
  substitute,
}

enum BasketStatus {
  pending,
  partially_filled,
  completed,
  failed,
  unknown;

  static BasketStatus fromString(String? value) {
    if (value == null) return BasketStatus.unknown;
    return BasketStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => BasketStatus.unknown,
    );
  }
}
