import 'package:am_trade_ui/features/trade/presentation/journal/models/journal_trade_id_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JournalTradeIdParser.parseTradeIdsFromText', () {
    test('splits commas newlines and whitespace', () {
      const raw = 'a,b\nc ; d  e';
      expect(
        JournalTradeIdParser.parseTradeIdsFromText(raw),
        ['a', 'b', 'c', 'd', 'e'],
      );
    });

    test('dedupes and ignores blanks', () {
      expect(
        JournalTradeIdParser.parseTradeIdsFromText('x,,x\n y '),
        ['x', 'y'],
      );
    });

    test('empty returns empty', () {
      expect(JournalTradeIdParser.parseTradeIdsFromText('  '), isEmpty);
    });
  });

  group('JournalTradeIdParser.parseTradeIdsFromCsv', () {
    test('uses tradeId header column', () {
      const csv = 'symbol,tradeId,pnl\nRELIANCE,t-1,10\nINFY,t-2,-5\n';
      expect(
        JournalTradeIdParser.parseTradeIdsFromCsv(csv),
        ['t-1', 't-2'],
      );
    });

    test('accepts trade_id and id headers', () {
      expect(
        JournalTradeIdParser.parseTradeIdsFromCsv('trade_id\na\nb'),
        ['a', 'b'],
      );
      expect(
        JournalTradeIdParser.parseTradeIdsFromCsv('id,name\n1,foo'),
        ['1'],
      );
    });

    test('falls back to first column without header', () {
      expect(
        JournalTradeIdParser.parseTradeIdsFromCsv('t-9\nt-8'),
        ['t-9', 't-8'],
      );
    });

    test('handles quoted commas', () {
      const csv = 'tradeId,note\n"t-1","hello, world"\n';
      expect(JournalTradeIdParser.parseTradeIdsFromCsv(csv), ['t-1']);
    });

    test('dedupes and skips blank rows', () {
      const csv = 'tradeId\nt-1\n\nt-1\nt-2\n';
      expect(JournalTradeIdParser.parseTradeIdsFromCsv(csv), ['t-1', 't-2']);
    });
  });

  group('JournalTradeIdParser.parseTradeIdsAuto', () {
    test('detects CSV header', () {
      expect(
        JournalTradeIdParser.parseTradeIdsAuto('tradeId,x\na,1'),
        ['a'],
      );
    });

    test('falls back to text split', () {
      expect(
        JournalTradeIdParser.parseTradeIdsAuto('a,b,c'),
        ['a', 'b', 'c'],
      );
    });
  });
}
