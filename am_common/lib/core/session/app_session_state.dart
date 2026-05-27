/// Client-side UI session (navigation + workspace). Not API data.
class AppSessionState {
  static const int currentVersion = 1;
  static const Duration maxAge = Duration(days: 7);

  final int version;
  final DateTime savedAt;
  final String globalNav;
  final String? portfolioId;
  final String? portfolioName;
  final int portfolioTabIndex;
  final BasketSessionState? basket;

  const AppSessionState({
    this.version = currentVersion,
    required this.savedAt,
    this.globalNav = 'Dashboard',
    this.portfolioId,
    this.portfolioName,
    this.portfolioTabIndex = 0,
    this.basket,
  });

  bool get isExpired => DateTime.now().difference(savedAt) > maxAge;

  AppSessionState copyWith({
    DateTime? savedAt,
    String? globalNav,
    String? portfolioId,
    String? portfolioName,
    int? portfolioTabIndex,
    BasketSessionState? basket,
    bool clearBasket = false,
    bool clearPortfolio = false,
  }) {
    return AppSessionState(
      version: version,
      savedAt: savedAt ?? this.savedAt,
      globalNav: globalNav ?? this.globalNav,
      portfolioId: clearPortfolio ? null : (portfolioId ?? this.portfolioId),
      portfolioName:
          clearPortfolio ? null : (portfolioName ?? this.portfolioName),
      portfolioTabIndex: portfolioTabIndex ?? this.portfolioTabIndex,
      basket: clearBasket ? null : (basket ?? this.basket),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'savedAt': savedAt.toIso8601String(),
        'globalNav': globalNav,
        if (portfolioId != null) 'portfolioId': portfolioId,
        if (portfolioName != null) 'portfolioName': portfolioName,
        'portfolioTabIndex': portfolioTabIndex,
        if (basket != null) 'basket': basket!.toJson(),
      };

  factory AppSessionState.fromJson(Map<String, dynamic> json) {
    return AppSessionState(
      version: json['version'] as int? ?? 1,
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      globalNav: json['globalNav'] as String? ?? 'Dashboard',
      portfolioId: json['portfolioId'] as String?,
      portfolioName: json['portfolioName'] as String?,
      portfolioTabIndex: json['portfolioTabIndex'] as int? ?? 0,
      basket: json['basket'] != null
          ? BasketSessionState.fromJson(
              json['basket'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  static AppSessionState initial({String globalNav = 'Dashboard'}) {
    return AppSessionState(
      savedAt: DateTime.now(),
      globalNav: globalNav,
    );
  }
}

class BasketSessionState {
  final String route;
  final String? etfIsin;
  final String? userId;
  final String? portfolioId;

  const BasketSessionState({
    required this.route,
    this.etfIsin,
    this.userId,
    this.portfolioId,
  });

  Map<String, dynamic> toJson() => {
        'route': route,
        if (etfIsin != null) 'etfIsin': etfIsin,
        if (userId != null) 'userId': userId,
        if (portfolioId != null) 'portfolioId': portfolioId,
      };

  factory BasketSessionState.fromJson(Map<String, dynamic> json) {
    return BasketSessionState(
      route: json['route'] as String? ?? '/',
      etfIsin: json['etfIsin'] as String?,
      userId: json['userId'] as String?,
      portfolioId: json['portfolioId'] as String?,
    );
  }
}
