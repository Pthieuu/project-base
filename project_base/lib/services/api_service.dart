import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_base/models/category_budget_model.dart';
import 'package:project_base/models/category_model.dart';
import 'package:project_base/models/recurring_transaction_model.dart';
import 'package:project_base/models/saving_goal_model.dart';
import 'package:project_base/models/transaction_model.dart';
import 'package:project_base/services/user_session.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/',
  );

  static Map<String, String> get authorizedJsonHeaders {
    final token = UserSession.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception("User not authenticated");
    }
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<int> addTransaction(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("${baseUrl}add_transaction.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final responseData = jsonDecode(response.body);
    if (responseData is! Map || responseData['status'] != 'success') {
      throw Exception(responseData['message'] ?? "Add transaction failed");
    }

    final transactionId = int.tryParse(
      responseData['transaction_id']?.toString() ?? '',
    );
    if (transactionId == null || transactionId <= 0) {
      throw Exception("API did not return the new transaction ID");
    }
    return transactionId;
  }

  Future<void> updateTransaction(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("${baseUrl}update_transaction.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final responseData = jsonDecode(response.body);
    if (responseData is! Map || responseData['status'] != 'success') {
      throw Exception(responseData['message'] ?? "Update failed");
    }
  }

  Future<void> deleteTransaction(int transactionId) async {
    final response = await http.post(
      Uri.parse("${baseUrl}delete_transaction.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode({"id": transactionId}),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final responseData = jsonDecode(response.body);
    if (responseData is! Map || responseData['status'] != 'success') {
      throw Exception(responseData['message'] ?? "Delete failed");
    }
  }

  Future<List<TransactionModel>> getTransactions() async {
    final response = await http.post(
      Uri.parse("${baseUrl}get_transaction.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode({}),
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

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse("${baseUrl}update_profile.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode({"name": name, "email": email}),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data is Map && data['status'] == 'success') {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['message'] ?? "Cannot update profile");
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await http.post(
      Uri.parse("${baseUrl}get_categories.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode({}),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data is Map && data['status'] == 'success') {
      final List items = data['data'];
      return items.map((item) => CategoryModel.fromJson(item)).toList();
    }

    throw Exception(data['message'] ?? "Cannot load categories");
  }

  Future<void> saveCategory({
    required String name,
    required String type,
    String icon = 'wallet',
    String color = '#1132D4',
  }) async {
    final response = await http.post(
      Uri.parse("${baseUrl}save_category.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode({
        "name": name,
        "type": type,
        "icon": icon,
        "color": color,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data is! Map || data['status'] != 'success') {
      throw Exception(data['message'] ?? "Cannot save category");
    }
  }

  Future<List<CategoryBudgetModel>> getBudgets(String month) async {
    final response = await http.post(
      Uri.parse("${baseUrl}get_budgets.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode({"month": month}),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data is Map && data['status'] == 'success') {
      final List items = data['data'];
      return items.map((item) => CategoryBudgetModel.fromJson(item)).toList();
    }

    throw Exception(data['message'] ?? "Cannot load budgets");
  }

  Future<void> saveBudget({
    required String category,
    required String month,
    required double monthlyLimit,
  }) async {
    final response = await http.post(
      Uri.parse("${baseUrl}save_budget.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode({
        "category": category,
        "month": month,
        "monthly_limit": monthlyLimit,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data is! Map || data['status'] != 'success') {
      throw Exception(data['message'] ?? "Cannot save budget");
    }
  }

  Future<List<SavingGoalModel>> getGoals() async {
    final response = await http.post(
      Uri.parse("${baseUrl}get_goals.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode({}),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data is Map && data['status'] == 'success') {
      final List items = data['data'];
      return items.map((item) => SavingGoalModel.fromJson(item)).toList();
    }

    throw Exception(data['message'] ?? "Cannot load goals");
  }

  Future<void> saveGoal({
    int? id,
    required String title,
    required double targetAmount,
    required double currentAmount,
    String? targetDate,
    String note = '',
    bool isCompleted = false,
  }) async {
    final response = await http.post(
      Uri.parse("${baseUrl}save_goal.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode({
        if (id != null) "id": id,
        "title": title,
        "target_amount": targetAmount,
        "current_amount": currentAmount,
        "target_date": targetDate ?? '',
        "note": note,
        "is_completed": isCompleted ? 1 : 0,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data is! Map || data['status'] != 'success') {
      throw Exception(data['message'] ?? "Cannot save goal");
    }
  }

  Future<void> deleteGoal(int goalId) async {
    final response = await http.post(
      Uri.parse("${baseUrl}delete_goal.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode({"id": goalId}),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data is! Map || data['status'] != 'success') {
      throw Exception(data['message'] ?? "Cannot delete goal");
    }
  }

  Future<List<RecurringTransactionModel>> getRecurringTransactions() async {
    final response = await http.post(
      Uri.parse("${baseUrl}get_recurring_transactions.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode({}),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data is Map && data['status'] == 'success') {
      final List items = data['data'];
      return items
          .map((item) => RecurringTransactionModel.fromJson(item))
          .toList();
    }

    throw Exception(data['message'] ?? "Cannot load recurring transactions");
  }

  Future<void> saveRecurringTransaction({
    int? id,
    required String description,
    required String category,
    required String account,
    required double amount,
    required bool isExpense,
    required String frequency,
    required String nextRunDate,
    String notes = '',
    bool isActive = true,
  }) async {
    final response = await http.post(
      Uri.parse("${baseUrl}save_recurring_transaction.php"),
      headers: authorizedJsonHeaders,
      body: jsonEncode({
        if (id != null) "id": id,
        "description": description,
        "category": category,
        "account": account,
        "amount": amount,
        "is_expense": isExpense ? 1 : 0,
        "frequency": frequency,
        "next_run_date": nextRunDate,
        "notes": notes,
        "is_active": isActive ? 1 : 0,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data is! Map || data['status'] != 'success') {
      throw Exception(data['message'] ?? "Cannot save recurring transaction");
    }
  }
}
