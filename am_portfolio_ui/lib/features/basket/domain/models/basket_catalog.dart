class BasketCatalog {
  final String defaultQuery;
  final List<BasketTheme> themes;

  const BasketCatalog({
    required this.defaultQuery,
    this.themes = const [],
  });

  factory BasketCatalog.fromJson(Map<String, dynamic> json) {
    return BasketCatalog(
      defaultQuery: json['defaultQuery'] as String? ?? '',
      themes: (json['themes'] as List<dynamic>?)
              ?.map((e) => BasketTheme.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class BasketTheme {
  final String id;
  final String label;
  final String query;
  final bool featured;

  const BasketTheme({
    required this.id,
    required this.label,
    required this.query,
    this.featured = true,
  });

  factory BasketTheme.fromJson(Map<String, dynamic> json) {
    return BasketTheme(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      query: json['query'] as String? ?? '',
      featured: json['featured'] as bool? ?? true,
    );
  }
}
