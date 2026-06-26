
import 'dart:convert';
import 'lib/features/trade/internal/domain/enums/broker_types.dart';
import 'lib/features/trade/internal/data/dtos/trade_controller_dtos.dart';
import 'lib/features/trade/internal/domain/enums/trade_directions.dart';
import 'lib/features/trade/internal/domain/enums/trade_statuses.dart';

void main() {
  final dto = TradeDetailsDto(
    tradeId: '',
    portfolioId: 'mock-pf-002',
    instrumentInfo: InstrumentInfoDto(symbol: 'IDEA'),
    status: TradeStatuses.open,
    tradePositionType: TradeDirections.long,
    entryInfo: EntryExitInfoDto(price: 100, quantity: 10, timestamp: '2026-06-25T19:00:00'),
    tradeExecutions: [
      TradeModelDto(
        basicInfo: BasicInfoDto(brokerType: BrokerTypes.zerodha)
      )
    ]
  );
  print(jsonEncode(dto.toJson()));
}

