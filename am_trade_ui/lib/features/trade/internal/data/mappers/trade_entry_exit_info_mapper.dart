import '../../domain/entities/trade_entry_exit_info.dart';
import '../dtos/trade_controller_dtos.dart';

class TradeEntryExitInfoMapper {
  static TradeEntryExitInfo? fromDto(EntryExitInfoDto? dto) {
    if (dto == null) return null;

    return TradeEntryExitInfo(
      timestamp: dto.timestamp != null ? DateTime.tryParse(dto.timestamp!) : null,
      price: dto.price,
      quantity: dto.quantity,
      totalValue: dto.totalValue,
      fees: dto.fees,
    );
  }

  static EntryExitInfoDto fromEntity(TradeEntryExitInfo entity) {
    return EntryExitInfoDto(
      timestamp: entity.timestamp?.toIso8601String(),
      price: entity.price,
      quantity: entity.quantity,
      totalValue: entity.totalValue,
      fees: entity.fees,
    );
  }
}
