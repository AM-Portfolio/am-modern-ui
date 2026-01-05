import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:am_common/features/attachment/internal/presentation/models/pending_attachment.dart';

part 'attachment_state.freezed.dart';

@freezed
abstract class AttachmentState with _$AttachmentState {
  const factory AttachmentState.initial() = _Initial;

  const factory AttachmentState.loading() = _Loading;

  const factory AttachmentState.uploading({
    required int currentFile,
    required int totalFiles,
    required double progress,
  }) = _Uploading;

  const factory AttachmentState.uploaded({
    required List<String> urls,
    required List<PendingAttachment> pending,
  }) = _Uploaded;

  const factory AttachmentState.error({
    required String message,
    List<String>? uploadedUrls,
    List<PendingAttachment>? pending,
  }) = _Error;
}
