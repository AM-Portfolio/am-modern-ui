enum ChartTimeframe {
  s1('1S', '1s'),
  s5('5S', '5s'),
  m1('1M', '1m'),
  m3('3M', '3m'),
  m5('5M', '5m'),
  m15('15M', '15m'),
  m30('30M', '30m'),
  h1('1H', '1H'),
  d1('1D', '1D'),
  w1('1W', '1W'),
  mo1('1MO', '1M'),
  y1('1Y', '1Y');

  const ChartTimeframe(this.code, this.label);
  final String code;
  final String label;

  static ChartTimeframe fromCode(String? code) {
    final c = (code ?? '1Y').toUpperCase();
    if (c == '1M' || c == '1MO') return ChartTimeframe.mo1;
    return ChartTimeframe.values.firstWhere(
      (e) => e.code == c,
      orElse: () => ChartTimeframe.d1,
    );
  }

  /// Phase 1 chips shown in the toolbar.
  static const phase1 = [
    ChartTimeframe.m5,
    ChartTimeframe.m15,
    ChartTimeframe.h1,
    ChartTimeframe.d1,
    ChartTimeframe.w1,
    ChartTimeframe.mo1,
    ChartTimeframe.y1,
  ];
}
