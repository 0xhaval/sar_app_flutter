import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://sar-iq.com';
  static const String _apiBase = '$baseUrl/api/method/sar_app.api.mobile';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('api_key') ?? '';
    final apiSecret = prefs.getString('api_secret') ?? '';

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (apiKey.isNotEmpty && apiSecret.isNotEmpty) {
      headers['Authorization'] = 'token $apiKey:$apiSecret';
    }

    return headers;
  }

  static Future<dynamic> call(String method, {Map<String, dynamic>? params}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$_apiBase.$method');

    final response = await http.post(
      uri,
      headers: headers,
      body: params != null ? jsonEncode(params) : null,
    );

    print('[API] $method → ${response.statusCode}');
    print('[API] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['exc'] != null) {
        print('[API] Exception: ${data['exc']}');
        throw ApiException(data['exc_type'] ?? 'Server Error', response.statusCode);
      }
      return data['message'];
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiException('غير مصرح', response.statusCode);
    } else {
      String message = 'حدث خطأ في الاتصال';
      try {
        final data = jsonDecode(response.body);
        message = data['message'] ?? data['exc_type'] ?? message;
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
  }

  /// Upload a file to Frappe and return the file URL.
  static Future<String> uploadFile(File file) async {
    final headers = await _getHeaders();
    headers.remove('Content-Type'); // multipart sets its own

    final uri = Uri.parse('$baseUrl/api/method/upload_file');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..fields['is_private'] = '0'
      ..fields['folder'] = 'Home/Attachments'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final fileUrl = data['message']?['file_url'] as String?;
      if (fileUrl == null) throw ApiException('فشل رفع الملف', 200);
      return fileUrl;
    } else {
      throw ApiException('فشل رفع الملف', response.statusCode);
    }
  }

  /// Fetch documents from Frappe's built-in /api/resource/ endpoint.
  static Future<List<Map<String, dynamic>>> getList(
    String doctype, {
    List<String> fields = const ['name'],
    String? orderBy,
    int limitPageLength = 0,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{
      'fields': jsonEncode(fields),
      if (orderBy != null) 'order_by': orderBy,
      'limit_page_length': '$limitPageLength',
    };
    final uri = Uri.parse('$baseUrl/api/resource/$doctype')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiException('غير مصرح', response.statusCode);
    } else {
      throw ApiException('حدث خطأ في الاتصال', response.statusCode);
    }
  }

  static Future<dynamic> login(String usr, String pwd) async {
    final uri = Uri.parse('$_apiBase.login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'usr': usr, 'pwd': pwd}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['exc'] != null) {
        throw ApiException(data['exc_type'] ?? 'Login failed', response.statusCode);
      }
      return data['message'];
    } else {
      String message = 'فشل تسجيل الدخول';
      try {
        final data = jsonDecode(response.body);
        message = data['message'] ?? message;
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
