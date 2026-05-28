import '../../domain/entities/instrument_info.dart';
import '../dtos/trade_controller_dtos.dart';
import '../../domain/enums/exchange_types.dart';
import '../../domain/enums/market_segments.dart';
import '../../domain/enums/series_types.dart';

class InstrumentInfoMapper {
  static InstrumentInfo? fromDto(InstrumentInfoDto? dto) {
    if (dto == null) return null;

    return InstrumentInfo(
      symbol: dto.symbol ?? '',
      isin: dto.isin,
      rawSymbol: dto.rawSymbol,
      exchange: dto.exchange?.name.toUpperCase(),
      segment: dto.segment?.name.toUpperCase(),
      series: dto.series?.name.toUpperCase(),
      description: dto.description,
      baseSymbol: dto.baseSymbol,
      formattedDescription: dto.formattedDescription,
      isDerivative: dto.derivative ?? false,
      isIndex: dto.index ?? false,
    );
  }

  static InstrumentInfoDto fromEntity(InstrumentInfo entity) {
    return InstrumentInfoDto(
      symbol: entity.symbol,
      isin: entity.isin,
      rawSymbol: entity.rawSymbol,
      exchange: _parseExchange(entity.exchange),
      segment: _parseSegment(entity.segment),
      series: _parseSeries(entity.series),
      description: entity.description,
      baseSymbol: entity.baseSymbol,
      formattedDescription: entity.formattedDescription,
      derivative: entity.isDerivative,
      index: entity.isIndex,
    );
  }

  static ExchangeTypes? _parseExchange(String? value) {
    if (value == null) return null;
    try {
      return ExchangeTypes.values.firstWhere((e) => e.name.toLowerCase() == value.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  static MarketSegments? _parseSegment(String? value) {
    if (value == null) return null;
    try {
      return MarketSegments.values.firstWhere((e) => e.name.toLowerCase() == value.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  static SeriesTypes? _parseSeries(String? value) {
    if (value == null) return null;
    try {
      return SeriesTypes.values.firstWhere((e) => e.name.toLowerCase() == value.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}
