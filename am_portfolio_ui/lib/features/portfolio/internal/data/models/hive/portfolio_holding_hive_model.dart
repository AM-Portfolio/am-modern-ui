import 'package:hive/hive.dart';
import '../../../../internal/domain/entities/portfolio_holding.dart';

@HiveType(typeId: 0)
class BrokerHoldingHiveModel extends HiveObject {
  @HiveField(0)
  final String brokerId;

  @HiveField(1)
  final String brokerName;

  @HiveField(2)
  final double quantity;

  @HiveField(3)
  final double avgPrice;

  @HiveField(4)
  final double investedAmount;

  @HiveField(5)
  final DateTime? lastUpdated;

  BrokerHoldingHiveModel({
    required this.brokerId,
    required this.brokerName,
    required this.quantity,
    required this.avgPrice,
    required this.investedAmount,
    this.lastUpdated,
  });

  factory BrokerHoldingHiveModel.fromDomain(BrokerHolding entity) {
    return BrokerHoldingHiveModel(
      brokerId: entity.brokerId,
      brokerName: entity.brokerName,
      quantity: entity.quantity,
      avgPrice: entity.avgPrice,
      investedAmount: entity.investedAmount,
      lastUpdated: entity.lastUpdated,
    );
  }

  BrokerHolding toDomain() {
    return BrokerHolding(
      brokerId: brokerId,
      brokerName: brokerName,
      quantity: quantity,
      avgPrice: avgPrice,
      investedAmount: investedAmount,
      lastUpdated: lastUpdated,
    );
  }
}

class BrokerHoldingHiveModelAdapter extends TypeAdapter<BrokerHoldingHiveModel> {
  @override
  final int typeId = 0;

  @override
  BrokerHoldingHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BrokerHoldingHiveModel(
      brokerId: fields[0] as String,
      brokerName: fields[1] as String,
      quantity: fields[2] as double,
      avgPrice: fields[3] as double,
      investedAmount: fields[4] as double,
      lastUpdated: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BrokerHoldingHiveModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.brokerId)
      ..writeByte(1)
      ..write(obj.brokerName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.avgPrice)
      ..writeByte(4)
      ..write(obj.investedAmount)
      ..writeByte(5)
      ..write(obj.lastUpdated);
  }
}

@HiveType(typeId: 1)
class PortfolioHoldingHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String symbol;

  @HiveField(2)
  final String companyName;

  @HiveField(3)
  final String sector;

  @HiveField(4)
  final String industry;

  @HiveField(5)
  final double quantity;

  @HiveField(6)
  final double avgPrice;

  @HiveField(7)
  final double currentPrice;

  @HiveField(8)
  final double investedAmount;

  @HiveField(9)
  final double currentValue;

  @HiveField(10)
  final double todayChange;

  @HiveField(11)
  final double todayChangePercentage;

  @HiveField(12)
  final double totalGainLoss;

  @HiveField(13)
  final double totalGainLossPercentage;

  @HiveField(14)
  final double portfolioWeight;

  @HiveField(15)
  final List<BrokerHoldingHiveModel> brokerHoldings;

  PortfolioHoldingHiveModel({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.sector,
    required this.industry,
    required this.quantity,
    required this.avgPrice,
    required this.currentPrice,
    required this.investedAmount,
    required this.currentValue,
    required this.todayChange,
    required this.todayChangePercentage,
    required this.totalGainLoss,
    required this.totalGainLossPercentage,
    required this.portfolioWeight,
    required this.brokerHoldings,
  });

  factory PortfolioHoldingHiveModel.fromDomain(PortfolioHolding entity) {
    return PortfolioHoldingHiveModel(
      id: entity.id,
      symbol: entity.symbol,
      companyName: entity.companyName,
      sector: entity.sector,
      industry: entity.industry,
      quantity: entity.quantity,
      avgPrice: entity.avgPrice,
      currentPrice: entity.currentPrice,
      investedAmount: entity.investedAmount,
      currentValue: entity.currentValue,
      todayChange: entity.todayChange,
      todayChangePercentage: entity.todayChangePercentage,
      totalGainLoss: entity.totalGainLoss,
      totalGainLossPercentage: entity.totalGainLossPercentage,
      portfolioWeight: entity.portfolioWeight,
      brokerHoldings: entity.brokerHoldings
          .map((e) => BrokerHoldingHiveModel.fromDomain(e))
          .toList(),
    );
  }

  PortfolioHolding toDomain() {
    return PortfolioHolding(
      id: id,
      symbol: symbol,
      companyName: companyName,
      sector: sector,
      industry: industry,
      quantity: quantity,
      avgPrice: avgPrice,
      currentPrice: currentPrice,
      investedAmount: investedAmount,
      currentValue: currentValue,
      todayChange: todayChange,
      todayChangePercentage: todayChangePercentage,
      totalGainLoss: totalGainLoss,
      totalGainLossPercentage: totalGainLossPercentage,
      portfolioWeight: portfolioWeight,
      brokerHoldings: brokerHoldings.map((e) => e.toDomain()).toList(),
    );
  }
}

class PortfolioHoldingHiveModelAdapter extends TypeAdapter<PortfolioHoldingHiveModel> {
  @override
  final int typeId = 1;

  @override
  PortfolioHoldingHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PortfolioHoldingHiveModel(
      id: fields[0] as String,
      symbol: fields[1] as String,
      companyName: fields[2] as String,
      sector: fields[3] as String,
      industry: fields[4] as String,
      quantity: fields[5] as double,
      avgPrice: fields[6] as double,
      currentPrice: fields[7] as double,
      investedAmount: fields[8] as double,
      currentValue: fields[9] as double,
      todayChange: fields[10] as double,
      todayChangePercentage: fields[11] as double,
      totalGainLoss: fields[12] as double,
      totalGainLossPercentage: fields[13] as double,
      portfolioWeight: fields[14] as double,
      brokerHoldings: (fields[15] as List).cast<BrokerHoldingHiveModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, PortfolioHoldingHiveModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.symbol)
      ..writeByte(2)
      ..write(obj.companyName)
      ..writeByte(3)
      ..write(obj.sector)
      ..writeByte(4)
      ..write(obj.industry)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.avgPrice)
      ..writeByte(7)
      ..write(obj.currentPrice)
      ..writeByte(8)
      ..write(obj.investedAmount)
      ..writeByte(9)
      ..write(obj.currentValue)
      ..writeByte(10)
      ..write(obj.todayChange)
      ..writeByte(11)
      ..write(obj.todayChangePercentage)
      ..writeByte(12)
      ..write(obj.totalGainLoss)
      ..writeByte(13)
      ..write(obj.totalGainLossPercentage)
      ..writeByte(14)
      ..write(obj.portfolioWeight)
      ..writeByte(15)
      ..write(obj.brokerHoldings);
  }
}

@HiveType(typeId: 2)
class PortfolioHoldingsHiveModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final List<PortfolioHoldingHiveModel> holdings;

  @HiveField(2)
  final DateTime lastUpdated;

  PortfolioHoldingsHiveModel({
    required this.userId,
    required this.holdings,
    required this.lastUpdated,
  });

  factory PortfolioHoldingsHiveModel.fromDomain(PortfolioHoldings entity) {
    return PortfolioHoldingsHiveModel(
      userId: entity.userId,
      holdings: entity.holdings
          .map((e) => PortfolioHoldingHiveModel.fromDomain(e))
          .toList(),
      lastUpdated: entity.lastUpdated,
    );
  }

  PortfolioHoldings toDomain() {
    return PortfolioHoldings(
      userId: userId,
      holdings: holdings.map((e) => e.toDomain()).toList(),
      lastUpdated: lastUpdated,
    );
  }
}

class PortfolioHoldingsHiveModelAdapter extends TypeAdapter<PortfolioHoldingsHiveModel> {
  @override
  final int typeId = 2;

  @override
  PortfolioHoldingsHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PortfolioHoldingsHiveModel(
      userId: fields[0] as String,
      holdings: (fields[1] as List).cast<PortfolioHoldingHiveModel>(),
      lastUpdated: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PortfolioHoldingsHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.holdings)
      ..writeByte(2)
      ..write(obj.lastUpdated);
  }
}
