import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../providers/watchlist_provider.dart';
import '../../data/models/watchlist_model.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';

class AddToWatchlistPopup extends ConsumerStatefulWidget {
  final String symbol;
  final String? sourceWatchlistId; // If provided, acts as 'Move' mode

  const AddToWatchlistPopup({
    super.key,
    required this.symbol,
    this.sourceWatchlistId,
  });

  static Future<void> show(BuildContext context, String symbol, {String? sourceWatchlistId}) {
    return showDialog(
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
        Navigator.of(context).pop();
        ref.invalidate(watchlistCheckStatusProvider(widget.symbol));
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose a Watchlist',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (_selectedWatchlistId != null || (_isCreatingNew && _newWatchlistController.text.trim().isNotEmpty)) && !_isLoading
                        ? _handleSave
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.actionPrimaryBg,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
          return const Text('No watchlists found. Create one below.');
        }

        return checkStatusAsync.when(
          data: (statuses) {
            return ListView.builder(
              shrinkWrap: true,
              itemCount: watchlists.length,
              itemBuilder: (context, index) {
                final list = watchlists[index];
                final status = statuses.firstWhere((s) => s.watchlistId == list.id, orElse: () => WatchlistCheckStatus(watchlistId: list.id, name: list.name, containsSymbol: false, itemCount: 0));
                
                final isAlreadyAdded = status.containsSymbol && list.id != widget.sourceWatchlistId;

                return RadioListTile<String>(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          list.name,
                          style: TextStyle(
                            color: isAlreadyAdded ? context.colors.textDisabled : context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isAlreadyAdded)
                        Text(
                          '(already added)',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textDisabled,
                          ),
                        ),
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
          error: (_, __) => const Text('Error loading status'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading watchlists'),
    );
  }

  Widget _buildCreateNewOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.add_box_rounded, color: ModuleColors.market),
          title: Text(
            'Create New Watchlist',
            style: TextStyle(
              color: ModuleColors.market,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            setState(() {
              _isCreatingNew = true;
              _selectedWatchlistId = null;
            });
          },
        ),
        if (_isCreatingNew)
          TextField(
            controller: _newWatchlistController,
            decoration: InputDecoration(
              hintText: 'Enter watchlist name...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) => setState(() {}),
          ),
      ],
    );
  }
}
