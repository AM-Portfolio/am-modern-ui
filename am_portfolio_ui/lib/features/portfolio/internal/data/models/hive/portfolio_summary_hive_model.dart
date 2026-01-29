import 'package:hive/hive.dart';
import '../../../../internal/domain/entities/portfolio_summary.dart';

@HiveType(typeId: 3)
class SectorAllocationHiveModel extends HiveObject {
  @HiveField(0)
  final String sector;

  @HiveField(1)
  final double value;

  @HiveField(2)
  final double percentage;

  @HiveField(3)
  final int holdings;

  SectorAllocationHiveModel({
    required this.sector,
    required this.value,
    required this.percentage,
    required this.holdings,
  });

  factory SectorAllocationHiveModel.fromDomain(SectorAllocation entity) {
    return SectorAllocationHiveModel(
      sector: entity.sector,
      value: entity.value,
      percentage: entity.percentage,
      holdings: entity.holdings,
    );
  }

  SectorAllocation toDomain() {
    return SectorAllocation(
      sector: sector,
      value: value,
      percentage: percentage,
      holdings: holdings,
    );
  }
}

class SectorAllocationHiveModelAdapter extends TypeAdapter<SectorAllocationHiveModel> {
  @override
  final int typeId = 3;

  @override
  SectorAllocationHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SectorAllocationHiveModel(
      sector: fields[0] as String,
      value: fields[1] as double,
      percentage: fields[2] as double,
      holdings: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SectorAllocationHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.sector)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.percentage)
      ..writeByte(3)
      ..write(obj.holdings);
  }
}

@HiveType(typeId: 4)
class TopPerformerHiveModel extends HiveObject {
  @HiveField(0)
  final String symbol;

  @HiveField(1)
  final String companyName;

  @HiveField(2)
  final double gainLoss;

  @HiveField(3)
  final double gainLossPercentage;

  @HiveField(4)
  final double currentValue;

  TopPerformerHiveModel({
    required this.symbol,
    required this.companyName,
    required this.gainLoss,
    required this.gainLossPercentage,
    required this.currentValue,
  });

  factory TopPerformerHiveModel.fromDomain(TopPerformer entity) {
    return TopPerformerHiveModel(
      symbol: entity.symbol,
      companyName: entity.companyName,
      gainLoss: entity.gainLoss,
      gainLossPercentage: entity.gainLossPercentage,
      currentValue: entity.currentValue,
    );
  }

  TopPerformer toDomain() {
    return TopPerformer(
      symbol: symbol,
      companyName: companyName,
      gainLoss: gainLoss,
      gainLossPercentage: gainLossPercentage,
      currentValue: currentValue,
    );
  }
}

class TopPerformerHiveModelAdapter extends TypeAdapter<TopPerformerHiveModel> {
  @override
  final int typeId = 4;

  @override
  TopPerformerHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TopPerformerHiveModel(
      symbol: fields[0] as String,
      companyName: fields[1] as String,
      gainLoss: fields[2] as double,
      gainLossPercentage: fields[3] as double,
      currentValue: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TopPerformerHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.symbol)
      ..writeByte(1)
      ..write(obj.companyName)
      ..writeByte(2)
      ..write(obj.gainLoss)
      ..writeByte(3)
      ..write(obj.gainLossPercentage)
      ..writeByte(4)
      ..write(obj.currentValue);
  }
}

@HiveType(typeId: 5)
class PortfolioSummaryHiveModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final double totalValue;

  @HiveField(2)
  final double totalInvested;

  @HiveField(3)
  final double investmentValue;

  @HiveField(4)
  final double totalGainLoss;

  @HiveField(5)
  final double totalGainLossPercentage;

  @HiveField(6)
  final double todayChange;

  @HiveField(7)
  final double todayChangePercentage;

  @HiveField(8)
  final double todayGainLossPercentage;

  @HiveField(9)
  final int totalHoldings;

  @HiveField(10)
  final int totalAssets;

  @HiveField(11)
  final int todayGainersCount;

  @HiveField(12)
  final int todayLosersCount;

  @HiveField(13)
  final int gainersCount;

  @HiveField(14)
  final int losersCount;

  @HiveField(15)
  final DateTime lastUpdated;

  @HiveField(16)
  final List<SectorAllocationHiveModel> sectorAllocation;

  @HiveField(17)
  final List<TopPerformerHiveModel> topPerformers;

  @HiveField(18)
  final List<TopPerformerHiveModel> worstPerformers;

  PortfolioSummaryHiveModel({
    required this.userId,
    required this.totalValue,
    required this.totalInvested,
    required this.investmentValue,
    required this.totalGainLoss,
    required this.totalGainLossPercentage,
    required this.todayChange,
    required this.todayChangePercentage,
    required this.todayGainLossPercentage,
    required this.totalHoldings,
    required this.totalAssets,
    required this.todayGainersCount,
    required this.todayLosersCount,
    required this.gainersCount,
    required this.losersCount,
    required this.lastUpdated,
    required this.sectorAllocation,
    required this.topPerformers,
    required this.worstPerformers,
  });

  factory PortfolioSummaryHiveModel.fromDomain(PortfolioSummary entity) {
    return PortfolioSummaryHiveModel(
      userId: entity.userId,
      totalValue: entity.totalValue,
      totalInvested: entity.totalInvested,
      investmentValue: entity.investmentValue,
      totalGainLoss: entity.totalGainLoss,
      totalGainLossPercentage: entity.totalGainLossPercentage,
      todayChange: entity.todayChange,
      todayChangePercentage: entity.todayChangePercentage,
      todayGainLossPercentage: entity.todayGainLossPercentage,
      totalHoldings: entity.totalHoldings,
      totalAssets: entity.totalAssets,
      todayGainersCount: entity.todayGainersCount,
      todayLosersCount: entity.todayLosersCount,
      gainersCount: entity.gainersCount,
      losersCount: entity.losersCount,
      lastUpdated: entity.lastUpdated,
      sectorAllocation: entity.sectorAllocation
          .map((e) => SectorAllocationHiveModel.fromDomain(e))
          .toList(),
      topPerformers: entity.topPerformers
          .map((e) => TopPerformerHiveModel.fromDomain(e))
          .toList(),
      worstPerformers: entity.worstPerformers
          .map((e) => TopPerformerHiveModel.fromDomain(e))
          .toList(),
    );
  }

  PortfolioSummary toDomain() {
    return PortfolioSummary(
      userId: userId,
      totalValue: totalValue,
      totalInvested: totalInvested,
      investmentValue: investmentValue,
      totalGainLoss: totalGainLoss,
      totalGainLossPercentage: totalGainLossPercentage,
      todayChange: todayChange,
      todayChangePercentage: todayChangePercentage,
      todayGainLossPercentage: todayGainLossPercentage,
      totalHoldings: totalHoldings,
      totalAssets: totalAssets,
      todayGainersCount: todayGainersCount,
      todayLosersCount: todayLosersCount,
      gainersCount: gainersCount,
      losersCount: losersCount,
      lastUpdated: lastUpdated,
      sectorAllocation: sectorAllocation.map((e) => e.toDomain()).toList(),
      topPerformers: topPerformers.map((e) => e.toDomain()).toList(),
      worstPerformers: worstPerformers.map((e) => e.toDomain()).toList(),
    );
  }
}

class PortfolioSummaryHiveModelAdapter extends TypeAdapter<PortfolioSummaryHiveModel> {
  @override
  final int typeId = 5;

  @override
  PortfolioSummaryHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PortfolioSummaryHiveModel(
      userId: fields[0] as String,
      totalValue: fields[1] as double,
      totalInvested: fields[2] as double,
      investmentValue: fields[3] as double,
      totalGainLoss: fields[4] as double,
      totalGainLossPercentage: fields[5] as double,
      todayChange: fields[6] as double,
      todayChangePercentage: fields[7] as double,
      todayGainLossPercentage: fields[8] as double,
      totalHoldings: fields[9] as int,
      totalAssets: fields[10] as int,
      todayGainersCount: fields[11] as int,
      todayLosersCount: fields[12] as int,
      gainersCount: fields[13] as int,
      losersCount: fields[14] as int,
      lastUpdated: fields[15] as DateTime,
      sectorAllocation: (fields[16] as List).cast<SectorAllocationHiveModel>(),
      topPerformers: (fields[17] as List).cast<TopPerformerHiveModel>(),
      worstPerformers: (fields[18] as List).cast<TopPerformerHiveModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, PortfolioSummaryHiveModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.totalValue)
      ..writeByte(2)
      ..write(obj.totalInvested)
      ..writeByte(3)
      ..write(obj.investmentValue)
      ..writeByte(4)
      ..write(obj.totalGainLoss)
      ..writeByte(5)
      ..write(obj.totalGainLossPercentage)
      ..writeByte(6)
      ..write(obj.todayChange)
      ..writeByte(7)
      ..write(obj.todayChangePercentage)
      ..writeByte(8)
      ..write(obj.todayGainLossPercentage)
      ..writeByte(9)
      ..write(obj.totalHoldings)
      ..writeByte(10)
      ..write(obj.totalAssets)
      ..writeByte(11)
      ..write(obj.todayGainersCount)
      ..writeByte(12)
      ..write(obj.todayLosersCount)
      ..writeByte(13)
      ..write(obj.gainersCount)
      ..writeByte(14)
      ..write(obj.losersCount)
      ..writeByte(15)
      ..write(obj.lastUpdated)
      ..writeByte(16)
      ..write(obj.sectorAllocation)
      ..writeByte(17)
      ..write(obj.topPerformers)
      ..writeByte(18)
      ..write(obj.worstPerformers);
  }
}
