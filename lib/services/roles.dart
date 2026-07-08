/// Role identifiers (as the backend sends them) allowed to create customers.
/// Compared case-insensitively; add entries here to grant the button to more
/// roles.
const Set<String> kAddCustomerRoles = {'RECEPTION', 'SALES_MOBILE'};

/// Coerces the `user` object from a login or `/api/mobile/me` response into a
/// list of role strings. Prefers `user['roles']` (a list); falls back to the
/// legacy single `user['role']`; returns an empty list if neither is present.
List<String> extractRoles(Map? user) {
  if (user == null) return const [];
  final roles = user['roles'];
  if (roles is List) {
    return roles.map((r) => r.toString()).toList();
  }
  final role = user['role'];
  if (role is String && role.isNotEmpty) {
    return [role];
  }
  return const [];
}

/// True if any of [roles] is allowed to create customers (case-insensitive).
bool canAddCustomerFromRoles(Iterable<String> roles) {
  return roles.any((r) => kAddCustomerRoles.contains(r.toUpperCase()));
}
