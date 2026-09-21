import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../chart_types/chart_type_id.dart';
import '../timeframe/chart_timeframe.dart';

enum ChartGridLayout { one, two, four }

extension ChartGridLayoutX on ChartGridLayout {
  int get paneCount => switch (this) {
        ChartGridLayout.one => 1,
        ChartGridLayout.two => 2,
        ChartGridLayout.four => 4,
      };

  String get code => name;

  static ChartGridLayout fromCode(String? code) {
    switch ((code ?? 'one').toLowerCase()) {
      case 'two':
        return ChartGridLayout.two;
      case 'four':
        return ChartGridLayout.four;
      default:
        return ChartGridLayout.one;
    }
  }
}

class PaneSnapshot {
  const PaneSnapshot({
    required this.symbol,
    required this.timeframe,
    required this.chartType,
  });

  final String symbol;
  final ChartTimeframe timeframe;
  final ChartTypeId chartType;

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'tf': timeframe.code,
        'type': chartType.id,
      };

  factory PaneSnapshot.fromJson(Map<String, dynamic> j) => PaneSnapshot(
        symbol: (j['symbol'] as String?) ?? 'NIFTY 50',
        timeframe: ChartTimeframe.fromCode(j['tf'] as String?),
        chartType: ChartTypeId.fromId(j['type'] as String?),
      );
}

class WorkspaceSnapshot {
  const WorkspaceSnapshot({
    required this.layout,
    required this.panes,
    this.activePaneIndex = 0,
  });

  final ChartGridLayout layout;
  final List<PaneSnapshot> panes;
  final int activePaneIndex;

  Map<String, dynamic> toJson() => {
        'layout': layout.code,
        'active': activePaneIndex,
        'panes': panes.map((p) => p.toJson()).toList(),
      };

  factory WorkspaceSnapshot.fromJson(Map<String, dynamic> j) {
    final layout = ChartGridLayoutX.fromCode(j['layout'] as String?);
    final rawPanes = j['panes'];
    final panes = <PaneSnapshot>[];
    if (rawPanes is List) {
      for (final e in rawPanes) {
        if (e is Map) {
          panes.add(PaneSnapshot.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    // Legacy single-pane shape
    if (panes.isEmpty && j['symbol'] != null) {
      panes.add(PaneSnapshot(
        symbol: (j['symbol'] as String?) ?? 'NIFTY 50',
        timeframe: ChartTimeframe.fromCode(j['tf'] as String?),
        chartType: ChartTypeId.fromId(j['type'] as String?),
      ));
    }
    if (panes.isEmpty) {
      panes.add(const PaneSnapshot(
        symbol: 'NIFTY 50',
        timeframe: ChartTimeframe.d1,
        chartType: ChartTypeId.candlestick,
      ));
    }
    return WorkspaceSnapshot(
      layout: layout,
      panes: panes,
      activePaneIndex: (j['active'] as num?)?.toInt() ?? 0,
    );
  }
}

class WorkspaceStore {
  static const _key = 'am_chart_ui.workspace.v2';

  Future<WorkspaceSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? prefs.getString('am_chart_ui.workspace.v1');
    if (raw == null || raw.isEmpty) return null;
    try {
      return WorkspaceSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(WorkspaceSnapshot snap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snap.toJson()));
  }
}
