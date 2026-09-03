class AvailableIndices {
  final List<String> broadMarketIndices;
  final List<String> sectoralIndices;
  final List<String> thematicIndices;
  final List<String> strategyIndices;
  /// Symbols from GET /v1/indices/global/available (kept separate from NSE lists).
  final List<String> globalIndices;

  AvailableIndices({
    this.broadMarketIndices = const [],
    this.sectoralIndices = const [],
    this.thematicIndices = const [],
    this.strategyIndices = const [],
    this.globalIndices = const [],
  });

  factory AvailableIndices.fromJson(Map<String, dynamic> json) {
    return AvailableIndices(
      broadMarketIndices: List<String>.from(json['broad'] ?? json['broadMarketIndices'] ?? []),
      sectoralIndices: List<String>.from(json['sector'] ?? json['sectoralIndices'] ?? []),
      thematicIndices: List<String>.from(json['thematic'] ?? json['thematicIndices'] ?? []),
      strategyIndices: List<String>.from(json['strategy'] ?? json['strategyIndices'] ?? []),
      globalIndices: List<String>.from(json['global'] ?? json['globalIndices'] ?? []),
    );
  }

  AvailableIndices copyWith({
    List<String>? broadMarketIndices,
    List<String>? sectoralIndices,
    List<String>? thematicIndices,
    List<String>? strategyIndices,
    List<String>? globalIndices,
  }) {
    return AvailableIndices(
      broadMarketIndices: broadMarketIndices ?? this.broadMarketIndices,
      sectoralIndices: sectoralIndices ?? this.sectoralIndices,
      thematicIndices: thematicIndices ?? this.thematicIndices,
      strategyIndices: strategyIndices ?? this.strategyIndices,
      globalIndices: globalIndices ?? this.globalIndices,
    );
  }

  List<String> get indianSymbols => [
        ...broadMarketIndices,
        ...sectoralIndices,
        ...thematicIndices,
        ...strategyIndices,
      ];

  // Legacy compatibility getters
  List<String> get broad => broadMarketIndices;
  List<String> get sector => sectoralIndices;
  List<String> get sectoral => sectoralIndices;
}
