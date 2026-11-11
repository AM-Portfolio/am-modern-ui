import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../../shared/widgets/market_async_error_view.dart';
import '../../providers/watchlist_provider.dart';
import '../../data/models/watchlist_model.dart';

class AddToWatchlistPopup extends ConsumerStatefulWidget {
  final String symbol;
  final String? sourceWatchlistId; // If provided, acts as 'Move' mode

  const AddToWatchlistPopup({
    super.key,
    required this.symbol,
    this.sourceWatchlistId,
  });

  static Future<bool?> show(BuildContext context, String symbol, {String? sourceWatchlistId}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AddToWatchlistPopup(symbol: symbol, sourceWatchlistId: sourceWatchlistId),
    );
  }

  @override
  ConsumerState<AddToWatchlistPopup> createState() => _AddToWatchlistPopupState();
}

class _AddToWatchlistPopupState extends ConsumerState<AddToWatchlistPopup> {
  String? _selectedWatchlistId;
  final TextEditingController _newWatchlistController = TextEditingController();
  bool _isCreatingNew = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _newWatchlistController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final notifier = ref.read(watchlistsProvider.notifier);
    setState(() => _isLoading = true);

    try {
      String? targetId = _selectedWatchlistId;
      
      // If creating a new one
      if (_isCreatingNew && _newWatchlistController.text.trim().isNotEmpty) {
        final client = ref.read(watchlistApiClientProvider);
        final newWatchlist = await client.createWatchlist(_newWatchlistController.text.trim());
        targetId = newWatchlist.id;
      }

      if (targetId == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (widget.sourceWatchlistId != null) {
        await notifier.moveStock(widget.sourceWatchlistId!, targetId, widget.symbol);
      } else {
        await notifier.addStock(targetId, widget.symbol);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ref.invalidate(watchlistCheckStatusProvider(widget.symbol));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${widget.symbol} to watchlist'),
            backgroundColor: context.colors.statusSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save to watchlist: $e'), backgroundColor: context.colors.statusError),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMoveMode = widget.sourceWatchlistId != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isMoveMode ? 'Move to Watchlist' : 'Add to Watchlist',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ModuleColors.market.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ModuleColors.market.withValues(alpha: 0.35)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.symbol.substring(0, min(2, widget.symbol.length)),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ModuleColors.market,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.symbol,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Choose a Watchlist',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _buildWatchlistSelector(),
              ),
              const SizedBox(height: 16),
              _buildCreateNewOption(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (_selectedWatchlistId != null || (_isCreatingNew && _newWatchlistController.text.trim().isNotEmpty)) && !_isLoading
                        ? _handleSave
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.actionPrimaryBg,
                      foregroundColor: colors.actionPrimaryFg,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.actionPrimaryFg,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;

  Widget _buildWatchlistSelector() {
    final watchlistsAsync = ref.watch(watchlistsProvider);
    final checkStatusAsync = ref.watch(watchlistCheckStatusProvider(widget.symbol));

    return watchlistsAsync.when(
      data: (watchlists) {
        if (watchlists.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No watchlists found. Create one below.',
              style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
            ),
          );
        }

        return checkStatusAsync.when(
          data: (statuses) {
            return ListView.builder(
              shrinkWrap: true,
              itemCount: watchlists.length,
              itemBuilder: (context, index) {
                final list = watchlists[index];
                final status = statuses.firstWhere(
                  (s) => s.watchlistId == list.id,
                  orElse: () => WatchlistCheckStatus(
                    watchlistId: list.id,
                    name: list.name,
                    containsSymbol: false,
                    itemCount: 0,
                  ),
                );

                final isAlreadyAdded =
                    status.containsSymbol && list.id != widget.sourceWatchlistId;

                return RadioListTile<String>(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          list.name,
                          style: TextStyle(
                            color: isAlreadyAdded
                                ? context.colors.textDisabled
                                : context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isAlreadyAdded) ...[
                        Text(
                          '(already added)',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textDisabled,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Remove from ${list.name}',
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: context.colors.statusError,
                          ),
                          onPressed: () async {
                            final confirm = await ConfirmationDialog.show(
                              context: context,
                              title: 'Remove Stock',
                              subtitle: 'Watchlist Management',
                              message:
                                  'Are you sure you want to remove ${widget.symbol} from ${list.name}?',
                              icon: Icons.star_rounded,
                              confirmText: 'Remove',
                              isDestructive: true,
                            );
                            if (confirm == true) {
                              await ref
                                  .read(watchlistsProvider.notifier)
                                  .removeStock(list.id, widget.symbol);
                              ref.invalidate(watchlistCheckStatusProvider(widget.symbol));
                            }
                          },
                        ),
                      ],
                      const SizedBox(width: 4),
                      Text(
                        '${status.itemCount} stocks',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  value: list.id,
                  groupValue: _selectedWatchlistId,
                  onChanged: isAlreadyAdded
                      ? null
                      : (val) {
                          setState(() {
                            _selectedWatchlistId = val;
                            _isCreatingNew = false;
                          });
                        },
                  contentPadding: EdgeInsets.zero,
                  activeColor: ModuleColors.market,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MarketAsyncErrorView(
            title: "Couldn't load status",
            error: e,
            onRetry: () => ref.invalidate(watchlistCheckStatusProvider(widget.symbol)),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => MarketAsyncErrorView(
        title: "Couldn't load watchlists",
        error: e,
        onRetry: () => ref.read(watchlistsProvider.notifier).refresh(),
      ),
    );
  }

  Widget _buildCreateNewOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RadioListTile<String>(
          value: '__new__',
          groupValue: _isCreatingNew ? '__new__' : _selectedWatchlistId,
          contentPadding: EdgeInsets.zero,
          activeColor: ModuleColors.market,
          title: Text(
            'Create New Watchlist',
            style: TextStyle(
              color: ModuleColors.market,
              fontWeight: FontWeight.w600,
            ),
          ),
          secondary: Icon(Icons.add_circle_outline, color: ModuleColors.market),
          onChanged: (_) {
            setState(() {
              _isCreatingNew = true;
              _selectedWatchlistId = null;
            });
          },
        ),
        if (_isCreatingNew) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _newWatchlistController,
            autofocus: true,
            style: TextStyle(color: context.colors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter watchlist name...',
              hintStyle: TextStyle(color: context.colors.textTertiary, fontSize: 14),
              filled: true,
              fillColor: context.colors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: ModuleColors.market),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) => setState(() {}),
          ),
        ],
      ],
    );
  }
}
