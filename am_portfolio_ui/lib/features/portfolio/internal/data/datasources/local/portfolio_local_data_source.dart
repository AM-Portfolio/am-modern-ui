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
  static const String _summaryBoxName = 'portfolio_summary_v2';
  static const String _listBoxName = 'user_portfolios';

  Future<void>? _initFuture;

  Future<void> ensureInitialized() {
    _initFuture ??= init();
    return _initFuture!;
  }

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
  Future<PortfolioHoldings?> getLastHoldings(String portfolioId) async {
    await ensureInitialized();
    try {
      final box = Hive.box<PortfolioHoldingsHiveModel>(_holdingsBoxName);
      final hiveModel = box.get(portfolioId);
      return hiveModel?.toDomain();
    } catch (e) {
      CommonLogger.error(
        'Failed to get cached holdings',
        error: e,
        tag: 'PortfolioLocalDataSource',
      );
      return null;
    }
  }

  /// Cache holdings
  Future<void> cacheHoldings(String portfolioId, PortfolioHoldings data) async {
    await ensureInitialized();
    try {
      final box = Hive.box<PortfolioHoldingsHiveModel>(_holdingsBoxName);
      await box.put(portfolioId, PortfolioHoldingsHiveModel.fromDomain(data));
      CommonLogger.info(
        'Cached holdings for $portfolioId',
        tag: 'PortfolioLocalDataSource',
      );
    } catch (e) {
      CommonLogger.error(
        'Failed to cache holdings',
        error: e,
        tag: 'PortfolioLocalDataSource',
      );
    }
  }

  /// Get cached summary
  Future<PortfolioSummary?> getLastSummary(String portfolioId) async {
    await ensureInitialized();
    try {
      final box = Hive.box<PortfolioSummaryHiveModel>(_summaryBoxName);
      final hiveModel = box.get(portfolioId);
      return hiveModel?.toDomain();
    } catch (e) {
      CommonLogger.error(
        'Failed to get cached summary',
        error: e,
        tag: 'PortfolioLocalDataSource',
      );
      return null;
    }
  }

  /// Cache summary
  Future<void> cacheSummary(String portfolioId, PortfolioSummary data) async {
    await ensureInitialized();
    try {
      final box = Hive.box<PortfolioSummaryHiveModel>(_summaryBoxName);
      await box.put(portfolioId, PortfolioSummaryHiveModel.fromDomain(data));
      CommonLogger.info(
        'Cached summary for $portfolioId',
        tag: 'PortfolioLocalDataSource',
      );
    } catch (e) {
      CommonLogger.error(
        'Failed to cache summary',
        error: e,
        tag: 'PortfolioLocalDataSource',
      );
    }
  }

  /// Get cached portfolio list
  Future<PortfolioList?> getLastPortfolioList() async {
    await ensureInitialized();
    try {
      final box = Hive.box<PortfolioListHiveModel>(_listBoxName);
      final hiveModel = box.get('current_user');
      return hiveModel?.toDomain();
    } catch (e) {
      CommonLogger.error(
        'Failed to get cached portfolio list',
        error: e,
        tag: 'PortfolioLocalDataSource',
      );
      return null;
    }
  }

  /// Cache portfolio list
  Future<void> cachePortfolioList(PortfolioList data) async {
    await ensureInitialized();
    try {
      final box = Hive.box<PortfolioListHiveModel>(_listBoxName);
      await box.put('current_user', PortfolioListHiveModel.fromDomain(data));
      CommonLogger.info(
        'Cached portfolio list for current_user',
        tag: 'PortfolioLocalDataSource',
      );
    } catch (e) {
      CommonLogger.error(
        'Failed to cache portfolio list',
        error: e,
        tag: 'PortfolioLocalDataSource',
      );
    }
  }
}
