import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart';

class EquityInsiderHero extends StatelessWidget {
  final FundamentalRatiosResponse data;

  const EquityInsiderHero({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 450;
          
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeft(context),
                const SizedBox(height: 16),
                _buildRight(context),
              ],
            );
          }
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildLeft(context)),
              _buildRight(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeft(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.symbol ?? '---',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: context.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${data.sector ?? 'Unknown Sector'} · NSE',
          style: TextStyle(
            fontSize: 10,
            color: context.textSecondary,
            textBaseline: TextBaseline.alphabetic,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _buildBadges(context),
        ),
      ],
    );
  }

  Widget _buildRight(BuildContext context) {
    final priceStr = data.currentPrice != null
        ? '₹${data.currentPrice!.toStringAsFixed(2)}'
        : '₹---';

    final changeStr = data.dayChange != null
        ? '${data.dayChange! >= 0 ? '+' : ''}${data.dayChange!.toStringAsFixed(2)} today'
        : '--- today';

    final isPositive = (data.dayChange ?? 0) >= 0;
    final changeColor = isPositive ? const Color(0xFF00C896) : const Color(0xFFF87171);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          priceStr,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: context.textPrimary,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          changeStr,
          style: TextStyle(
            fontSize: 12,
            color: changeColor,
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
    );
  }

  List<Widget> _buildBadges(BuildContext context) {
    final badges = <Widget>[];

    // Day change badge
    if (data.dayChangePercent != null) {
      final isPos = data.dayChangePercent! >= 0;
      final sign = isPos ? '↑ +' : '↓ ';
      badges.add(_Badge(
        text: '$sign${data.dayChangePercent!.toStringAsFixed(2)}% today',
        isPositive: isPos,
        isNegative: !isPos,
      ));
    }

    // Market cap category (Mocked as Large Cap for now since we don't have the exact classification, or we can use sectorMarketCapInr)
    badges.add(const _Badge(
      text: 'Equity',
    ));

    // ROE badge
    if (data.roe != null) {
      final roeStr = 'ROE ${data.roe!.toStringAsFixed(1)}%';
      final isStrong = data.roe! > 15;
      badges.add(_Badge(
        text: roeStr,
        isPositive: isStrong,
      ));
    }

    return badges;
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool isPositive;
  final bool isNegative;

  const _Badge({
    required this.text,
    this.isPositive = false,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (isPositive) {
      fg = const Color(0xFF00C896);
      bg = fg.withOpacity(0.1);
    } else if (isNegative) {
      fg = const Color(0xFFF87171);
      bg = fg.withOpacity(0.1);
    } else {
      fg = context.textSecondary;
      bg = fg.withOpacity(0.15);
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
