import 'package:am_doc_intelligence_ui/features/import_source_resolve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveImportSourceSlug', () {
    test('mailbox and email-extractor open Email on all platforms', () {
      expect(resolveImportSourceSlug('mailbox'), ImportSourceKind.email);
      expect(
        resolveImportSourceSlug('email-extractor'),
        ImportSourceKind.email,
      );
      expect(resolveImportSourceSlug('unknown'), ImportSourceKind.email);
    });

    test('upload and doc-processor open Document upload', () {
      expect(resolveImportSourceSlug('upload'), ImportSourceKind.upload);
      expect(
        resolveImportSourceSlug('doc-processor'),
        ImportSourceKind.upload,
      );
    });
  });
}
