import 'package:hive_flutter/hive_flutter.dart';
import '../../../../internal/domain/entities/portfolio_holding.dart';
import '../../../../internal/domain/entities/portfolio_summary.dart';
import '../../../../internal/domain/entities/portfolio_list.dart';
import '../../models/hive/portfolio_holding_hive_model.dart';
import '../../models/hive/portfolio_summary_hive_model.dart';
import '../../models/hive/portfolio_list_hive_model.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';

/// Local data source for caching portfolio data using Hive
class PortfolioLocalDataSource {
  static const String _holdingsBoxName = 'portfolio_holdings';
  static const String _summaryBoxName = 'portfolio_summary';
  static const String _listBoxName = 'user_portfolios';

  /// Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Only register adapters if not already registered to avoid errors during hot restart
    if (!Hive.isAdapterRegistered(0)) {
       Hive.registerAdapter(BrokerHoldingHiveModelAdapter());
       Hive.registerAdapter(PortfolioHoldingHiveModelAdapter());
       Hive.registerAdapter(PortfolioHoldingsHiveModelAdapter());
       Hive.registerAdapter(SectorAllocationHiveModelAdapter());
       Hive.registerAdapter(TopPerformerHiveModelAdapter());
       Hive.registerAdapter(PortfolioSummaryHiveModelAdapter());
       Hive.registerAdapter(PortfolioItemHiveModelAdapter());
       Hive.registerAdapter(PortfolioListHiveModelAdapter());
    }

    await Hive.openBox<PortfolioHoldingsHiveModel>(_holdingsBoxName);
    await Hive.openBox<PortfolioSummaryHiveModel>(_summaryBoxName);
    await Hive.openBox<PortfolioListHiveModel>(_listBoxName);
  }

  /// Get cached holdings
  Future<PortfolioHoldings?> getLastHoldings(String userId) async {
    try {
      final box = Hive.box<PortfolioHoldingsHiveModel>(_holdingsBoxName);
      final hiveModel = box.get(userId);
      return hiveModel?.toDomain();
    } catch (e) {
      CommonLogger.error('Failed to get cached holdings', error: e, tag: 'PortfolioLocalDataSource');
      return null;
    }
  }

  /// Cache holdings
  Future<void> cacheHoldings(String userId, PortfolioHoldings data) async {
    try {
      final box = Hive.box<PortfolioHoldingsHiveModel>(_holdingsBoxName);
      await box.put(userId, PortfolioHoldingsHiveModel.fromDomain(data));
      CommonLogger.info('Cached holdings for user: $userId', tag: 'PortfolioLocalDataSource');
    } catch (e) {
      CommonLogger.error('Failed to cache holdings', error: e, tag: 'PortfolioLocalDataSource');
    }
  }

  /// Get cached summary
  Future<PortfolioSummary?> getLastSummary(String userId) async {
    try {
      final box = Hive.box<PortfolioSummaryHiveModel>(_summaryBoxName);
      final hiveModel = box.get(userId);
      return hiveModel?.toDomain();
    } catch (e) {
      CommonLogger.error('Failed to get cached summary', error: e, tag: 'PortfolioLocalDataSource');
      return null;
    }
  }

  /// Cache summary
  Future<void> cacheSummary(String userId, PortfolioSummary data) async {
    try {
      final box = Hive.box<PortfolioSummaryHiveModel>(_summaryBoxName);
      await box.put(userId, PortfolioSummaryHiveModel.fromDomain(data));
      CommonLogger.info('Cached summary for user: $userId', tag: 'PortfolioLocalDataSource');
    } catch (e) {
      CommonLogger.error('Failed to cache summary', error: e, tag: 'PortfolioLocalDataSource');
    }
  }

  /// Get cached portfolio list
  Future<PortfolioList?> getLastPortfolioList(String userId) async {
    try {
      final box = Hive.box<PortfolioListHiveModel>(_listBoxName);
      final hiveModel = box.get(userId);
      return hiveModel?.toDomain();
    } catch (e) {
      CommonLogger.error('Failed to get cached portfolio list', error: e, tag: 'PortfolioLocalDataSource');
      return null;
    }
  }

  /// Cache portfolio list
  Future<void> cachePortfolioList(String userId, PortfolioList data) async {
    try {
      final box = Hive.box<PortfolioListHiveModel>(_listBoxName);
      await box.put(userId, PortfolioListHiveModel.fromDomain(data));
      CommonLogger.info('Cached portfolio list for user: $userId', tag: 'PortfolioLocalDataSource');
    } catch (e) {
      CommonLogger.error('Failed to cache portfolio list', error: e, tag: 'PortfolioLocalDataSource');
    }
  }
}
