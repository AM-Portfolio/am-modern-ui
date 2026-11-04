import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../journal_providers.dart';
import '../../../journal/utils/journal_this_trade.dart';
import '../../../models/trade_holding_view_model.dart';

/// Narrow-viewport trade detail header (stacked; no horizontal overflow).
class MobileTradeDetailHeader extends ConsumerStatefulWidget {
  const MobileTradeDetailHeader({
    required this.trade,
    required this.portfolioId,
    this.onClose,
    this.onSymbolTap,
    super.key,
  });

  final TradeHoldingViewModel trade;
  final String portfolioId;
  final VoidCallback? onClose;
  final Function(String symbol)? onSymbolTap;

  @override
  ConsumerState<MobileTradeDetailHeader> createState() =>
      _MobileTradeDetailHeaderState();
}

class _MobileTradeDetailHeaderState
    extends ConsumerState<MobileTradeDetailHeader> {
  var _journaling = false;

  Future<void> _journalThis() async {
    if (_journaling) return;
    setState(() => _journaling = true);
    try {
      final cubit = await ref.read(journalCubitProvider.future);
      if (!mounted) return;
      await openJournalThisTrade(
        context,
        cubit: cubit,
        tradeId: widget.trade.tradeId,
        portfolioId: widget.portfolioId,
        holding: widget.trade,
      );
    } finally {
      if (mounted) setState(() => _journaling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trade = widget.trade;
    final position = (trade.tradePositionType ?? 'LONG').toLowerCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: context.shadow(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
                borderRadius: AppRadii.button,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.border),
                    borderRadius: AppRadii.button,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: widget.onSymbolTap != null
                          ? () => widget.onSymbolTap!(trade.displaySymbol)
                          : null,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              trade.displaySymbol,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _StatusChip(
                            label: trade.displayStatus.toUpperCase(),
                          ),
                        ],
                      ),
                    ),
                    if (trade.hasDistinctCompanyName) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        trade.displayCompanyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.textSecondary,
                              fontSize: AppTypeScale.sm,
                            ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs + 2,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        _OutlineChip(
                          label: _titleCase(position),
                          color: colors.statusError,
                        ),
                        _OutlineChip(
                          label: 'Equity',
                          color: colors.statusInfo,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppButton(
                text: _journaling ? '…' : 'Journal',
                icon: Icons.menu_book_outlined,
                isOutlined: true,
                textColor: ModuleColors.trade,
                height: 36,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.xs,
                ),
                onPressed: _journaling ? null : _journalThis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.statusSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: AppTypeScale.xs,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.1,
            ),
      ),
    );
  }
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        color: color.withValues(alpha: 0.05),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: AppTypeScale.xs + 1,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.1,
            ),
      ),
    );
  }
}
