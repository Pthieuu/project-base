import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_base/services/api_service.dart';
import 'package:project_base/services/user_session.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    return _postForm("login.php", {"email": email, "password": password});
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    return _postForm("register.php", {
      "name": name,
      "email": email,
      "password": password,
    });
  }

  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) async {
    return _postForm("reset_password.php", {
      "email": email,
      "password": newPassword,
    });
  }

  static Future<void> logout() async {
    final token = UserSession.accessToken;
    if (token == null || token.isEmpty) return;

    try {
      await http.post(
        Uri.parse("${ApiService.baseUrl}logout.php"),
        headers: {"Authorization": "Bearer $token"},
      );
    } catch (_) {
      // Local logout must still succeed if the server is unavailable.
    }
  }

  static Future<Map<String, dynamic>> _postForm(
    String endpoint,
    Map<String, String> body,
  ) async {
    final uri = Uri.parse("${ApiService.baseUrl}$endpoint");
    final response = await http.post(uri, body: body);

    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      // The status handling below provides a readable fallback.
    }

    if (response.statusCode != 200) {
      final message = data?["message"];
      throw Exception(
        message is String && message.isNotEmpty
            ? message
            : "API ${response.statusCode}: server error at $uri.",
      );
    }

    if (data == null) {
      throw Exception(
        "API did not return JSON. The PHP server may be pointing to the wrong folder: $uri",
      );
    }
    return data;
  }
}
