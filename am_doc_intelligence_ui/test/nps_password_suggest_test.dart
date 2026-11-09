import 'package:am_doc_intelligence_ui/features/nps_password_suggest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Om + 01/11/1975 → 99om0111', () {
    expect(
      buildNpsStatementPassword('Om', DateTime(1975, 11, 1)),
      '99om0111',
    );
  });

  test('longer first name uses first 4 lowercase letters', () {
    expect(
      buildNpsStatementPassword('Mukherjee', DateTime(1975, 11, 1)),
      'mukh0111',
    );
  });

  test('parse DOB formats', () {
    expect(parseNpsDobInput('01/11/1975'), DateTime(1975, 11, 1));
    expect(parseNpsDobInput('01-11-1975'), DateTime(1975, 11, 1));
    expect(parseNpsDobInput('01111975'), DateTime(1975, 11, 1));
  });
}
