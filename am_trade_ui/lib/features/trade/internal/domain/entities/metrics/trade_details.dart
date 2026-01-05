class TradeDetails {
  final String? tradeId;
  final String? symbol;
  final String? strategy;
  final String? status;
  final String? tradePositionType;
  final String? notes;
  final List<String>? tags;

  TradeDetails({
    this.tradeId,
    this.symbol,
    this.strategy,
    this.status,
    this.tradePositionType,
    this.notes,
    this.tags,
  });
}
