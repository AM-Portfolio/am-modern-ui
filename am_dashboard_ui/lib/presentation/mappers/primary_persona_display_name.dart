import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';

String? hubIdentityOrNpsName(AccountsHub hub) {
  final identity = hub.identity?.name?.trim();
  if (identity != null && identity.isNotEmpty) return identity;
  final nps = hub.nps?.subscriberName?.trim();
  if (nps != null && nps.isNotEmpty) return nps;
  return null;
}

/// Primary / "You" label comes from hub identity only (backend owns the truth).
String? resolvePrimaryPersonaDisplayName(
  AccountsHub hub,
  String? sessionDisplayName,
) {
  return hubIdentityOrNpsName(hub);
}

String primaryPersonaStripLabel(AccountsHub hub, String? sessionDisplayName) {
  final name = resolvePrimaryPersonaDisplayName(hub, sessionDisplayName);
  if (name == null || name.isEmpty) return 'You';
  return name;
}
