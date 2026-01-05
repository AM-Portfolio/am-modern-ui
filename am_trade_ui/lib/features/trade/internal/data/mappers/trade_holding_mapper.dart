import 'package:am_common/core/utils/logger.dart';
import '../../domain/entities/trade_controller_entities.dart';
import '../../domain/entities/trade_holding.dart';
import '../dtos/trade_holding_dto.dart';
import 'trade_controller_mapper.dart';

/// Mapper for trade holding - now delegates to TradeControllerMapper
/// since TradeHoldingDto is a typedef alias of TradeDetailsDto
class TradeHoldingMapper {
  /// Convert TradeHoldingDto to TradeDetails domain entity
  /// Delegates to TradeControllerMapper since TradeHoldingDto = TradeDetailsDto
  static TradeDetails fromDto(TradeHoldingDto dto) {
    AppLogger.debug('🔄 Mapping TradeHoldingDto to TradeDetails', tag: 'TradeHoldingMapper');
    AppLogger.debug('  Trade ID: ${dto.tradeId}', tag: 'TradeHoldingMapper');
    AppLogger.debug('  Attachments in DTO: ${dto.attachments?.length ?? 0} items', tag: 'TradeHoldingMapper');

    if (dto.attachments != null && dto.attachments!.isNotEmpty) {
      for (var i = 0; i < dto.attachments!.length; i++) {
        final att = dto.attachments![i];
        AppLogger.debug('    [$i] File: ${att.fileName}, URL: ${att.fileUrl}', tag: 'TradeHoldingMapper');
      }
    }

    // Delegate to TradeControllerMapper which handles all mapping for TradeDetailsDto
    final result = TradeControllerMapper.toTradeDetailsEntity(dto);
    AppLogger.debug('  ✅ Mapped Attachments: ${result.attachments?.length ?? 0} items', tag: 'TradeHoldingMapper');
    return result;
  }

  /// Convert list of TradeHoldingDtos to list of TradeDetails entities
  static List<TradeDetails> fromDtoList(List<TradeHoldingDto> dtos) => dtos.map(fromDto).toList();

  /// Convert TradeHoldingsDto to TradeHoldings domain entity
  static TradeHoldings fromListDto(TradeHoldingsDto dto, String userId, String portfolioId) => TradeHoldings(
    userId: userId,
    portfolioId: portfolioId,
    content: fromDtoList(dto.content),
    totalPages: dto.totalPages,
    last: dto.last,
    totalElements: dto.totalElements,
    first: dto.first,
    size: dto.size,
    number: dto.number,
    numberOfElements: dto.numberOfElements,
    empty: dto.empty,
  );
}
