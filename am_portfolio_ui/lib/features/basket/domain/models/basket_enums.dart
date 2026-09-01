enum BasketItemStatus {
  held,
  missing,
  substitute,
}

enum BasketStatus {
  active,
  pending,
  partially_filled,
  completed,
  failed,
  unknown;

  static BasketStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) return BasketStatus.unknown;
    final normalized = value.trim().toLowerCase();
    for (final s in BasketStatus.values) {
      if (s.name.toLowerCase() == normalized ||
          s.name.replaceAll('_', '').toLowerCase() == normalized.replaceAll('_', '')) {
        return s;
      }
    }
    return BasketStatus.unknown;
  }
}
