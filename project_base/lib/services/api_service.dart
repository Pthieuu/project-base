import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_base/models/transaction_model.dart';
import 'package:project_base/services/user_session.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/',
  );

  Future<void> addTransaction(Map<String, dynamic> data) async {
    if (UserSession.user_id == null) {
      throw Exception("User not logged in");
    }

    final body = {...data, "user_id": UserSession.user_id};

    final response = await http.post(
      Uri.parse("${baseUrl}add_transaction.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }
  }

  Future<List<TransactionModel>> getTransactions(int userId) async {
    final response = await http.post(
      Uri.parse("${baseUrl}get_transaction.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map && data['status'] == 'success') {
        final List transactions = data['data'];
        return transactions
            .map((item) => TransactionModel.fromJson(item))
            .toList();
      } else {
        return [];
      }
    } else {
      return [];
    }
  }
}
