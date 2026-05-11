import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_base/services/api_service.dart';

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

  static Future<Map<String, dynamic>> _postForm(
    String endpoint,
    Map<String, String> body,
  ) async {
    final uri = Uri.parse("${ApiService.baseUrl}$endpoint");
    final response = await http.post(uri, body: body);

    if (response.statusCode != 200) {
      throw Exception(
        "API ${response.statusCode}: không tìm thấy $uri. Kiểm tra lại PHP server/API_BASE_URL.",
      );
    }

    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const FormatException("Response is not a JSON object");
    } on FormatException {
      throw Exception(
        "API trả về không phải JSON. Có thể PHP server đang trỏ sai thư mục: $uri",
      );
    }
  }
}
