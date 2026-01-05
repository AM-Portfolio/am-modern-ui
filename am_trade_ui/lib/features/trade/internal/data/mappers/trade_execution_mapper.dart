import '../../domain/entities/trade_execution.dart';
import '../dtos/trade_execution_dto.dart';
import 'instrument_info_mapper.dart';

class TradeExecutionMapper {
  static TradeExecutionBasicInfo? fromBasicInfoDto(
      TradeExecutionBasicInfoDto? dto) {
    if (dto == null) return null;

    return TradeExecutionBasicInfo(
      tradeId: dto.tradeId,
      orderId: dto.orderId,
      tradeDate: dto.tradeDate != null ? DateTime.tryParse(dto.tradeDate!) : null,
      orderExecutionTime: dto.orderExecutionTime != null
          ? DateTime.tryParse(dto.orderExecutionTime!)
          : null,
      brokerType: dto.brokerType,
      tradeType: dto.tradeType,
    );
  }

  static TradeExecutionInfo? fromExecutionInfoDto(
      TradeExecutionInfoDto? dto) {
    if (dto == null) return null;

    return TradeExecutionInfo(
      tradeType: dto.tradeType,
      auction: dto.auction,
      quantity: dto.quantity,
      price: dto.price,
    );
  }

  static TradeExecution? fromDto(TradeExecutionDto? dto) {
    if (dto == null) return null;

    return TradeExecution(
      basicInfo: fromBasicInfoDto(dto.basicInfo),
      instrumentInfo: InstrumentInfoMapper.fromDto(dto.instrumentInfo),
      executionInfo: fromExecutionInfoDto(dto.executionInfo),
    );
  }

  static List<TradeExecution> fromDtoList(List<TradeExecutionDto>? dtos) {
    if (dtos == null || dtos.isEmpty) return [];
    return dtos.map((dto) => fromDto(dto)!).where((e) => e != null).toList();
  }
}
