import '../../domain/entities/instrument_info.dart';
import '../dtos/trade_controller_dtos.dart';

class InstrumentInfoMapper {
  static InstrumentInfo? fromDto(InstrumentInfoDto? dto) {
    if (dto == null) return null;

    return InstrumentInfo(
      symbol: dto.symbol,
      isin: dto.isin,
      rawSymbol: dto.rawSymbol,
      exchange: dto.exchange,
      segment: dto.segment,
      series: dto.series,
      description: dto.description,
      baseSymbol: dto.baseSymbol,
      formattedDescription: dto.formattedDescription,
      isDerivative: dto.derivative,
      isIndex: dto.index,
    );
  }

  static InstrumentInfoDto fromEntity(InstrumentInfo entity) {
    return InstrumentInfoDto(
      symbol: entity.symbol,
      isin: entity.isin,
      rawSymbol: entity.rawSymbol,
      exchange: entity.exchange,
      segment: entity.segment,
      series: entity.series,
      description: entity.description,
      baseSymbol: entity.baseSymbol,
      formattedDescription: entity.formattedDescription,
      derivative: entity.isDerivative,
      index: entity.isIndex,
    );
  }
}
