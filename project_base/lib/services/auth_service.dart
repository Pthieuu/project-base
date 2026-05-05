import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_base/services/api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    var response = await http.post(
      Uri.parse("${ApiService.baseUrl}login.php"),
      body: {"email": email, "password": password},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    var response = await http.post(
      Uri.parse("${ApiService.baseUrl}register.php"),
      body: {"name": name, "email": email, "password": password},
    );

    return jsonDecode(response.body);
  }
}
