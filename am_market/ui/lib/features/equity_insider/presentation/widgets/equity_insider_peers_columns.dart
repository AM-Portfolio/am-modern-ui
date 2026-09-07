import 'package:flutter/material.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../../core/styles/market_theme_extension.dart';

class PeerColumnDef {
  final String label;
  final String key;
  final double? Function(CompetitorPeer peer) valueGetter;
  final Widget Function(BuildContext context, CompetitorPeer peer, double maxRoe) cellBuilder;

  const PeerColumnDef({
    required this.label,
    required this.key,
    required this.valueGetter,
    required this.cellBuilder,
  });
}

class PeerColumnsHelper {
  static List<PeerColumnDef> resolveActiveColumns(List<CompetitorPeer> peers) {
    final List<PeerColumnDef> candidates = [
      PeerColumnDef(
        label: 'P/E',
        key: 'pe',
        valueGetter: (p) => p.pe,
        cellBuilder: (context, p, _) => Text(
          p.pe != null ? p.pe!.toStringAsFixed(2) : '—',
          style: TextStyle(color: context.textSecondary),
        ),
      ),
      PeerColumnDef(
        label: 'P/B',
        key: 'pb',
        valueGetter: (p) => p.pb,
        cellBuilder: (context, p, _) => Text(
          p.pb != null ? p.pb!.toStringAsFixed(2) : '—',
          style: TextStyle(color: context.textSecondary),
        ),
      ),
      PeerColumnDef(
        label: 'ROE %',
        key: 'roe',
        valueGetter: (p) => p.roe,
        cellBuilder: (context, p, maxRoe) => buildMetricBar(context, p.roe, maxRoe),
      ),
      PeerColumnDef(
        label: 'ROA %',
        key: 'roa',
        valueGetter: (p) => p.roa,
        cellBuilder: (context, p, _) => Text(
          p.roa != null ? p.roa!.toStringAsFixed(2) : '—',
          style: TextStyle(
            color: p.roa != null && p.roa! > 1.5
                ? context.marketTheme.positive
                : (p.roa != null && p.roa! < 0 ? context.marketTheme.negative : context.textSecondary),
          ),
        ),
      ),
      PeerColumnDef(
        label: 'NIM %',
        key: 'nim',
        valueGetter: (p) => p.nim,
        cellBuilder: (context, p, _) => Text(
          p.nim != null ? '${p.nim!.toStringAsFixed(2)}%' : '—',
          style: TextStyle(
            color: p.nim != null && p.nim! > 3.0 ? context.marketTheme.positive : context.textSecondary,
          ),
        ),
      ),
      PeerColumnDef(
        label: 'Net NPA %',
        key: 'netNpa',
        valueGetter: (p) => p.netNpa,
        cellBuilder: (context, p, _) => Text(
          p.netNpa != null ? '${p.netNpa!.toStringAsFixed(2)}%' : '—',
          style: TextStyle(
            color: p.netNpa != null && p.netNpa! < 0.5
                ? context.marketTheme.positive
                : (p.netNpa != null && p.netNpa! > 1.0 ? context.marketTheme.negative : context.textSecondary),
          ),
        ),
      ),
      PeerColumnDef(
        label: 'CASA %',
        key: 'casa',
        valueGetter: (p) => p.casa,
        cellBuilder: (context, p, _) => Text(
          p.casa != null ? '${p.casa!.toStringAsFixed(2)}%' : '—',
          style: TextStyle(
            color: p.casa != null && p.casa! > 40.0 ? context.marketTheme.positive : context.textSecondary,
          ),
        ),
      ),
      PeerColumnDef(
        label: 'ROCE %',
        key: 'roce',
        valueGetter: (p) => p.roce,
        cellBuilder: (context, p, _) => Text(
          p.roce != null ? p.roce!.toStringAsFixed(2) : '—',
          style: TextStyle(
            color: p.roce != null && p.roce! > 15.0
                ? context.marketTheme.positive
                : (p.roce != null && p.roce! < 0 ? context.marketTheme.negative : context.textSecondary),
            fontWeight: p.roce != null && p.roce! > 15.0 ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
      PeerColumnDef(
        label: 'EV/EBITDA',
        key: 'evEbitda',
        valueGetter: (p) => p.evEbitda,
        cellBuilder: (context, p, _) => Text(
          p.evEbitda != null ? p.evEbitda!.toStringAsFixed(2) : '—',
          style: TextStyle(color: context.textSecondary),
        ),
      ),
      PeerColumnDef(
        label: 'Quick Ratio',
        key: 'quickRatio',
        valueGetter: (p) => p.quickRatio,
        cellBuilder: (context, p, _) => Text(
          p.quickRatio != null ? p.quickRatio!.toStringAsFixed(2) : '—',
          style: TextStyle(color: context.textSecondary),
        ),
      ),
    ];

    return candidates.where((c) => peers.any((p) => c.valueGetter(p) != null)).toList();
  }

  static Widget buildMetricBar(BuildContext context, double? roe, double maxRoe) {
    if (roe == null) {
      return Text('—', style: TextStyle(color: context.textSecondary, fontSize: 12));
    }
    final isPos = roe >= 0;
    final color = isPos ? context.marketTheme.positive : context.marketTheme.negative;

    return Text(
      roe.toStringAsFixed(2),
      style: TextStyle(
        color: color,
        fontWeight: isPos ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}
