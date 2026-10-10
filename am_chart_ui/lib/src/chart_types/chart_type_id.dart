enum ChartTypeId {
  candlestick('candlestick', 'Candlestick', true),
  hollowCandle('hollow', 'Hollow Candlestick', true),
  ohlcBar('ohlc', 'OHLC Bar', true),
  line('line', 'Line', true),
  area('area', 'Area', true),
  baseline('baseline', 'Baseline', true),
  columns('columns', 'Columns', true),
  heikinAshi('heikin', 'Heikin Ashi', false),
  volumeCandles('vol_candles', 'Volume Candles', false),
  highLow('hl', 'High-Low', false),
  hlcArea('hlc_area', 'HLC Area', false),
  renko('renko', 'Renko', false),
  range('range', 'Range', false),
  kagi('kagi', 'Kagi', false),
  pointFigure('pnf', 'Point & Figure', false),
  lineBreak('linebreak', 'Line Break', false),
  footprint('footprint', 'Footprint', false),
  tpo('tpo', 'TPO / Market Profile', false),
  volumeProfile('vp', 'Volume Profile', false);

  const ChartTypeId(this.id, this.label, this.isAvailable);
  final String id;
  final String label;
  final bool isAvailable;

  static ChartTypeId fromId(String? id) {
    return ChartTypeId.values.firstWhere(
      (e) => e.id == id,
      orElse: () => ChartTypeId.candlestick,
    );
  }

  static List<ChartTypeId> get available =>
      values.where((e) => e.isAvailable).toList();
}
