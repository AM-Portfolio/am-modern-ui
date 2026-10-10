/// Formats a user id for display in the Profile header field.
///
/// Shows the full string when short; otherwise the first [head] characters
/// plus an ellipsis. Clipboard always uses the full id separately.
String truncateUserId(String id, {int head = 20, int maxLen = 23}) {
  if (id.length <= maxLen) return id;
  if (head <= 0) return '...';
  final safeHead = head > id.length ? id.length : head;
  return '${id.substring(0, safeHead)}...';
}
