import '../../../../core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../providers/equity_insider_provider.dart';
import '../../../../features/watchlists/providers/watchlist_provider.dart';
import '../../../../features/watchlists/presentation/widgets/add_to_watchlist_popup.dart';
class EquityInsiderHero extends ConsumerWidget {
  final String symbol;
  final VoidCallback? onSearchTap;

  const EquityInsiderHero({
    super.key,
    required this.symbol,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(fundamentalProfileProvider(symbol));

    return asyncData.when(
      data: (data) {
        if (data == null) return const Text('No profile data');

        final isPos = (data.dayChangePercent ?? 0) >= 0;
        final deltaColor = isPos ? context.marketTheme.positive : context.marketTheme.negative;
        final arrow = isPos ? '▲' : '▼';
        final absChange = data.dayChange != null ? data.dayChange!.abs().toStringAsFixed(2) : '0.00';
        final pctChange = data.dayChangePercent != null ? data.dayChangePercent!.abs().toStringAsFixed(2) : '0.00';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLogo(context, data.companyName ?? data.symbol ?? symbol),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            data.symbol ?? symbol,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          _buildBadge(context, data.sector ?? 'NSE', isNeutral: true),
                          if (data.industry != null && data.industry!.isNotEmpty)
                            _buildBadge(context, data.industry!, isNeutral: true),
                          if (onSearchTap != null)
                            _buildSearchCapsule(context),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data.companyName ?? 'National Stock Exchange · Live',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_formatCurrency(data.currentPrice)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$arrow ₹$absChange ($pctChange%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: deltaColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildWatchlistButton(context, ref),
                  ],
                ),
              ],
            ),
            if (data.description != null && data.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ExpandableDescription(text: data.description!),
            ],
          ],
        );
      },
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (e, st) => Text('Error loading profile: $e', style: TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }

  Widget _buildLogo(BuildContext context, String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0].toUpperCase()).join()
        : 'EQ';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: ModuleColors.market.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ModuleColors.market.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ModuleColors.market,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSearchCapsule(BuildContext context) {
    return InkWell(
      onTap: onSearchTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ModuleColors.market.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 13,
              color: ModuleColors.market,
            ),
            const SizedBox(width: 5),
            Text(
              'Search stock...',
              style: TextStyle(
                color: context.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistButton(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(watchlistCheckStatusProvider(symbol));

    return statusAsync.when(
      data: (statuses) {
        final isAdded = statuses.any((s) => s.containsSymbol);
        final addedToWatchlistName = isAdded ? statuses.firstWhere((s) => s.containsSymbol).name : '';

        if (isAdded) {
          return SizedBox(
            height: 28,
            child: FilledButton.icon(
              onPressed: () async {
                // Check if they want to manage it
                final confirm = await ConfirmationDialog.show(
                  context: context,
                  title: 'Remove Stock',
                  subtitle: 'Watchlist Management',
                  message: 'Are you sure you want to remove $symbol from $addedToWatchlistName?',
                  icon: Icons.bookmark_remove_rounded,
                  confirmText: 'Remove',
                  isDestructive: true,
                );
                if (confirm) {
                  final wid = statuses.firstWhere((s) => s.containsSymbol).watchlistId;
                  ref.read(watchlistsProvider.notifier).removeStock(wid, symbol);
                  ref.refresh(watchlistCheckStatusProvider(symbol));
                }
              },
              icon: const Icon(Icons.bookmark_added_rounded, size: 14, color: Colors.white),
              label: const Text(
                'Already Added',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: ModuleColors.market,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 28,
          child: OutlinedButton.icon(
            onPressed: () {
              AddToWatchlistPopup.show(context, symbol);
            },
            icon: Icon(Icons.add, size: 14, color: ModuleColors.market),
            label: Text(
              'Add to Watchlist',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ModuleColors.market,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              side: BorderSide(
                color: ModuleColors.market.withValues(alpha: 0.4),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 28, width: 100, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatCurrency(num? val) {
    if (val == null) return '---';
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(val);
  }


  Widget _buildBadge(BuildContext context, String text, {bool isPos = false, bool isNeg = false, bool isNeutral = false}) {
    Color bg;
    Color fg;
    if (isPos) {
      fg = context.marketTheme.positive;
      bg = fg.withValues(alpha: 0.10);
    } else if (isNeg) {
      fg = context.marketTheme.negative;
      bg = fg.withValues(alpha: 0.10);
    } else {
      fg = context.marketTheme.textMuted;
      bg = fg.withValues(alpha: 0.15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String text;

  const _ExpandableDescription({required this.text});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = TextStyle(
          fontSize: 12,
          color: context.textSecondary,
          height: 1.45,
        );

        final textSpan = TextSpan(
          text: widget.text,
          style: textStyle,
        );

        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 2,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        if (!isOverflowing) {
          return Text(
            widget.text,
            style: textStyle,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              firstChild: Text(
                widget.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
              secondChild: Text(
                widget.text,
                style: textStyle,
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            const SizedBox(height: 4),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Show less' : 'See more',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.marketTheme.chartBlue,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: context.marketTheme.chartBlue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

