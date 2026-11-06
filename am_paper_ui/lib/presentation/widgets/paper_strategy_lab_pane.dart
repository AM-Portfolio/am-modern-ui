import 'dart:async';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/strategy_lab_client.dart';
import '../../data/strategy_lab_models.dart';

/// Paper desk tab: run Strategy Lab backtests and view calendar/report.
class PaperStrategyLabPane extends StatefulWidget {
  const PaperStrategyLabPane({super.key, this.initialSymbol});

  final String? initialSymbol;

  @override
  State<PaperStrategyLabPane> createState() => _PaperStrategyLabPaneState();
}

class _PaperStrategyLabPaneState extends State<PaperStrategyLabPane> {
  final _client = StrategyLabClient();
  final _symbolCtrl = TextEditingController();
  final _fromCtrl = TextEditingController(text: '2024-01-01');
  final _toCtrl = TextEditingController(text: '2024-01-20');

  List<StrategyLabTemplate> _templates = const [];
  StrategyLabTemplate? _selected;
  String _timeframe = '1d';
  bool _loadingCatalog = true;
  bool _running = false;
  String? _statusLine;
  String? _error;
  BacktestJob? _job;
  BacktestReport? _report;

  @override
  void initState() {
    super.initState();
    final sym = widget.initialSymbol?.trim().toUpperCase() ?? '';
    _symbolCtrl.text = sym.isEmpty ? 'RELIANCE' : sym;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadCatalog());
    });
  }

  @override
  void didUpdateWidget(covariant PaperStrategyLabPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialSymbol?.trim().toUpperCase() ?? '';
    final prev = oldWidget.initialSymbol?.trim().toUpperCase() ?? '';
    if (next.isNotEmpty && next != prev && _symbolCtrl.text.trim().isEmpty) {
      _symbolCtrl.text = next;
    }
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loadingCatalog = true;
      _error = null;
    });
    try {
      final templates = await _client.loadCatalogTemplates();
      if (!mounted) return;
      final supported = templates.where((t) => t.supported).toList();
      final pick = supported.isNotEmpty
          ? supported.first
          : (templates.isNotEmpty ? templates.first : null);
      setState(() {
        _templates = templates;
        _selected = pick;
        _loadingCatalog = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCatalog = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _run() async {
    final tpl = _selected;
    if (tpl == null) return;
    if (!tpl.supported) {
      setState(() {
        _error =
            '${tpl.strategyId} is catalog-only — engine supports ZONE_SCALE / LINE_LEVEL / SUPER_BRACKET.';
      });
      return;
    }
    final symbol = _symbolCtrl.text.trim().toUpperCase();
    if (symbol.isEmpty) {
      setState(() => _error = 'Symbol required');
      return;
    }

    setState(() {
      _running = true;
      _error = null;
      _report = null;
      _job = null;
      _statusLine = 'Upserting ${tpl.strategyId}…';
    });

    try {
      final result = await _client.runBacktestAndWait(
        upsertBody: tpl.toUpsertBody(),
        symbol: symbol,
        from: _fromCtrl.text.trim(),
        to: _toCtrl.text.trim(),
        timeframe: _timeframe,
      );
      if (!mounted) return;
      setState(() {
        _job = result.job;
        _report = result.report;
        _running = false;
        _statusLine = result.job.status == 'DONE'
            ? 'Backtest ${result.job.jobId} complete'
            : 'Backtest ${result.job.status}'
                '${result.job.error != null ? ': ${result.job.error}' : ''}';
        if (result.job.status == 'FAILED') {
          _error = result.job.error ?? 'Backtest failed';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _error = e.toString();
        _statusLine = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final pnlFmt = NumberFormat('+#,##0.00;-#,##0.00');
    final pctFmt = NumberFormat('0.0%');

    if (_loadingCatalog) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Strategy Lab',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Run a catalog strategy on real market historical bars and open the fill report.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Strategy',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<StrategyLabTemplate>(
              isExpanded: true,
              value: _selected,
              items: _templates
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        '${t.strategyId} — ${t.label}'
                        '${t.supported ? '' : ' (catalog only)'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _running
                  ? null
                  : (v) => setState(() => _selected = v),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _symbolCtrl,
                enabled: !_running,
                decoration: const InputDecoration(
                  labelText: 'Symbol',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Timeframe',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _timeframe,
                    items: const [
                      DropdownMenuItem(value: '1d', child: Text('1d')),
                      DropdownMenuItem(value: '1h', child: Text('1h')),
                      DropdownMenuItem(value: '5m', child: Text('5m')),
                    ],
                    onChanged: _running
                        ? null
                        : (v) => setState(() => _timeframe = v ?? '1d'),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _fromCtrl,
                enabled: !_running,
                decoration: const InputDecoration(
                  labelText: 'From (yyyy-MM-dd)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _toCtrl,
                enabled: !_running,
                decoration: const InputDecoration(
                  labelText: 'To (yyyy-MM-dd)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _running || _selected == null ? null : _run,
          icon: _running
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(_running ? 'Running…' : 'Run strategy test'),
        ),
        if (_statusLine != null) ...[
          const SizedBox(height: 12),
          Text(
            _statusLine!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.statusError,
            ),
          ),
        ],
        if (_job != null) ...[
          const SizedBox(height: 16),
          _sectionTitle(context, 'Job'),
          Text(
            '${_job!.jobId} · ${_job!.status} · ${_job!.strategyId} · ${_job!.symbol}',
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if (_report != null) ...[
          const SizedBox(height: 20),
          _sectionTitle(context, 'Report summary'),
          if (_report!.hasBarsNote) ...[
            _InfoBanner(message: _report!.barsNote!),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(
                label: 'Total PnL',
                value: pnlFmt.format(_report!.summary.totalPnl),
                positive: _report!.summary.totalPnl >= 0,
              ),
              _MetricCard(
                label: 'Trades',
                value: '${_report!.summary.trades}',
              ),
              _MetricCard(
                label: 'Win rate',
                value: pctFmt.format(_report!.summary.winRate),
              ),
              if (_report!.summary.avgEntryPrice != null)
                _MetricCard(
                  label: 'Avg entry',
                  value: _report!.summary.avgEntryPrice!.toStringAsFixed(2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Calendar (daily)'),
          ...(_report!.calendar['daily'] ?? const <CalendarBucket>[]).map(
            (b) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(b.date),
              subtitle: Text('${b.trades} trades · win ${pctFmt.format(b.winRate)}'),
              trailing: Text(
                pnlFmt.format(b.pnl),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: b.pnl >= 0
                      ? colors.statusSuccess
                      : colors.statusError,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _sectionTitle(context, 'Fills'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 40,
              columns: const [
                DataColumn(label: Text('When')),
                DataColumn(label: Text('Side')),
                DataColumn(label: Text('Kind')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('PnL')),
              ],
              rows: _report!.trades
                  .map(
                    (t) => DataRow(
                      cells: [
                        DataCell(Text(_shortTs(t.ts))),
                        DataCell(Text(t.side)),
                        DataCell(Text(t.kind)),
                        DataCell(Text(t.qty.toStringAsFixed(0))),
                        DataCell(Text(t.price.toStringAsFixed(2))),
                        DataCell(
                          Text(
                            t.pnl == null ? '—' : pnlFmt.format(t.pnl!),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _shortTs(String ts) {
    if (ts.length >= 16) return ts.substring(0, 16).replaceFirst('T', ' ');
    return ts;
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(8),
        color: colors.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.positive,
  });

  final String label;
  final String value;
  final bool? positive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Color? valueColor;
    if (positive != null) {
      valueColor =
          positive! ? colors.statusSuccess : colors.statusError;
    }
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
