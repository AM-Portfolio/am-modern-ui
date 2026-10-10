import '../../../../core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../providers/equity_insider_provider.dart';
import '../../../../features/watchlists/providers/watchlist_provider.dart';
import '../../../../features/watchlists/presentation/widgets/add_to_watchlist_popup.dart';

/// Full hero (bar + description). Prefer [EquityInsiderHeroBar] /
/// [EquityInsiderHeroDescription] when the bar is pinned separately.
class EquityInsiderHero extends ConsumerWidget {
  final String symbol;

  const EquityInsiderHero({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EquityInsiderHeroBar(symbol: symbol),
        EquityInsiderHeroDescription(symbol: symbol),
      ],
    );
  }
}

/// Sticky identity strip: logo, symbol, price (compact on mobile).
class EquityInsiderHeroBar extends ConsumerWidget {
  final String symbol;
  final VoidCallback? onBack;

  const EquityInsiderHeroBar({
    super.key,
    required this.symbol,
    this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeExchange = ref.watch(selectedExchangeProvider);
    final asyncData = ref.watch(fundamentalProfileProvider(
      EquityFundamentalQuery(symbol: symbol, exchange: activeExchange),
    ));

    return asyncData.when(
      data: (data) {
        if (data == null) return const Text('No profile data');

        final isPos = (data.dayChangePercent ?? 0) >= 0;
        final deltaColor =
            isPos ? context.marketTheme.positive : context.marketTheme.negative;
        final arrow = isPos ? '▲' : '▼';
        final signedChange = data.dayChange != null
            ? '${data.dayChange! >= 0 ? '+' : ''}${data.dayChange!.toStringAsFixed(2)}'
            : '+0.00';
        final signedPct = data.dayChangePercent != null
            ? '${data.dayChangePercent! >= 0 ? '+' : ''}${data.dayChangePercent!.toStringAsFixed(2)}'
            : '+0.00';
        final companyName = data.companyName ?? data.symbol ?? symbol;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < AmBreakpoints.mobile;
            final isMobileShell = constraints.maxWidth < 800;
            final logoSize = isCompact ? 36.0 : (isMobileShell ? 36.0 : 44.0);

            if (isMobileShell) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (onBack != null) ...[
                        IconButton(
                          onPressed: onBack,
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: context.textPrimary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                      _buildLogo(context, companyName, size: logoSize),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              companyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isCompact ? 15 : 16,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                                letterSpacing: -0.3,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            _buildCompactExchangeChips(context, ref),
                          ],
                        ),
                      ),
                      _buildWatchlistStar(context, ref, symbol),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          '₹${_formatCurrency(data.currentPrice)}',
                          style: TextStyle(
                            fontSize: isCompact ? 18 : 20,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isPos ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: deltaColor,
                        ),
                        Text(
                          '$signedChange ($signedPct%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: deltaColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final exchangeBadgeColor = activeExchange == 'BSE'
                ? context.colors.statusWarning
                : context.marketTheme.chartBlue;
            final absChange = data.dayChange != null
                ? data.dayChange!.abs().toStringAsFixed(2)
                : '0.00';
            final pctChange = data.dayChangePercent != null
                ? data.dayChangePercent!.abs().toStringAsFixed(2)
                : '0.00';

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLogo(context, companyName, size: logoSize),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          _buildBadge(
                            context,
                            activeExchange,
                            customColor: exchangeBadgeColor,
                          ),
                          if (data.sector != null && data.sector!.isNotEmpty)
                            _buildBadge(context, data.sector!, isNeutral: true),
                          if (data.industry != null && data.industry!.isNotEmpty)
                            _buildBadge(
                              context,
                              data.industry!,
                              isNeutral: true,
                            ),
                          _buildExchangeToggle(context, ref),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$companyName · ${activeExchange == 'BSE' ? 'Bombay Stock Exchange' : 'National Stock Exchange'} · Live',
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${_formatCurrency(data.currentPrice)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '$arrow ₹$absChange ($pctChange%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: deltaColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildWatchlistButton(context, ref, symbol),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Text(
        'Error loading profile: $e',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget _buildCompactExchangeChips(BuildContext context, WidgetRef ref) {
    final activeExchange = ref.watch(selectedExchangeProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _compactChip(
          context,
          label: 'NSE',
          selected: activeExchange == 'NSE',
          color: context.marketTheme.chartBlue,
          onTap: () =>
              ref.read(selectedExchangeProvider.notifier).setExchange('NSE'),
        ),
        const SizedBox(width: 4),
        _compactChip(
          context,
          label: 'BSE',
          selected: activeExchange == 'BSE',
          color: context.colors.statusWarning,
          onTap: () =>
              ref.read(selectedExchangeProvider.notifier).setExchange('BSE'),
        ),
      ],
    );
  }

  Widget _compactChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.7)
                : context.colors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? color : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildWatchlistStar(
    BuildContext context,
    WidgetRef ref,
    String symbol,
  ) {
    final statusAsync = ref.watch(watchlistCheckStatusProvider(symbol));
    return statusAsync.when(
      data: (statuses) {
        final isAdded = statuses.any((s) => s.containsSymbol);
        return IconButton(
          tooltip: isAdded ? 'Remove from watchlist' : 'Add to watchlist',
          onPressed: () async {
            if (isAdded) {
              final name =
                  statuses.firstWhere((s) => s.containsSymbol).name;
              final confirm = await ConfirmationDialog.show(
                context: context,
                title: 'Remove Stock',
                subtitle: 'Watchlist Management',
                message:
                    'Are you sure you want to remove $symbol from $name?',
                icon: Icons.star_rounded,
                confirmText: 'Remove',
                isDestructive: true,
              );
              if (confirm) {
                final wid =
                    statuses.firstWhere((s) => s.containsSymbol).watchlistId;
                ref.read(watchlistsProvider.notifier).removeStock(wid, symbol);
                ref.invalidate(watchlistCheckStatusProvider(symbol));
              }
            } else {
              AddToWatchlistPopup.show(context, symbol);
            }
          },
          icon: Icon(
            isAdded ? Icons.star_rounded : Icons.star_border_rounded,
            size: 22,
            color: isAdded ? ModuleColors.market : context.textSecondary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        );
      },
      loading: () => const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox(width: 40, height: 40),
    );
  }

  Widget _buildExchangeToggle(BuildContext context, WidgetRef ref) {
    final activeExchange = ref.watch(selectedExchangeProvider);
    final isBse = activeExchange == 'BSE';

    return Container(
      height: 26,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBse
              ? context.colors.statusWarning.withValues(alpha: 0.5)
              : context.marketTheme.chartBlue.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleSegment(
            context,
            ref,
            label: 'NSE',
            isSelected: !isBse,
            activeColor: context.marketTheme.chartBlue,
          ),
          _buildToggleSegment(
            context,
            ref,
            label: 'BSE',
            isSelected: isBse,
            activeColor: context.colors.statusWarning,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSegment(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required bool isSelected,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          ref.read(selectedExchangeProvider.notifier).setExchange(label);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeColor : context.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, String name, {double size = 44}) {
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((e) => e[0].toUpperCase())
            .join()
        : 'EQ';

    return Container(
      width: size,
      height: size,
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
          fontSize: size >= 44 ? 16 : 13,
          fontWeight: FontWeight.w700,
          color: ModuleColors.market,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatCurrency(num? val) {
    if (val == null) return '---';
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(val);
  }

  Widget _buildBadge(
    BuildContext context,
    String text, {
    bool isPos = false,
    bool isNeg = false,
    bool isNeutral = false,
    Color? customColor,
  }) {
    Color bg;
    Color fg;
    if (customColor != null) {
      fg = customColor;
      bg = fg.withValues(alpha: 0.15);
    } else if (isPos) {
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

/// Watchlist CTA shared by desktop sticky bar and mobile scroll block.
Widget _buildWatchlistButton(
  BuildContext context,
  WidgetRef ref,
  String symbol, {
  bool compact = false,
}) {
  final statusAsync = ref.watch(watchlistCheckStatusProvider(symbol));

  return statusAsync.when(
    data: (statuses) {
      final isAdded = statuses.any((s) => s.containsSymbol);
      final addedToWatchlistName =
          isAdded ? statuses.firstWhere((s) => s.containsSymbol).name : '';

        if (isAdded) {
          final onPrimary = context.colors.actionPrimaryFg;
          return SizedBox(
            height: 28,
            child: FilledButton.icon(
              onPressed: () async {
                final confirm = await ConfirmationDialog.show(
                  context: context,
                  title: 'Remove Stock',
                  subtitle: 'Watchlist Management',
                  message:
                      'Are you sure you want to remove $symbol from $addedToWatchlistName?',
                  icon: Icons.bookmark_remove_rounded,
                  confirmText: 'Remove',
                  isDestructive: true,
                );
                if (confirm) {
                  final wid =
                      statuses.firstWhere((s) => s.containsSymbol).watchlistId;
                  ref.read(watchlistsProvider.notifier).removeStock(wid, symbol);
                  ref.invalidate(watchlistCheckStatusProvider(symbol));
                }
              },
              icon: Icon(
                Icons.bookmark_added_rounded,
                size: 14,
                color: onPrimary,
              ),
              label: Text(
                compact ? 'Added' : 'Already Added',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: onPrimary,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: ModuleColors.market,
                foregroundColor: onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            compact ? 'Watchlist' : 'Add to Watchlist',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ModuleColors.market,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    loading: () => const SizedBox(
      height: 28,
      width: 100,
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (_, __) => const SizedBox.shrink(),
  );
}

/// Company description + mobile exchange/watchlist actions (scrolls under pin).
class EquityInsiderHeroDescription extends ConsumerWidget {
  final String symbol;

  const EquityInsiderHeroDescription({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeExchange = ref.watch(selectedExchangeProvider);
    final asyncData = ref.watch(fundamentalProfileProvider(
      EquityFundamentalQuery(symbol: symbol, exchange: activeExchange),
    ));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return asyncData.when(
          data: (data) {
            final description = data?.description;
            final hasDescription =
                description != null && description.isNotEmpty;

            final sector = data?.sector;
            final industry = data?.industry;
            final hasSector = sector != null && sector.isNotEmpty;
            final hasIndustry = industry != null && industry.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mobile: exchange + watchlist live in sticky hero — keep only light meta.
                if (isMobile && (hasSector || hasIndustry))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (hasSector) _MobileMetaBadge(text: sector),
                        if (hasIndustry) _MobileMetaBadge(text: industry),
                      ],
                    ),
                  ),
                if (hasDescription)
                  Padding(
                    padding: EdgeInsets.only(top: isMobile ? 6 : 12),
                    child: _ExpandableDescription(
                      text: description,
                      collapsedLines: isMobile ? 2 : 2,
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _MobileMetaBadge extends StatelessWidget {
  const _MobileMetaBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final fg = context.marketTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.15),
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
  final int collapsedLines;

  const _ExpandableDescription({
    required this.text,
    this.collapsedLines = 2,
  });

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.market;
    final textStyle = TextStyle(
      fontSize: 12,
      color: context.textSecondary,
      height: 1.45,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: textStyle),
          maxLines: widget.collapsedLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;
        if (!isOverflowing) {
          return Text(widget.text, style: textStyle);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                maxLines: _isExpanded ? null : widget.collapsedLines,
                overflow:
                    _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Show less' : 'See more',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: accent,
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
