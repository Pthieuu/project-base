import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {

  static String baseUrl = "http://127.0.0.1/expense_api";

  static Future<Map<String, dynamic>> login(String email, String password) async {

    var response = await http.post(
      Uri.parse("$baseUrl/login.php"),
      body: {
        "email": email,
        "password": password
      },
    );

    print("LOGIN RESPONSE: ${response.body}");

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {

    var response = await http.post(
      Uri.parse("$baseUrl/register.php"),
      body: {
        "name": name,
        "email": email,
        "password": password
      },
    );

    print("REGISTER RESPONSE: ${response.body}");

    return jsonDecode(response.body);
  }
}