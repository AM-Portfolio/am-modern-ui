import 'dart:convert';
import 'package:am_trade_ui/features/trade/internal/data/dtos/trade_holding_dto.dart';
void main() {
  final jsonStr = '''{
    "content": [
      {
        "tradeId": "ad81cdfd-6428-4ad8-acc8-5a5b671a4083",
        "portfolioId": "94b6063f-4be8-485d-aa0e-3c5992d80a72",
        "symbol": "INFY",
        "status": "OPEN",
        "tradePositionType": "LONG",
        "instrumentInfo": { "symbol": "INFY" },
        "entryInfo": { "price": 2322.0 },
        "currentPrice": 1079.0,
        "metrics": { "profitLoss": -13673.0 }
      }
    ]
  }''';
  final json = jsonDecode(jsonStr);
  final dto = TradeHoldingsDto.fromJson(json);
  print(dto.content.first.currentPrice);
}