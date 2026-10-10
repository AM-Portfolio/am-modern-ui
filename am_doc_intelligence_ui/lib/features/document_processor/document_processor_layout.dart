/// Layout helpers for [DocumentProcessorView] responsive branches.
///
/// Wide desktop (`isWide`) must surface status/batch UI when state is non-empty;
/// narrow branches mount those widgets via their own paths.
bool docProcessorWideShowsStatusSlots({
  required bool isWide,
  required bool hasStatusOrProcessing,
  required bool hasBatch,
}) =>
    isWide && (hasStatusOrProcessing || hasBatch);
