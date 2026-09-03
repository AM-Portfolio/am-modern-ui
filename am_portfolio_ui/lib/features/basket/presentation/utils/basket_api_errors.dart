import 'package:am_common/am_common.dart';

/// Maps basket API errors (especially HTTP 409) to user-readable messages.
String basketApiErrorMessage(Object error) {
  if (error is ApiException) {
    final code = basketApiErrorCode(error);
    if (code == 'DRAFT_LIMIT_REACHED') {
      return error.message.isNotEmpty
          ? error.message
          : 'You already have 5 drafts. Delete one to save another.';
    }
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
    if (error.statusCode == 404) {
      return 'ETF not found — please pick another theme.';
    }
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Session expired. Please log in again.';
    }
    if (error.statusCode == 408 || error.statusCode == 504) {
      return 'Market data is slow. Showing last known prices if available.';
    }
    if ((error.statusCode ?? 0) >= 500) {
      return 'Something went wrong on our end. Please retry.';
    }
  }
  final raw = error.toString().toLowerCase();
  if (raw.contains('socketexception') || raw.contains('timeout')) {
    return 'No internet connection. Please check your network.';
  }
  return error.toString().replaceFirst('ApiException: ', '');
}

String? basketApiErrorCode(Object error) {
  if (error is! ApiException) return null;
  final data = error.data;
  if (data is Map && data['errorCode'] != null) {
    return data['errorCode'].toString();
  }
  return null;
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
