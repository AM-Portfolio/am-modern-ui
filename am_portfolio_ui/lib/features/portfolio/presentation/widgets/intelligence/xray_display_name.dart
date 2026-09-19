/// FE display label for X-Ray slice names. API `name` stays unchanged for sync.
///
/// Class Add sheet (bonds / commodities / cash) must reuse this helper so
/// `COMMODITY` stays labeled **Precious Metal** while the wire value is unchanged.
String xrayDisplayName(String raw) {
  final key = raw.trim();
  if (key.isEmpty) return 'Unknown';
  switch (key.toUpperCase()) {
    case 'LARGE_CAP':
      return 'Large Cap';
    case 'MID_CAP':
      return 'Mid Cap';
    case 'SMALL_CAP':
      return 'Small Cap';
    case 'MICRO_CAP':
      return 'Micro Cap';
    case 'EQUITY':
      return 'Equity';
    case 'FIXED_INCOME':
      return 'Fixed Income';
    case 'BOND':
    case 'BONDS':
      return 'Bond';
    case 'COMMODITY':
      return 'Precious Metal';
    case 'CASH':
      return 'Cash';
    case 'MUTUAL_FUND':
      return 'Mutual Fund';
    case 'UNKNOWN':
      return 'Unknown';
    default:
      if (!key.contains('_')) return key;
      return key
          .toLowerCase()
          .split('_')
          .where((p) => p.isNotEmpty)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
          .join(' ');
  }
}
