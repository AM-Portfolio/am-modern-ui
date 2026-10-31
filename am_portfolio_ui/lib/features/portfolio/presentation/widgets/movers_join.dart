import 'package:am_design_system/am_design_system.dart';

import '../../internal/domain/entities/portfolio_analytics.dart';
import '../../internal/domain/entities/portfolio_holding.dart';

/// Uppercase ticker; strip `NSE_EQ:` / `NSE_EQ|` (Dhan pipe) prefixes.
String normalizeMoverSymbol(String raw) {
  var s = raw.trim().toUpperCase();
  final colon = s.lastIndexOf(':');
  final pipe = s.lastIndexOf('|');
  final cut = colon > pipe ? colon : pipe;
  if (cut >= 0 && cut < s.length - 1) {
    s = s.substring(cut + 1);
  }
  return s;
}

bool moversHaveCostBasis(Movers movers) =>
    movers.topGainers.any((s) => s.hasCostBasis) ||
    movers.topLosers.any((s) => s.hasCostBasis);

/// Rank holdings by today's ₹ impact on the portfolio (not market % alone).
Movers buildPortfolioMovers(
  List<PortfolioHolding> holdings, {
  int limit = 10,
  String? sessionDate,
  String? priceFreshness,
}) {
  final stocks = holdings
      .where((h) => h.quantity > 0)
      .map(stockFromHolding)
      .toList();
  final gainers = stocks.where((s) => _portfolioDayImpact(s) > 0).toList()
    ..sort((a, b) => _portfolioDayImpact(b).compareTo(_portfolioDayImpact(a)));
  final losers = stocks.where((s) => _portfolioDayImpact(s) < 0).toList()
    ..sort((a, b) => _portfolioDayImpact(a).compareTo(_portfolioDayImpact(b)));
  return Movers(
    topGainers: gainers.take(limit).toList(),
    topLosers: losers.take(limit).toList(),
    sessionDate: sessionDate,
    priceFreshness: priceFreshness,
  );
}

double _portfolioDayImpact(Stock s) =>
    moverDayValueChange(s) ?? (s.quantity ?? 0) * s.changeAmount;

/// Enrich API mover rows with holding qty/value and re-rank by day ₹ impact.
Movers enrichMovers(Movers movers, List<PortfolioHolding> holdings) {
  final bySymbol = <String, PortfolioHolding>{};
  for (final h in holdings) {
    bySymbol[normalizeMoverSymbol(h.symbol)] = h;
  }
  final gainers = movers.topGainers
      .map((s) => enrichMoverStock(s, bySymbol))
      .toList()
    ..sort((a, b) => _portfolioDayImpact(b).compareTo(_portfolioDayImpact(a)));
  final losers = movers.topLosers
      .map((s) => enrichMoverStock(s, bySymbol))
      .toList()
    ..sort((a, b) => _portfolioDayImpact(a).compareTo(_portfolioDayImpact(b)));
  return Movers(
    topGainers: gainers,
    topLosers: losers,
    sessionDate: movers.sessionDate,
    priceFreshness: movers.priceFreshness,
  );
}

Stock stockFromHolding(PortfolioHolding h) {
  final dayPerShare = h.quantity > 0 ? h.todayChange / h.quantity : 0.0;
  final invested = h.investedAmount > 0 ? h.investedAmount : null;
  final avg = h.avgPrice > 0
      ? h.avgPrice
      : (invested != null && h.quantity > 0 ? invested / h.quantity : null);
  final value = h.currentValue > 0
      ? h.currentValue
      : (h.currentPrice > 0 && h.quantity > 0
          ? h.currentPrice * h.quantity
          : null);
  final pnl = (value != null && invested != null) ? value - invested : null;
  return Stock(
    symbol: h.symbol,
    companyName: h.companyName.trim().isNotEmpty ? h.companyName : h.name,
    lastPrice: h.currentPrice,
    changeAmount: dayPerShare != 0
        ? dayPerShare
        : (h.currentPrice * h.todayChangePercentage / 100),
    changePercent: h.todayChangePercentage,
    sector: h.sector,
    quantity: h.quantity,
    avgPrice: avg,
    investedAmount: invested,
    marketValue: value,
    totalReturn: pnl ?? (h.hasCostBasis ? h.totalGainLoss : null),
    weight: h.portfolioWeight > 0 ? h.portfolioWeight : null,
  );
}

Stock enrichMoverStock(Stock mover, Map<String, PortfolioHolding> bySymbol) {
  final holding = bySymbol[normalizeMoverSymbol(mover.symbol)];
  final qty = (holding != null && holding.quantity > 0)
      ? holding.quantity
      : null;
  final invested = (holding != null && holding.investedAmount > 0)
      ? holding.investedAmount
      : null;
  final avg = (holding != null && holding.avgPrice > 0)
      ? holding.avgPrice
      : (invested != null && qty != null && qty > 0 ? invested / qty : null);

  final ltp = mover.lastPrice > 0
      ? mover.lastPrice
      : (holding != null && holding.currentPrice > 0
          ? holding.currentPrice
          : 0.0);

  double? value;
  if (qty != null && ltp > 0) {
    value = qty * ltp;
  } else if (holding != null &&
      holding.currentPrice > 0 &&
      holding.currentValue > 0) {
    value = holding.currentValue;
  }

  double? pnl;
  if (value != null && invested != null) {
    pnl = value - invested;
  }

  final sector = _usableLabel(mover.sector) ??
      (holding != null ? _usableLabel(holding.sector) : null) ??
      '';
  final company = _companyName(mover, holding);

  return Stock(
    symbol: mover.symbol,
    companyName: company,
    lastPrice: ltp,
    changeAmount: mover.changeAmount,
    changePercent: mover.changePercent,
    sector: sector,
    quantity: qty,
    avgPrice: avg,
    investedAmount: invested,
    marketValue: value,
    totalReturn: pnl,
    weight: mover.weight,
    previousClose: mover.previousClose,
  );
}

/// Today's position move in ₹ (`qty × day change`). Null when qty missing.
/// Prefer this over [moverDisplayPnl] for Top Movers day-value rows (avoids
/// mixing in cost-basis total return).
double? moverDayValueChange(Stock stock) {
  final qty = stock.quantity;
  if (qty == null || qty <= 0) return null;
  return qty * stock.changeAmount;
}

/// Cost-basis unrealized P&L when present; otherwise today's position move
/// (`qty × day change`). Does not invent invested/avg.
double? moverDisplayPnl(Stock stock) {
  if (stock.hasCostBasis) return stock.totalReturn;
  return moverDayValueChange(stock);
}

/// Lifetime unrealized return % on cost (not used for Top Movers % column).
double? moverDisplayPnlPercent(Stock stock) {
  if (stock.hasCostBasis) {
    final pnl = stock.totalReturn;
    final invested = stock.investedAmount;
    if (pnl == null || invested == null || invested <= 0) return null;
    return (pnl / invested) * 100;
  }
  if (stock.quantity == null || stock.quantity! <= 0) return null;
  return stock.changePercent;
}

/// Today's position return % for Top Movers % mode (matches Gainers/Losers).
/// Prefer day ₹ / invested; else market day [Stock.changePercent].
double? moverDayReturnPercent(Stock stock) {
  final day = moverDayValueChange(stock);
  final invested = stock.investedAmount;
  if (day != null && invested != null && invested > 0) {
    return (day / invested) * 100;
  }
  return stock.changePercent;
}

String? moverSubtitle(Stock stock) {
  final sector = _usableLabel(stock.sector);
  if (sector != null) return sector;
  final company = _usableLabel(stock.companyName);
  if (company != null &&
      company.toUpperCase() != stock.symbol.toUpperCase()) {
    return company;
  }
  return null;
}

String formatMoverInr(double amount) =>
    StringUtils.formatCurrencyExact(amount);

/// Compact ₹ for dense total columns (`1000` → `₹1.0K`). Display-only.
String formatMoverInrCompact(double amount) =>
    StringUtils.formatCurrency(amount);

String formatMoverQty(double qty) {
  if (qty == qty.roundToDouble()) return qty.toInt().toString();
  return qty.toStringAsFixed(2);
}

String formatSignedInr(double amount) {
  final abs = formatMoverInr(amount.abs());
  if (amount > 0) return '+$abs';
  if (amount < 0) return '-$abs';
  return abs;
}

String formatSignedInrCompact(double amount) {
  final abs = formatMoverInrCompact(amount.abs());
  if (amount > 0) return '+$abs';
  if (amount < 0) return '-$abs';
  return abs;
}

String formatSignedPct(double pct) {
  if (pct.abs() < 0.005) return '0.00%';
  final sign = pct > 0 ? '+' : '';
  return '$sign${pct.toStringAsFixed(2)}%';
}

String? _usableLabel(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty ||
      t == '-' ||
      t.toLowerCase() == 'unknown' ||
      t.toLowerCase().startsWith('unknown ')) {
    return null;
  }
  return t;
}

String _companyName(Stock mover, PortfolioHolding? holding) {
  if (holding != null) {
    final fromHolding = holding.companyName.trim().isNotEmpty
        ? holding.companyName.trim()
        : holding.name.trim();
    if (fromHolding.isNotEmpty &&
        fromHolding.toUpperCase() != holding.symbol.toUpperCase()) {
      return fromHolding;
    }
  }
  if (mover.companyName.isNotEmpty &&
      mover.companyName.toUpperCase() != mover.symbol.toUpperCase()) {
    return mover.companyName;
  }
  return mover.companyName;
}
