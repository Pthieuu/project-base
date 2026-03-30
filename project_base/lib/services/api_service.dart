import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_base/models/transaction_model.dart';
import 'package:project_base/services/user_session.dart';
import 'package:project_base/services/api_service.dart';

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

  Future<List<TransactionModel>> get_transactions(int user_id) async {
  final response = await http.post(
    Uri.parse("${baseUrl}get_transaction.php"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"user_id": user_id}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is Map && data['status'] == 'success') {
      final List transactions = data['data'];
      return transactions
          .map((item) => TransactionModel.fromJson(item))
          .toList();
    } else {
      print("API ERROR: $data");
      return [];
    }
  } else {
    print("HTTP ERROR: ${response.statusCode}");
    return [];
  }
}
} 