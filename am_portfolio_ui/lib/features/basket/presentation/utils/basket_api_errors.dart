import 'package:am_common/am_common.dart';

/// Maps basket API errors (especially HTTP 409) to user-readable messages.
String basketApiErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 409) {
      final msg = error.message.trim();
      if (msg.isNotEmpty && !msg.startsWith('ApiException')) {
        return msg;
      }
      return 'This change conflicts with your current basket state. Refresh and try again.';
    }
    if (error.statusCode == 400) {
      return error.message;
    }
  }
  return error.toString().replaceFirst('ApiException: ', '');
}

/// Builds snackbar text when apply-substitutes partially succeeds.
String substituteApplyMessage({
  required int appliedCount,
  required List<String> warnings,
}) {
  if (appliedCount <= 0) {
    if (warnings.isNotEmpty) {
      return 'No substitutes applied: ${warnings.first}';
    }
    return 'No substitutes applied — check your holdings';
  }
  if (warnings.isNotEmpty) {
    return '$appliedCount applied, ${warnings.length} skipped: ${warnings.first}';
  }
  return '$appliedCount applied — see Substituted section';
}
