import 'package:am_design_system/am_design_system.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../presentation/models/trade_holding_view_model.dart';
import '../../../providers/trade_internal_providers.dart';
import '../../cubit/journal/journal_cubit.dart';
import '../models/journal_trade_id_parser.dart';

/// Journal → Import: browse portfolio fills and/or paste CSV/IDs → DRAFT stubs.
class JournalImportDialog extends ConsumerStatefulWidget {
  const JournalImportDialog({
    super.key,
    required this.journalCubit,
    this.portfolioId,
  });

  final JournalCubit journalCubit;
  final String? portfolioId;

  @override
  ConsumerState<JournalImportDialog> createState() =>
      _JournalImportDialogState();
}

class _JournalImportDialogState extends ConsumerState<JournalImportDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _pasteController = TextEditingController();
  final _symbolFilterController = TextEditingController();

  var _busy = false;
  String? _error;

  // Browse state
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  List<TradeHoldingViewModel> _trades = const [];
  final Set<String> _selectedIds = {};
  var _loadingTrades = false;
  String? _loadError;

  String? get _portfolioId {
    final fromWidget = widget.portfolioId?.trim();
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    return null;
  }

  bool get _canBrowse => _portfolioId != null && _portfolioId!.isNotEmpty;

  List<TradeHoldingViewModel> get _filteredTrades {
    final q = _symbolFilterController.text.trim().toUpperCase();
    if (q.isEmpty) return _trades;
    return _trades
        .where(
          (t) =>
              t.symbol.toUpperCase().contains(q) ||
              t.tradeId.toUpperCase().contains(q),
        )
        .toList();
  }

  List<String> get _pasteIds =>
      JournalTradeIdParser.parseTradeIdsAuto(_pasteController.text);

  List<String> get _mergedIds {
    final seen = <String>{};
    final out = <String>[];
    for (final id in [..._selectedIds, ..._pasteIds]) {
      final t = id.trim();
      if (t.isEmpty) continue;
      if (seen.add(t)) out.add(t);
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _pasteController.addListener(() => setState(() {}));
    _symbolFilterController.addListener(() => setState(() {}));
    if (_canBrowse) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrades());
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pasteController.dispose();
    _symbolFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadTrades() async {
    final pid = _portfolioId;
    if (pid == null || pid.isEmpty) return;
    setState(() {
      _loadingTrades = true;
      _loadError = null;
    });
    try {
      final getRange =
          await ref.read(getTradeCalendarByDateRangeProvider.future);
      final calendar = await getRange(
        pid,
        startDate: _range.start,
        endDate: _range.end,
      );
      if (!mounted) return;
      final list = TradeHoldingViewModel.fromEntityList(calendar.allTrades);
      setState(() {
        _trades = list;
        _selectedIds.removeWhere(
          (id) => !list.any((t) => t.tradeId == id),
        );
        _loadingTrades = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _trades = const [];
        _loadingTrades = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _range,
    );
    if (picked == null || !mounted) return;
    setState(() => _range = picked);
    await _loadTrades();
  }

  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      String? text = file.bytes != null
          ? String.fromCharCodes(file.bytes!)
          : null;
      if (text == null && !kIsWeb && file.path != null) {
        // Path-based read not needed on web; desktop can paste manually.
        text = null;
      }
      if (text == null || text.trim().isEmpty) {
        setState(() => _error = 'Could not read CSV file');
        return;
      }
      setState(() {
        _pasteController.text = text!;
        _error = null;
        _tabs.index = 1;
      });
    } catch (e) {
      setState(() => _error = 'File pick failed: $e');
    }
  }

  Future<void> _import() async {
    final ids = _mergedIds;
    if (ids.isEmpty) {
      setState(() => _error = 'Select fills and/or paste at least one trade ID');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await widget.journalCubit.createFromTrades(
        ids,
        portfolioId: _portfolioId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created ${created.length} journal stubs')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final dateFmt = DateFormat('dd MMM yyyy');
    final mergedCount = _mergedIds.length;

    return AlertDialog(
      backgroundColor: colors.cardSurface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import trades',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Link portfolio trades as journal stubs',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              controller: _tabs,
              labelColor: ModuleColors.trade,
              unselectedLabelColor: colors.textSecondary,
              indicatorColor: ModuleColors.trade,
              tabs: const [
                Tab(text: 'Browse'),
                Tab(text: 'Paste / CSV'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildBrowseTab(theme, colors, dateFmt),
                  _buildPasteTab(theme, colors),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$mergedCount trade ID${mergedCount == 1 ? '' : 's'} ready '
              '(browse + paste, deduped)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy || mergedCount == 0 ? null : _import,
          style: FilledButton.styleFrom(
            backgroundColor: ModuleColors.trade,
          ),
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create journal stubs'),
        ),
      ],
    );
  }

  Widget _buildBrowseTab(
    ThemeData theme,
    AppColorsTheme colors,
    DateFormat dateFmt,
  ) {
    if (!_canBrowse) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Select a portfolio to browse fills.\n'
            'You can still paste trade IDs on the Paste / CSV tab.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    final filtered = _filteredTrades;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _pickRange,
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(
                  '${dateFmt.format(_range.start)} – ${dateFmt.format(_range.end)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _busy || _loadingTrades ? null : _loadTrades,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _symbolFilterController,
          decoration: InputDecoration(
            hintText: 'Filter by symbol or trade ID',
            isDense: true,
            prefixIcon: const Icon(Icons.search, size: 18),
            border: OutlineInputBorder(borderRadius: AppRadii.card),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            TextButton(
              onPressed: filtered.isEmpty
                  ? null
                  : () => setState(() {
                        for (final t in filtered) {
                          if (t.tradeId.isNotEmpty) {
                            _selectedIds.add(t.tradeId);
                          }
                        }
                      }),
              child: const Text('Select all'),
            ),
            TextButton(
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () => setState(_selectedIds.clear),
              child: const Text('Clear'),
            ),
            const Spacer(),
            Text(
              '${_selectedIds.length} selected',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(child: _buildTradeList(theme, colors, filtered)),
      ],
    );
  }

  Widget _buildTradeList(
    ThemeData theme,
    AppColorsTheme colors,
    List<TradeHoldingViewModel> filtered,
  ) {
    if (_loadingTrades) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_loadError != null) {
      return Center(
        child: Text(
          'Could not load trades:\n$_loadError',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _trades.isEmpty
              ? 'No fills in this date range.'
              : 'No fills match the symbol filter.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
        borderRadius: AppRadii.card,
      ),
      child: ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: colors.border.withValues(alpha: 0.25),
        ),
        itemBuilder: (context, i) {
          final t = filtered[i];
          final id = t.tradeId;
          final checked = _selectedIds.contains(id);
          final pnl = t.profitLoss;
          final side = t.tradePositionType?.trim();
          final subtitle = [
            if (id.isNotEmpty) id,
            if (side != null && side.isNotEmpty) side,
            if (pnl != null) 'P&L ${pnl.toStringAsFixed(2)}',
          ].join(' · ');

          return CheckboxListTile(
            dense: true,
            value: checked,
            onChanged: id.isEmpty
                ? null
                : (v) {
                    setState(() {
                      if (v == true) {
                        _selectedIds.add(id);
                      } else {
                        _selectedIds.remove(id);
                      }
                    });
                  },
            title: Text(
              t.symbol.isNotEmpty ? t.symbol : id,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            activeColor: ModuleColors.trade,
            controlAffinity: ListTileControlAffinity.leading,
          );
        },
      ),
    );
  }

  Widget _buildPasteTab(ThemeData theme, AppColorsTheme colors) {
    final count = _pasteIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Paste trade IDs (comma or newline) or CSV with a tradeId column.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _pickCsvFile,
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('Choose CSV file'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _pasteController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: AppRadii.card),
              hintText: 'trade-id-1\ntrade-id-2\n\nor CSV:\ntradeId,symbol\nt-1,RELIANCE',
              alignLabelWithHint: true,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$count ID${count == 1 ? '' : 's'} parsed from paste',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
