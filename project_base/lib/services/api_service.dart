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

    final responseData = jsonDecode(response.body);
    if (responseData is! Map || responseData['status'] != 'success') {
      throw Exception(responseData['message'] ?? "Add transaction failed");
    }
  }

  Future<void> updateTransaction(Map<String, dynamic> data) async {
    if (UserSession.user_id == null) {
      throw Exception("User not logged in");
    }

    final body = {...data, "user_id": UserSession.user_id};

    final response = await http.post(
      Uri.parse("${baseUrl}update_transaction.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
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
    if (UserSession.user_id == null) {
      throw Exception("User not logged in");
    }

    final response = await http.post(
      Uri.parse("${baseUrl}delete_transaction.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": transactionId, "user_id": UserSession.user_id}),
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ERROR: ${response.statusCode}");
    }

    final responseData = jsonDecode(response.body);
    if (responseData is! Map || responseData['status'] != 'success') {
      throw Exception(responseData['message'] ?? "Delete failed");
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

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    final userId = UserSession.user_id;
    if (userId == null) throw Exception("User not logged in");

    final response = await http.post(
      Uri.parse("${baseUrl}update_profile.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "name": name, "email": email}),
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
    final userId = UserSession.user_id;
    if (userId == null) throw Exception("User not logged in");

    final response = await http.post(
      Uri.parse("${baseUrl}get_categories.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId}),
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
    final userId = UserSession.user_id;
    if (userId == null) throw Exception("User not logged in");

    final response = await http.post(
      Uri.parse("${baseUrl}save_category.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
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
    final userId = UserSession.user_id;
    if (userId == null) throw Exception("User not logged in");

    final response = await http.post(
      Uri.parse("${baseUrl}get_budgets.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "month": month}),
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
    final userId = UserSession.user_id;
    if (userId == null) throw Exception("User not logged in");

    final response = await http.post(
      Uri.parse("${baseUrl}save_budget.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
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
    final userId = UserSession.user_id;
    if (userId == null) throw Exception("User not logged in");

    final response = await http.post(
      Uri.parse("${baseUrl}get_goals.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId}),
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
    final userId = UserSession.user_id;
    if (userId == null) throw Exception("User not logged in");

    final response = await http.post(
      Uri.parse("${baseUrl}save_goal.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
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
    final userId = UserSession.user_id;
    if (userId == null) throw Exception("User not logged in");

    final response = await http.post(
      Uri.parse("${baseUrl}delete_goal.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": goalId, "user_id": userId}),
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
    final userId = UserSession.user_id;
    if (userId == null) throw Exception("User not logged in");

    final response = await http.post(
      Uri.parse("${baseUrl}get_recurring_transactions.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId}),
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
    final userId = UserSession.user_id;
    if (userId == null) throw Exception("User not logged in");

    final response = await http.post(
      Uri.parse("${baseUrl}save_recurring_transaction.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
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
