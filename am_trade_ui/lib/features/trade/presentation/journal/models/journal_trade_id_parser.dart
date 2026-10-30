/// Pure helpers for Journal → Import (paste text / CSV → trade IDs).
class JournalTradeIdParser {
  JournalTradeIdParser._();

  static final _splitPattern = RegExp(r'[\s,;]+');

  /// Known CSV header names for the trade-id column (case-insensitive).
  static const _idHeaders = {
    'tradeid',
    'trade_id',
    'trade-id',
    'id',
  };

  /// Split whitespace / commas / semicolons / newlines into unique non-empty IDs.
  static List<String> parseTradeIdsFromText(String raw) {
    if (raw.trim().isEmpty) return const [];
    final seen = <String>{};
    final out = <String>[];
    for (final part in raw.split(_splitPattern)) {
      final id = part.trim();
      if (id.isEmpty) continue;
      if (seen.add(id)) out.add(id);
    }
    return out;
  }

  /// Parse CSV body: prefer a `tradeId` / `trade_id` / `id` header column,
  /// otherwise use the first column. Blank rows ignored. IDs deduped.
  static List<String> parseTradeIdsFromCsv(String raw) {
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];

    final firstCells = _splitCsvLine(lines.first);
    final headerIndex = _headerTradeIdIndex(firstCells);

    final dataLines = headerIndex != null ? lines.skip(1) : lines;
    final col = headerIndex ?? 0;

    final seen = <String>{};
    final out = <String>[];
    for (final line in dataLines) {
      final cells = _splitCsvLine(line);
      if (cells.isEmpty || col >= cells.length) continue;
      final id = cells[col].trim();
      if (id.isEmpty) continue;
      // Skip accidental re-parse of a header-looking cell in no-header mode.
      if (headerIndex == null && _idHeaders.contains(_normalizeHeader(id))) {
        continue;
      }
      if (seen.add(id)) out.add(id);
    }
    return out;
  }

  /// Auto-detect: CSV only when the first line has a trade-id header;
  /// otherwise treat as loose ID text (commas / newlines).
  static List<String> parseTradeIdsAuto(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const [];
    final firstLine = trimmed.split(RegExp(r'\r?\n')).first;
    final cells = _splitCsvLine(firstLine);
    if (_headerTradeIdIndex(cells) != null) {
      return parseTradeIdsFromCsv(trimmed);
    }
    return parseTradeIdsFromText(trimmed);
  }

  static int? _headerTradeIdIndex(List<String> cells) {
    for (var i = 0; i < cells.length; i++) {
      if (_idHeaders.contains(_normalizeHeader(cells[i]))) return i;
    }
    return null;
  }

  static String _normalizeHeader(String cell) =>
      cell.trim().toLowerCase().replaceAll('"', '');

  /// Minimal CSV split (handles quoted commas).
  static List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (ch == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
        continue;
      }
      buf.write(ch);
    }
    result.add(buf.toString());
    return result;
  }
}
