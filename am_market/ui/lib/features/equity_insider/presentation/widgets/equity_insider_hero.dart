import '../../../../core/styles/market_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../providers/equity_insider_provider.dart';

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
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Text(
                            data.symbol ?? symbol,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          _buildBadge(context, data.sector ?? 'NSE', isNeutral: true),
                          if (onSearchTap != null)
                            InkWell(
                              onTap: onSearchTap,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: context.cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: context.borderColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      size: 14,
                                      color: context.colors.actionPrimaryBg,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Search stock...',
                                      style: TextStyle(
                                        color: context.textTertiary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.companyName ?? 'National Stock Exchange · Live',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_formatCurrency(data.currentPrice)}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: context.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.dayChangePercent != null && data.dayChangePercent! >= 0 ? '+' : ''}${_formatNum(data.dayChange)} today',
                      style: TextStyle(
                        fontSize: 12,
                        color: data.dayChangePercent != null && data.dayChangePercent! >= 0
                            ? context.marketTheme.positive
                            : context.marketTheme.negative,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NSE · Live',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (data.description != null && data.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ExpandableDescription(text: data.description!),
            ],
            const SizedBox(height: 16),
            Container(height: 1, color: context.borderColor),
          ],
        );
      },
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (e, st) => Text('Error loading profile: $e', style: TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }

  String _formatCurrency(num? val) {
    if (val == null) return '---';
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(val);
  }

  String _formatNum(num? val) {
    if (val == null) return '---';
    return val.toStringAsFixed(2);
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
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

