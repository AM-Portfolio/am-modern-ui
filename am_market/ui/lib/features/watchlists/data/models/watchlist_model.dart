class Watchlist {
  final String id;
  final String userId;
  final String name;
  final bool isDefault;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<WatchlistItem> items;

  const Watchlist({
    required this.id,
    required this.userId,
    required this.name,
    required this.isDefault,
    required this.displayOrder,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => WatchlistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Watchlist copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isDefault,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<WatchlistItem>? items,
  }) {
    return Watchlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'isDefault': isDefault,
        'displayOrder': displayOrder,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class WatchlistItem {
  final String id;
  final String watchlistId;
  final String userId;
  final String symbol;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WatchlistItem({
    required this.id,
    required this.watchlistId,
    required this.userId,
    required this.symbol,
    required this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as String? ?? '',
      watchlistId: json['watchlistId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      displayOrder: json['displayOrder'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'watchlistId': watchlistId,
        'userId': userId,
        'symbol': symbol,
        'displayOrder': displayOrder,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class WatchlistCheckStatus {
  final String watchlistId;
  final String name;
  final bool containsSymbol;
  final int itemCount;

  const WatchlistCheckStatus({
    required this.watchlistId,
    required this.name,
    required this.containsSymbol,
    required this.itemCount,
  });

  factory WatchlistCheckStatus.fromJson(Map<String, dynamic> json) {
    return WatchlistCheckStatus(
      watchlistId: json['watchlistId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      containsSymbol: json['containsSymbol'] as bool? ?? false,
      itemCount: json['itemCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'watchlistId': watchlistId,
        'name': name,
        'containsSymbol': containsSymbol,
        'itemCount': itemCount,
      };
}

class WatchlistStockQuote {
  final String symbol;
  final String companyName;
  final double lastPrice;
  final double change;
  final double changePercent;

  const WatchlistStockQuote({
    required this.symbol,
    required this.companyName,
    this.lastPrice = 0.0,
    this.change = 0.0,
    this.changePercent = 0.0,
  });

  WatchlistStockQuote copyWith({
    String? symbol,
    String? companyName,
    double? lastPrice,
    double? change,
    double? changePercent,
  }) {
    return WatchlistStockQuote(
      symbol: symbol ?? this.symbol,
      companyName: companyName ?? this.companyName,
      lastPrice: lastPrice ?? this.lastPrice,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
    );
  }
}

