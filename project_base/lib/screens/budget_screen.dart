import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_base/models/transaction_model.dart';
import 'package:project_base/services/api_service.dart';
import 'package:project_base/services/user_session.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late Future<_BudgetSummary> futureBudget;

  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    futureBudget = _loadBudgetSummary();
  }

  Future<_BudgetSummary> _loadBudgetSummary() async {
    if (UserSession.user_id == null) {
      throw Exception("User not logged in");
    }

    final transactions = await ApiService().get_transactions(UserSession.user_id!);
    final now = DateTime.now();

    final monthlyTransactions = transactions.where((tx) {
      final date = DateTime.tryParse(tx.date);
      return date != null && date.year == now.year && date.month == now.month;
    }).toList();

    final expenseTransactions = monthlyTransactions.where((tx) => tx.isExpense).toList();
    final incomeTransactions = monthlyTransactions.where((tx) => !tx.isExpense).toList();

    final totalSpent = expenseTransactions.fold<double>(0, (sum, tx) => sum + tx.amount);
    final totalIncome = incomeTransactions.fold<double>(0, (sum, tx) => sum + tx.amount);
    final totalFlow = totalSpent + totalIncome;
    final spendingRatio = totalFlow == 0 ? 0.0 : (totalSpent / totalFlow).clamp(0.0, 1.0);

    final grouped = <String, List<TransactionModel>>{};
    for (final tx in expenseTransactions) {
      final label = _displayCategory(tx.category);
      grouped.putIfAbsent(label, () => []).add(tx);
    }

    final categories = grouped.entries.map((entry) {
      final spent = entry.value.fold<double>(0, (sum, tx) => sum + tx.amount);
      final style = _categoryStyle(entry.key);
      final percent = totalSpent == 0 ? 0.0 : (spent / totalSpent).clamp(0.0, 1.0);
      return _BudgetCategory(
        title: entry.key,
        spent: spent,
        percent: percent,
        color: style.color,
        icon: style.icon,
      );
    }).toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));

    return _BudgetSummary(
      totalSpent: totalSpent,
      referenceAmount: totalFlow == 0 ? totalSpent : totalFlow,
      spendingRatio: spendingRatio,
      categories: categories,
    );
  }

  static String _displayCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'food':
      case 'food & drink':
      case 'food & dining':
        return 'Food & Dining';
      case 'home':
        return 'Housing';
      default:
        return category.isEmpty ? 'Other' : category;
    }
  }

  static _CategoryStyle _categoryStyle(String category) {
    switch (category.trim().toLowerCase()) {
      case 'food':
      case 'food & drink':
      case 'food & dining':
        return const _CategoryStyle(
          icon: Icons.restaurant,
          color: Colors.orange,
        );
      case 'housing':
      case 'home':
        return const _CategoryStyle(
          icon: Icons.home,
          color: Color(0xFF1132D4),
        );
      case 'entertainment':
        return const _CategoryStyle(
          icon: Icons.movie,
          color: Colors.red,
        );
      case 'shopping':
        return const _CategoryStyle(
          icon: Icons.shopping_bag,
          color: Colors.green,
        );
      default:
        return const _CategoryStyle(
          icon: Icons.account_balance_wallet,
          color: Color(0xFF1132D4),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? theme.iconTheme.color : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Monthly Budget",
          style: TextStyle(
            color: isDark ? theme.textTheme.titleLarge?.color : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.more_vert,
              color: isDark ? theme.iconTheme.color : Colors.black,
            ),
          ),
        ],
      ),
      body: UserSession.user_id == null
          ? const Center(child: Text("User not logged in"))
          : FutureBuilder<_BudgetSummary>(
              future: futureBudget,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text("No budget data found."));
                }

                final summary = snapshot.data!;
                final topCategory = summary.categories.isEmpty ? null : summary.categories.first;
                final isNearLimit = summary.spendingRatio >= 0.8;
                final remaining =
                    (summary.referenceAmount - summary.totalSpent).clamp(0.0, double.infinity);
                final statusColor = isNearLimit ? Colors.orange : Colors.green;
                final statusIcon =
                    isNearLimit ? Icons.warning : Icons.check_circle;
                final statusText = isNearLimit ? "Near limit" : "On track";

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1132D4).withOpacity(0.15)
                              : const Color(0xFF1132D4).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Total Spent",
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currencyFormat.format(summary.totalSpent),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            Text(
                              "of ${currencyFormat.format(summary.referenceAmount)} budget",
                              style: const TextStyle(
                                color: Color(0xFF1132D4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Overall Progress",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                Text(
                                  "${(summary.spendingRatio * 100).toInt()}%",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1132D4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: summary.spendingRatio,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(20),
                              color: const Color(0xFF1132D4),
                              backgroundColor: isDark ? Colors.grey[800] : Colors.grey.shade300,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${currencyFormat.format(remaining)} remaining",
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey,
                                  ),
                                ),
                                if (topCategory != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(statusIcon, size: 14, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Category Budgets",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const Text(
                              "Edit All",
                              style: TextStyle(
                                color: Color(0xFF1132D4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (summary.categories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            "No expense data for this month.",
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey,
                            ),
                          ),
                        )
                      else
                        ...summary.categories.map(
                          (item) => budgetItem(
                            context,
                            icon: item.icon,
                            title: item.title,
                            spent:
                                "${currencyFormat.format(item.spent)} spent of ${currencyFormat.format(summary.referenceAmount)}",
                            percent: item.percent,
                            color: item.color,
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
    );
  }

  static Widget budgetItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String spent,
    required double percent,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          "${(percent * 100).toInt()}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      spent,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            borderRadius: BorderRadius.circular(20),
            color: color,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}

class _BudgetSummary {
  final double totalSpent;
  final double referenceAmount;
  final double spendingRatio;
  final List<_BudgetCategory> categories;

  const _BudgetSummary({
    required this.totalSpent,
    required this.referenceAmount,
    required this.spendingRatio,
    required this.categories,
  });
}

class _BudgetCategory {
  final String title;
  final double spent;
  final double percent;
  final Color color;
  final IconData icon;

  const _BudgetCategory({
    required this.title,
    required this.spent,
    required this.percent,
    required this.color,
    required this.icon,
  });
}

class _CategoryStyle {
  final IconData icon;
  final Color color;

  const _CategoryStyle({
    required this.icon,
    required this.color,
  });
}
