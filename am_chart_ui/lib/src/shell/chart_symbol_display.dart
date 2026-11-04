import 'package:flutter/material.dart';

/// Display helpers for chart pane symbols (esp. `PORTFOLIO:<id>|Name`).
abstract final class ChartSymbolDisplay {
  static bool isPortfolioSymbol(String symbol) {
    final u = symbol.trim().toUpperCase();
    return u.startsWith('PORTFOLIO:') ||
        u == 'OVERALL' ||
        u == 'OVERALL - NSE' ||
        u == 'OVERALL - BSE';
  }

  /// Human title: portfolio name / Overall / raw symbol (never PORTFOLIO:uuid).
  static String title(String symbol) {
    final s = symbol.trim();
    final u = s.toUpperCase();
    if (u == 'OVERALL' ||
        u == 'OVERALL - NSE' ||
        u == 'OVERALL - BSE' ||
        s.toLowerCase() == 'overall') {
      return 'Overall';
    }
    if (u.startsWith('PORTFOLIO:')) {
      final rest = s.substring('PORTFOLIO:'.length);
      final parts = rest.split('|');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        return parts[1].trim();
      }
      return 'Portfolio';
    }
    return s;
  }

  /// Infer broker key from portfolio display name for logo lookup.
  static String? brokerKeyFromTitle(String title) {
    final t = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (t.contains('zerodha') || t.contains('kite')) return 'zerodha';
    if (t.contains('dhan')) return 'dhan';
    if (t.contains('groww')) return 'groww';
    if (t.contains('angel')) return 'angelone';
    if (t.contains('upstox')) return 'upstox';
    if (t.contains('kotak')) return 'kotak';
    if (t.contains('mstock') || t.contains('mirae')) return 'mstock';
    return null;
  }

  static String? brokerLogoAsset(String? brokerKey) {
    switch (brokerKey) {
      case 'zerodha':
        return 'assets/images/brokers/zerodha.png';
      case 'dhan':
        return 'assets/images/brokers/dhan.png';
      case 'groww':
        return 'assets/images/brokers/groww.png';
      case 'angelone':
        return 'assets/images/brokers/angelone.png';
      case 'upstox':
        return 'assets/images/brokers/upstox.png';
      case 'kotak':
        return 'assets/images/brokers/kotak.png';
      case 'mstock':
        return 'assets/images/brokers/mstock.png';
      default:
        return null;
    }
  }

  /// Logo chip + title for portfolio / overall; plain text for market symbols.
  static Widget titleRow(
    BuildContext context,
    String symbol, {
    double logoSize = 18,
    TextStyle? style,
  }) {
    final theme = Theme.of(context);
    final label = title(symbol);
    final portfolio = isPortfolioSymbol(symbol);
    final textStyle = style ??
        TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.onSurface,
          letterSpacing: -0.2,
        );

    if (!portfolio) {
      return Text(label.toUpperCase(), style: textStyle);
    }

    final broker = brokerKeyFromTitle(label);
    final asset = brokerLogoAsset(broker);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PortfolioLogoChip(
          size: logoSize,
          assetPath: asset,
          letter: label.isNotEmpty ? label[0].toUpperCase() : 'P',
          accent: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(label, style: textStyle),
      ],
    );
  }
}

class _PortfolioLogoChip extends StatelessWidget {
  const _PortfolioLogoChip({
    required this.size,
    required this.letter,
    required this.accent,
    this.assetPath,
  });

  final double size;
  final String letter;
  final Color accent;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 6,
      height: size + 6,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: assetPath != null
          ? Image.asset(
              assetPath!,
              package: 'am_doc_intelligence_ui',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _letter(),
            )
          : _letter(),
    );
  }

  Widget _letter() {
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.55,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}
