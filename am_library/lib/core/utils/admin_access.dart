/// Whether [roles] or OAuth scopes grant admin access.
bool rolesOrScopesGrantAdmin(Iterable<String> roles, Iterable<String> scopes) {
  bool isAdminName(String value) {
    final normalized = value.toLowerCase().replaceAll('-', '_');
    return normalized == 'admin' ||
        normalized == 'super_admin' ||
        normalized == 'role_admin';
  }

  for (final role in roles) {
    if (isAdminName(role)) return true;
  }
  for (final scope in scopes) {
    if (isAdminName(scope)) return true;
  }
  return false;
}
