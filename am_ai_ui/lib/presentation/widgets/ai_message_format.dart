import 'package:flutter/material.dart';
import '../../data/ai_intent_response.dart';

/// Formats AI chat text and tool metadata for display.
class AiMessageFormat {
  const AiMessageFormat._();

  static const _structuredWidgets = {
    'HOLDINGS_TABLE',
    'TOP_MOVERS',
    'PORTFOLIO_SUMMARY',
    'ALLOCATION_PIE_CHART',
    'RECENT_ACTIVITY',
    'BASKET_CARD',
    'ORDER_PREVIEW',
  };

  static const _toolLabels = {
    'get_portfolio_summary': 'Portfolio',
    'get_holdings_list': 'Holdings',
    'get_holdings': 'Holdings',
    'get_holding_detail': 'Holding',
    'get_top_movers': 'Top movers',
    'get_market_movers': 'Market movers',
    'get_stock_quote': 'Quote',
    'get_indices_data': 'Indices',
    'search_instruments': 'Search',
    'get_recent_activity': 'Activity',
    'get_trade_history': 'Trades',
    'get_sector_allocation': 'Sectors',
    'get_market_cap_allocation': 'Market cap',
  };

  /// Widgets that render beside a short intro instead of below duplicated text.
  static bool usesInlineWidgetLayout(String? widgetId) =>
      widgetId == 'PORTFOLIO_SUMMARY';

  static bool isStructuredWidget(String? widgetId) =>
      widgetId != null && _structuredWidgets.contains(widgetId);

  /// Remove raw markdown tables when a structured widget renders the same data.
  static String cleanDisplayText(String text, AiIntentResponse? response) {
    var out = text.trim();
    if (out.isEmpty) return out;

    final widgetId = response?.widgetId ?? 'TEXT_RESPONSE';
    if (_structuredWidgets.contains(widgetId)) {
      out = _stripMarkdownTables(out);
      if (widgetId == 'PORTFOLIO_SUMMARY') {
        out = _stripPortfolioMetricBullets(out);
      }
      out = _collapseBlankLines(out);
    }
    return out;
  }

  static String toolLabel(String toolName) =>
      _toolLabels[toolName] ?? toolName.replaceAll('_', ' ');

  static Widget richText(String text, TextStyle baseStyle) {
    if (!text.contains('**')) {
      return Text(text, style: baseStyle);
    }
    return Text.rich(
      TextSpan(children: _boldSpans(text, baseStyle)),
    );
  }

  static List<TextSpan> _boldSpans(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd
              ? base.copyWith(fontWeight: FontWeight.w700)
              : base,
        ),
      );
    }
    return spans;
  }

  /// Parse a simple markdown pipe table into row maps (header → cell).
  static List<Map<String, String>> parseMarkdownTable(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.startsWith('|') && l.endsWith('|'))
        .toList();
    if (lines.length < 2) return const [];

    List<String> splitRow(String row) {
      return row
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
    }

    final header = splitRow(lines.first);
    if (header.isEmpty) return const [];

    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (RegExp(r'^[\|\-\:\s]+$').hasMatch(line)) continue;
      final cells = splitRow(line);
      if (cells.isEmpty) continue;
      final row = <String, String>{};
      for (var c = 0; c < header.length && c < cells.length; c++) {
        row[header[c]] = cells[c];
      }
      if (row.isNotEmpty) rows.add(row);
    }
    return rows;
  }

  static String _stripMarkdownTables(String text) {
    final kept = <String>[];
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('|') && trimmed.contains('|')) continue;
      if (RegExp(r'^[\|\-\:\s]+$').hasMatch(trimmed)) continue;
      kept.add(line);
    }
    return kept.join('\n').trim();
  }

  static String _collapseBlankLines(String text) {
    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  static final _portfolioMetricLine = RegExp(
    r"^[\-\*•]?\s*(?:\*\*)?(Total Value|Total Invested|Total Gain|Today's Gain|Total Holdings|Total Portfolios|Total Assets)\b",
    caseSensitive: false,
  );

  /// Drop bullet/label lines duplicated by [PORTFOLIO_SUMMARY] cards.
  static String _stripPortfolioMetricBullets(String text) {
    final kept = <String>[];
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        kept.add(line);
        continue;
      }
      if (_portfolioMetricLine.hasMatch(trimmed)) continue;
      kept.add(line);
    }
    return kept.join('\n').trim();
  }
}
