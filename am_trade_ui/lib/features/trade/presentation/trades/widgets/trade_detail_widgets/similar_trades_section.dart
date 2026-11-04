import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/trade_internal_providers.dart';
import '../../../holdings/components/trade_holdings_advanced_template.dart';
import '../../../models/trade_holding_view_model.dart';

class SimilarTradesSection extends ConsumerStatefulWidget {
  const SimilarTradesSection({
    required this.trade,
    required this.portfolioId,
    this.symbolFilter,
    this.onSymbolFilterChanged,
    this.compact = false,
    super.key,
  });

  final TradeHoldingViewModel trade;
  final String portfolioId;
  final String? symbolFilter;
  final ValueChanged<String?>? onSymbolFilterChanged;

  /// Narrow layout: fewer table columns.
  final bool compact;

  @override
  ConsumerState<SimilarTradesSection> createState() =>
      _SimilarTradesSectionState();
}

class _SimilarTradesSectionState extends ConsumerState<SimilarTradesSection> {
  late String _selectedSymbol;

  @override
  void initState() {
    super.initState();
    _selectedSymbol =
        (widget.symbolFilter?.trim().isNotEmpty ?? false)
            ? widget.symbolFilter!.trim().toUpperCase()
            : widget.trade.symbol.toUpperCase();
  }

  @override
  void didUpdateWidget(covariant SimilarTradesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.symbolFilter?.trim();
    if (incoming != null &&
        incoming.isNotEmpty &&
        incoming.toUpperCase() != _selectedSymbol) {
      _selectedSymbol = incoming.toUpperCase();
    }
  }

  void _onSymbolSelected(String symbol) {
    final next = symbol.trim().toUpperCase();
    if (next == _selectedSymbol) return;
    setState(() => _selectedSymbol = next);
    widget.onSymbolFilterChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final holdingsAsync =
        ref.watch(tradeHoldingsStreamProvider(widget.portfolioId));
    final colors = context.colors;
    final accent = ModuleColors.trade;

    return holdingsAsync.when(
      data: (tradeHoldings) {
        final symbols = tradeHoldings.holdings
            .map((h) => h.symbol.toUpperCase())
            .toSet()
            .toList()
          ..sort();
        if (!symbols.contains(_selectedSymbol)) {
          symbols.insert(0, _selectedSymbol);
        }

        final similarTrades = tradeHoldings.holdings
            .where((h) => h.symbol.toUpperCase() == _selectedSymbol)
            .toList();

        if (similarTrades.isEmpty) {
          return _buildEmptyState(context, _selectedSymbol);
        }

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadii.card,
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: context.shadow(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(
                context,
                count: similarTrades.length,
                symbols: symbols,
                accent: accent,
              ),
              SizedBox(
                height: widget.compact ? 280 : 320,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadii.lg),
                    bottomRight: Radius.circular(AppRadii.lg),
                  ),
                  child: TradeHoldingsAdvancedTemplate(
                    holdings: similarTrades,
                    isLoading: false,
                    itemsPerPage: 10,
                    showSearch: false,
                    compact: widget.compact,
                    onEditTrade: widget.compact
                        ? null
                        : (holding) {
                            OpenAddTradeNotification(
                              portfolioId: widget.portfolioId,
                              existingTrade: holding,
                            ).dispatch(context);
                          },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(color: ModuleColors.trade),
        ),
      ),
      error: (error, _) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required int count,
    required List<String> symbols,
    required Color accent,
  }) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal:
            widget.compact ? AppSpacing.sm + AppSpacing.xs : AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.08),
            accent.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadii.lg),
          topRight: Radius.circular(AppRadii.lg),
        ),
        border: Border(
          bottom: BorderSide(color: colors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm - 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: AppRadii.button,
            ),
            child: Icon(Icons.history, size: 16, color: accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'Similar Trades',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: AppTypeScale.md,
                    color: colors.textPrimary,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: AppRadii.chip,
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
            ),
          ),
          const Spacer(),
          _SymbolFilterChip(
            selected: _selectedSymbol,
            symbols: symbols,
            accent: accent,
            onSelected: _onSymbolSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String symbol) {
    final colors = context.colors;
    final muted = context.textSecondary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: colors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No trades found for symbol: $symbol',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: muted,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try searching for a different symbol',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.statusError),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error loading similar trades',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.statusError,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SymbolFilterChip extends StatelessWidget {
  const _SymbolFilterChip({
    required this.selected,
    required this.symbols,
    required this.accent,
    required this.onSelected,
  });

  final String selected;
  final List<String> symbols;
  final Color accent;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopupMenuButton<String>(
      tooltip: 'Filter by symbol',
      onSelected: onSelected,
      offset: const Offset(0, 36),
      color: colors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.button,
        side: BorderSide(color: colors.border.withValues(alpha: 0.45)),
      ),
      itemBuilder: (_) => [
        for (final symbol in symbols)
          PopupMenuItem<String>(
            value: symbol,
            child: Text(
              symbol,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        symbol == selected ? FontWeight.w700 : FontWeight.w500,
                    color: symbol == selected ? accent : colors.textPrimary,
                  ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.sm - 2),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt, size: 12, color: accent),
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Text(
                selected,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Icon(Icons.keyboard_arrow_down, size: 14, color: accent),
          ],
        ),
      ),
    );
  }
}
