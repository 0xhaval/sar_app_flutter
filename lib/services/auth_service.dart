import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String usr, String pwd) async {
    final result = await ApiService.login(usr, pwd);
    final data = Map<String, dynamic>.from(result);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', data['api_key'] ?? '');
    await prefs.setString('api_secret', data['api_secret'] ?? '');
    await prefs.setString('user', data['user'] ?? '');
    await prefs.setString('full_name', data['full_name'] ?? '');
    await prefs.setString('employee_id', data['employee_id'] ?? '');

    return data;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_key');
    await prefs.remove('api_secret');
    await prefs.remove('user');
    await prefs.remove('full_name');
    await prefs.remove('employee_id');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('api_key') ?? '';
    final apiSecret = prefs.getString('api_secret') ?? '';
    return apiKey.isNotEmpty && apiSecret.isNotEmpty;
  }

  static Future<String> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('full_name') ?? '';
  }

  static Future<String> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('employee_id') ?? '';
  }
}
