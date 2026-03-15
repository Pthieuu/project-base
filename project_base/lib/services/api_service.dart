import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  // Android Emulator dùng 10.0.2.2
  static const String baseUrl = "http://127.0.0.1/expense_api/";

  Future<void> add_transaction(Map data) async {

    final response = await http.post(
      Uri.parse("${baseUrl}add_transaction.php"),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(data),
    );

    print("API RESPONSE: ${response.body}");
  }
}