import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart' show CommonLogger;
import '../../internal/data/datasources/portfolio_remote_data_source.dart';
import 'portfolio_history_state.dart';

class PortfolioHistoryCubit extends Cubit<PortfolioHistoryState> {
  PortfolioHistoryCubit(this._dataSource) : super(PortfolioHistoryInitial());

  final PortfolioRemoteDataSource _dataSource;

  // Deduplication guard — don't refetch same data
  String? _lastPortfolioId;
  String? _lastTimeFrame;

  Future<void> loadHistory(String? portfolioId, TimeFrame timeFrame) async {
    final tf = timeFrame.code; // e.g. "1M"

    // Skip if already loaded for the same args
    if (state is PortfolioHistoryLoaded &&
        _lastPortfolioId == portfolioId &&
        _lastTimeFrame == tf) {
      return;
    }

    emit(PortfolioHistoryLoading());

    try {
      final snapshots = await _dataSource.getPortfolioHistory(
        portfolioId == 'all' ? null : portfolioId,
        tf,
      );

      // Extract sorted, unique broker names for the tab switcher
      final Set<String> brokerSet = {};
      for (final s in snapshots) {
        for (final p in s.portfolios) {
          if (p.brokerType != null && p.brokerType!.isNotEmpty) {
            brokerSet.add(p.brokerType!);
          }
        }
      }

      // 'ALL' is always first; rest are sorted alphabetically
      final brokers = ['ALL', ...brokerSet.toList()..sort()];

      _lastPortfolioId = portfolioId;
      _lastTimeFrame = tf;

      emit(PortfolioHistoryLoaded(
        snapshots: snapshots,
        availableBrokers: brokers,
      ));

      CommonLogger.info(
        'Portfolio history loaded: ${snapshots.length} snapshots, brokers: $brokers',
        tag: 'PortfolioHistoryCubit',
      );
    } catch (e, stack) {
      CommonLogger.error(
        'Failed to load portfolio history',
        tag: 'PortfolioHistoryCubit',
        error: e,
        stackTrace: stack,
      );
      emit(PortfolioHistoryError(e.toString()));
    }
  }

  /// Call this when the user selects a different portfolio or time frame
  void invalidate() {
    _lastPortfolioId = null;
    _lastTimeFrame = null;
  }
}
