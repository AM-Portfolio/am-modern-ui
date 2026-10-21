import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/features/equity_insider/providers/equity_insider_provider.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/watchlists/presentation/widgets/market_watchlist_star.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Compact Equity Insider identity strip matching the premium header mock.
class EquityInsiderHeaderCard extends ConsumerWidget {
  const EquityInsiderHeaderCard({
    required this.symbol,
    required this.companyName,
    this.currentPrice,
    this.dayChange,
    this.dayChangePercent,
    super.key,
  });

  final String symbol;
  final String companyName;
  final num? currentPrice;
  final num? dayChange;
  final num? dayChangePercent;

  static final NumberFormat _inr = NumberFormat('#,##,##0.00', 'en_IN');

  /// Mobile sticky pin: measured GlassCard at 390 plus [AppSpacing.xs] on each edge.
  static const double mobileStickyPinExtent = 128;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = MediaQuery.sizeOf(context).width < AmBreakpoints.mobile;
    final logoSize = isCompact ? 40.0 : 44.0;
    final changeLabel = _changeLabel();
    final isPos = (dayChangePercent ?? dayChange ?? 0) >= 0;
    final deltaColor = isPos
        ? MarketColors.positive(context)
        : MarketColors.negative(context);
    final ltpText =
        currentPrice == null ? '—' : '₹${_inr.format(currentPrice)}';

    return Align(
      alignment: Alignment.topCenter,
      child: GlassCard(
        padding: EdgeInsets.all(isCompact ? AppSpacing.sm : AppSpacing.md),
        borderRadius: AppRadii.md,
        child: isCompact
            ? _buildMobile(
                context: context,
                logoSize: logoSize,
                ltpText: ltpText,
                changeLabel: changeLabel,
                isPos: isPos,
                deltaColor: deltaColor,
                ref: ref,
              )
            : _buildDesktop(
                context: context,
                logoSize: logoSize,
                ltpText: ltpText,
                changeLabel: changeLabel,
                isPos: isPos,
                deltaColor: deltaColor,
                ref: ref,
              ),
      ),
    );
  }

  Widget _nameText(BuildContext context, {required bool compact}) {
    final style = (compact
            ? context.text.sectionTitle(compact: true)
            : context.text.pageTitle(compact: true))
        .copyWith(
      color: context.textPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
    return Text(
      companyName,
      key: const Key('ei-header-name'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  Widget _priceRow(
    BuildContext context, {
    required String ltpText,
    required String? changeLabel,
    required bool isPos,
    required Color deltaColor,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            ltpText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.pageTitle(compact: true).copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (changeLabel != null) ...[
            SizedBox(width: AppSpacing.sm),
            Icon(
              isPos ? Icons.arrow_upward : Icons.arrow_downward,
              size: AppTypeScale.sm,
              color: deltaColor,
            ),
            SizedBox(width: AppSpacing.xxs),
            Text(
              changeLabel,
              style: context.text.label(compact: true).copyWith(
                    color: deltaColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceCluster(
    BuildContext context, {
    required String ltpText,
    required String? changeLabel,
    required bool isPos,
    required Color deltaColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ltpText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.pageTitle(compact: true).copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (changeLabel != null) ...[
          SizedBox(height: AppSpacing.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPos ? Icons.arrow_upward : Icons.arrow_downward,
                size: AppTypeScale.sm,
                color: deltaColor,
              ),
              SizedBox(width: AppSpacing.xxs),
              Text(
                changeLabel,
                style: context.text.label(compact: true).copyWith(
                      color: deltaColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMobile({
    required BuildContext context,
    required double logoSize,
    required String ltpText,
    required String? changeLabel,
    required bool isPos,
    required Color deltaColor,
    required WidgetRef ref,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InitialsLogo(name: companyName, size: logoSize),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _nameText(context, compact: true)),
                  MarketWatchlistStar(symbol: symbol),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              _ExchangeChips(ref: ref),
              SizedBox(height: AppSpacing.xs),
              _priceRow(
                context,
                ltpText: ltpText,
                changeLabel: changeLabel,
                isPos: isPos,
                deltaColor: deltaColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktop({
    required BuildContext context,
    required double logoSize,
    required String ltpText,
    required String? changeLabel,
    required bool isPos,
    required Color deltaColor,
    required WidgetRef ref,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InitialsLogo(name: companyName, size: logoSize),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Row(
            children: [
              Flexible(child: _nameText(context, compact: false)),
              SizedBox(width: AppSpacing.sm),
              _ExchangeChips(ref: ref),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        _priceCluster(
          context,
          ltpText: ltpText,
          changeLabel: changeLabel,
          isPos: isPos,
          deltaColor: deltaColor,
        ),
        SizedBox(width: AppSpacing.xs),
        MarketWatchlistStar(symbol: symbol),
      ],
    );
  }

  String? _changeLabel() {
    if (dayChange == null && dayChangePercent == null) return null;
    final ch = dayChange;
    final pct = dayChangePercent;
    final chStr = ch == null
        ? null
        : '${ch >= 0 ? '+' : ''}${ch.toStringAsFixed(2)}';
    final pctStr = pct == null
        ? null
        : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%';
    if (chStr != null && pctStr != null) return '$chStr ($pctStr)';
    return chStr ?? pctStr;
  }
}

class _ExchangeChips extends StatelessWidget {
  const _ExchangeChips({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(selectedExchangeProvider);
    final radius = BorderRadius.circular(AppRadii.xs);
    final pad = EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xxs,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AmToggleChip(
            label: 'NSE',
            selected: active == 'NSE',
            compact: true,
            accentColor: ModuleColors.market,
            borderRadius: radius,
            contentPadding: pad,
            onTap: () =>
                ref.read(selectedExchangeProvider.notifier).setExchange('NSE'),
          ),
          SizedBox(width: AppSpacing.xs),
          AmToggleChip(
            label: 'BSE',
            selected: active == 'BSE',
            compact: true,
            accentColor: context.colors.statusWarning,
            borderRadius: radius,
            contentPadding: pad,
            onTap: () =>
                ref.read(selectedExchangeProvider.notifier).setExchange('BSE'),
          ),
        ],
      ),
    );
  }
}

class _InitialsLogo extends StatelessWidget {
  const _InitialsLogo({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((e) => e[0].toUpperCase())
            .join()
        : 'EQ';
    final accent = ModuleColors.market;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: accent.withValues(alpha: 0.45),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: context.text.label(compact: true).copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
