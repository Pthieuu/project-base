import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_base/services/user_session.dart';

class ApiService {

  // Android Emulator dùng 10.0.2.2
  static const String baseUrl = "http://127.0.0.1/expense_api/";

  Future<void> add_transaction(Map<String, dynamic> data) async {

  if (UserSession.user_id == null) {
    throw Exception("User not logged in");
  }

  final body = {
    ...data,
    "user_id": UserSession.user_id, // 🔥 FIX QUAN TRỌNG
  };

  print("SEND DATA: $body");

  final response = await http.post(
    Uri.parse("${baseUrl}add_transaction.php"),
    headers: {
      "Content-Type": "application/json"
    },
    body: jsonEncode(body),
  );

  print("API RESPONSE: ${response.body}");
}

  Future<List<dynamic>> get_transactions(int user_id) async {
    final response = await http.post(
      Uri.parse("${baseUrl}get_transaction.php"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "user_id": UserSession.user_id,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map && data['status'] == 'success') {
        return data['data']; 
      } else {
        print("API ERROR: $data");
        return [];
    }
  }

    throw Exception("Failed to load transactions");
  }
} 