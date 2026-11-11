/// Configurable exchange lot size definitions and dynamic response resolver.
///
/// If exchange-mandated lot sizes change in the future, update the [defaultIndexLotSizes]
/// mapping here so that changes take effect globally across the entire F&O module.
class FoLotSizeConfig {
  const FoLotSizeConfig._();

  /// Exchange-mandated lot sizes for benchmark indices.
  ///
  /// Source: NSE & BSE Derivatives Specifications (Revised Lot Sizes)
  static const Map<String, int> defaultIndexLotSizes = {
    // --- NSE Indices ---
    'NIFTY': 65,
    'NIFTY 50': 65,
    'NIFTY50': 65,
    'BANKNIFTY': 30,
    'NIFTY BANK': 30,
    'FINNIFTY': 60,
    'NIFTY FINANCIAL SERVICES': 60,
    'NIFTY FIN SERVICE': 60,
    'MIDCPNIFTY': 120,
    'NIFTY MIDCAP SELECT': 120,
    'NIFTY MID SELECT': 120,
    'NIFTYNXT50': 25,
    'NIFTY NEXT 50': 25,

    // --- BSE Indices ---
    'SENSEX': 20,
    'BSE SENSEX': 20,
    'BANKEX': 30,
    'BSE BANKEX': 30,
    'SENSEX50': 75,
    'BSE SENSEX 50': 75,
  };

  /// Resolves the effective lot size with the following priority:
  /// 1. Dynamic API contract response (`lot_size` or `lotSize`)
  /// 2. Dynamic Option Chain root response (`lotSize` or `lot_size`)
  /// 3. Dynamic Option Chain strike rows (`call['lotSize']` or `put['lotSize']`)
  /// 4. Configurable [defaultIndexLotSizes] table
  /// 5. Default fallback to 1 (equities)
  static int resolveLotSize({
    required String symbol,
    dynamic contract,
    Map<String, dynamic>? chainData,
  }) {
    // 1. Check selected or active contract from API response
    if (contract is Map) {
      final raw = contract['lot_size'] ??
          contract['lotSize'] ??
          contract['minimum_lot_size'];
      if (raw is num && raw > 0) return raw.toInt();
      if (raw is String) {
        final parsed = int.tryParse(raw);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    // 2. Check Option Chain root from API response
    if (chainData != null) {
      final rootLot = chainData['lotSize'] ?? chainData['lot_size'];
      if (rootLot is num && rootLot > 0) return rootLot.toInt();
      if (rootLot is String) {
        final parsed = int.tryParse(rootLot);
        if (parsed != null && parsed > 0) return parsed;
      }

      // 3. Check strikes in Option Chain
      final strikes = chainData['strikes'];
      if (strikes is List && strikes.isNotEmpty && strikes.first is Map) {
        final first = strikes.first as Map;
        final call = first['call'] is Map ? first['call'] as Map : null;
        final put = first['put'] is Map ? first['put'] as Map : null;
        final strikeLot = (call?['lotSize'] ??
                call?['lot_size'] ??
                put?['lotSize'] ??
                put?['lot_size']) as num?;
        if (strikeLot != null && strikeLot > 0) return strikeLot.toInt();
      }
    }

    // 4. Check configurable index mapping
    final normalized = symbol.toUpperCase().trim();
    if (defaultIndexLotSizes.containsKey(normalized)) {
      return defaultIndexLotSizes[normalized]!;
    }

    // Secondary check without spaces/punctuation
    final stripped = normalized.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    for (final entry in defaultIndexLotSizes.entries) {
      if (entry.key.replaceAll(RegExp(r'[^A-Z0-9]'), '') == stripped) {
        return entry.value;
      }
    }

    // 5. Default fallback for individual stock underliers before contract load
    return 1;
  }
}
