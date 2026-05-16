import 'package:hive/hive.dart';
import '../../../../internal/domain/entities/portfolio_list.dart';

@HiveType(typeId: 6)
class PortfolioItemHiveModel extends HiveObject {
  @HiveField(0)
  final String portfolioId;

  @HiveField(1)
  final String portfolioName;

  PortfolioItemHiveModel({
    required this.portfolioId,
    required this.portfolioName,
  });

  factory PortfolioItemHiveModel.fromDomain(PortfolioItem entity) {
    return PortfolioItemHiveModel(
      portfolioId: entity.portfolioId,
      portfolioName: entity.portfolioName,
    );
  }

  PortfolioItem toDomain() {
    return PortfolioItem(
      portfolioId: portfolioId,
      portfolioName: portfolioName,
    );
  }
}

class PortfolioItemHiveModelAdapter
    extends TypeAdapter<PortfolioItemHiveModel> {
  @override
  final int typeId = 6;

  @override
  PortfolioItemHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PortfolioItemHiveModel(
      portfolioId: fields[0] as String,
      portfolioName: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PortfolioItemHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.portfolioId)
      ..writeByte(1)
      ..write(obj.portfolioName);
  }
}

@HiveType(typeId: 7)
class PortfolioListHiveModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final DateTime lastUpdated;

  @HiveField(2)
  final List<PortfolioItemHiveModel> portfolios;

  PortfolioListHiveModel({
    required this.userId,
    required this.lastUpdated,
    required this.portfolios,
  });

  factory PortfolioListHiveModel.fromDomain(PortfolioList entity) {
    return PortfolioListHiveModel(
      userId: entity.userId,
      lastUpdated: entity.lastUpdated,
      portfolios: entity.portfolios
          .map((e) => PortfolioItemHiveModel.fromDomain(e))
          .toList(),
    );
  }

  PortfolioList toDomain() {
    return PortfolioList(
      userId: userId,
      lastUpdated: lastUpdated,
      portfolios: portfolios.map((e) => e.toDomain()).toList(),
    );
  }
}

class PortfolioListHiveModelAdapter
    extends TypeAdapter<PortfolioListHiveModel> {
  @override
  final int typeId = 7;

  @override
  PortfolioListHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PortfolioListHiveModel(
      userId: fields[0] as String,
      lastUpdated: fields[1] as DateTime,
      portfolios: (fields[2] as List).cast<PortfolioItemHiveModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, PortfolioListHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.lastUpdated)
      ..writeByte(2)
      ..write(obj.portfolios);
  }
}
