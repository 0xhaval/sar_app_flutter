import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'roles.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await ApiService.login(email, password);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', data['token'] ?? '');

    final user = data['user'] as Map?;
    final employee = data['employee'] as Map?;
    await prefs.setString('user_id', user?['id'] ?? '');
    await prefs.setString('user_email', user?['email'] ?? '');
    await prefs.setString('full_name', user?['name'] ?? '');
    await prefs.setString('employee_id', employee?['employeeCode'] ?? '');
    await prefs.setString('user_roles', jsonEncode(extractRoles(user)));

    return data;
  }

  static Future<void> deleteAccount() async {
    await ApiService.deleteJson('/api/mobile/me');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('full_name');
    await prefs.remove('employee_id');
    await prefs.remove('user_roles');
  }

  static Future<void> logout() async {
    try {
      await ApiService.postJson('/api/mobile/auth/logout');
    } catch (_) {
      /* server-side is a no-op; ignore errors so logout always succeeds */
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('full_name');
    await prefs.remove('employee_id');
    await prefs.remove('user_roles');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return token.isNotEmpty;
  }

  static Future<String> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('full_name') ?? '';
  }

  static Future<String> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('employee_id') ?? '';
  }

  /// Roles for the current user. Reads the persisted list first; if none was
  /// stored (a session that predates role persistence), fetches `/api/mobile/me`
  /// once, persists, and returns. Returns an empty list on any failure.
  static Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('user_roles');
    if (stored != null && stored.isNotEmpty) {
      final decoded = jsonDecode(stored);
      if (decoded is List) return decoded.map((r) => r.toString()).toList();
    }
    try {
      final data = await ApiService.getJson('/api/mobile/me');
      final user = (data is Map ? data['user'] as Map? : null);
      final roles = extractRoles(user);
      await prefs.setString('user_roles', jsonEncode(roles));
      return roles;
    } catch (_) {
      return const [];
    }
  }

  /// Whether the current user may create customers (Reception / Sales Mobile).
  static Future<bool> canAddCustomer() async {
    return canAddCustomerFromRoles(await getRoles());
  }
}
