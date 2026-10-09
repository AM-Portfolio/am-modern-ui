import 'package:flutter_test/flutter_test.dart';
import 'package:am_doc_intelligence_ui/features/document_processor/document_processor_layout.dart';

void main() {
  group('docProcessorWideShowsStatusSlots', () {
    test('wide + hasBatch → true', () {
      expect(
        docProcessorWideShowsStatusSlots(
          isWide: true,
          hasStatusOrProcessing: false,
          hasBatch: true,
        ),
        isTrue,
      );
    });

    test('wide + status/processing → true', () {
      expect(
        docProcessorWideShowsStatusSlots(
          isWide: true,
          hasStatusOrProcessing: true,
          hasBatch: false,
        ),
        isTrue,
      );
    });

    test('wide + empty → false', () {
      expect(
        docProcessorWideShowsStatusSlots(
          isWide: true,
          hasStatusOrProcessing: false,
          hasBatch: false,
        ),
        isFalse,
      );
    });

    test('narrow even with batch → false (other branches own UI)', () {
      expect(
        docProcessorWideShowsStatusSlots(
          isWide: false,
          hasStatusOrProcessing: true,
          hasBatch: true,
        ),
        isFalse,
      );
    });
  });
}
