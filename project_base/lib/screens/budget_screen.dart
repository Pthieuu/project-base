import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_base/screens/recurring_transactions_screen.dart';
import 'package:project_base/screens/saving_goals_screen.dart';
import 'package:project_base/services/api_service.dart';
import 'package:project_base/services/user_session.dart';
import 'package:project_base/utils/category_visuals.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  static const Color _primary = Color(0xFF1132D4);
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

  String get _currentMonthKey {
    final now = DateTime.now();
    return DateFormat('yyyy-MM').format(now);
  }

  void _reload() {
    setState(() {
      futureBudget = _loadBudgetSummary();
    });
  }

  Future<_BudgetSummary> _loadBudgetSummary() async {
    if (UserSession.user_id == null) {
      throw Exception("User not logged in");
    }

    final api = ApiService();
    final transactions = await api.getTransactions(UserSession.user_id!);
    final categories = await api.getCategories();
    final budgets = await api.getBudgets(_currentMonthKey);
    final now = DateTime.now();

    final monthlyExpenses = transactions.where((tx) {
      final date = DateTime.tryParse(tx.date);
      return tx.isExpense &&
          date != null &&
          date.year == now.year &&
          date.month == now.month;
    }).toList();

    final spentByCategory = <String, double>{};
    for (final tx in monthlyExpenses) {
      final label = _displayCategory(tx.category);
      spentByCategory[label] = (spentByCategory[label] ?? 0) + tx.amount;
    }

    final budgetByCategory = {
      for (final item in budgets)
        _displayCategory(item.category): item.monthlyLimit,
    };

    final categoryNames = <String>{
      ...categories
          .where((item) => item.type == 'expense' || item.type == 'both')
          .map((item) => _displayCategory(item.name)),
      ...spentByCategory.keys,
      ...budgetByCategory.keys,
    }.toList()..sort();

    final budgetCategories =
        categoryNames.map((name) {
          final spent = spentByCategory[name] ?? 0;
          final limit = budgetByCategory[name] ?? 0;
          final style = _categoryStyle(name);
          final percent = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);

          return _BudgetCategory(
            title: name,
            spent: spent,
            monthlyLimit: limit,
            percent: percent,
            color: _statusColor(percent, limit),
            icon: style.icon,
          );
        }).toList()..sort((a, b) {
          if (a.monthlyLimit == 0 && b.monthlyLimit > 0) return 1;
          if (a.monthlyLimit > 0 && b.monthlyLimit == 0) return -1;
          return b.spent.compareTo(a.spent);
        });

    final totalSpent = budgetCategories.fold<double>(
      0,
      (sum, item) => sum + item.spent,
    );
    final totalBudget = budgetCategories.fold<double>(
      0,
      (sum, item) => sum + item.monthlyLimit,
    );
    final overallProgress = totalBudget <= 0
        ? 0.0
        : (totalSpent / totalBudget).clamp(0.0, 1.0);

    return _BudgetSummary(
      monthLabel: DateFormat('MM/yyyy').format(now),
      totalSpent: totalSpent,
      totalBudget: totalBudget,
      overallProgress: overallProgress,
      categories: budgetCategories,
    );
  }

  static Color _statusColor(double percent, double limit) {
    if (limit <= 0) return _primary;
    if (percent >= 1) return const Color(0xFFDC2626);
    if (percent >= 0.8) return Colors.orange;
    return Colors.green;
  }

  static String _displayCategory(String category) {
    return displayCategoryName(category);
  }

  static _CategoryStyle _categoryStyle(String category) {
    final visual = categoryVisual(category);
    return _CategoryStyle(icon: visual.icon, color: visual.color);
  }

  Future<void> _editBudget(_BudgetCategory item) async {
    final controller = TextEditingController(
      text: item.monthlyLimit <= 0 ? '' : item.monthlyLimit.toStringAsFixed(0),
    );

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;
        final card = isDark ? theme.cardColor : Colors.white;
        final text = isDark ? Colors.white : const Color(0xFF0F172A);

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHeader(
                  icon: item.icon,
                  title: item.title,
                  subtitle: "Monthly spending limit",
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: text,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: "Monthly limit",
                      prefixIcon: const Icon(Icons.savings),
                      suffixText: "VND",
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF6F6F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final amount =
                              double.tryParse(
                                controller.text
                                    .replaceAll(".", "")
                                    .replaceAll(",", ""),
                              ) ??
                              0;
                          Navigator.pop(sheetContext, amount);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;

    await ApiService().saveBudget(
      category: item.title,
      month: _currentMonthKey,
      monthlyLimit: result,
    );
    _reload();
  }

  Widget _sheetHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBudgetTools() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHeader(
                  icon: Icons.tune,
                  title: "Budget tools",
                  subtitle: "Manage plans beyond monthly limits",
                ),
                const SizedBox(height: 14),
                _toolOption(
                  sheetContext,
                  icon: Icons.savings,
                  title: "Saving Goals",
                  subtitle: "Track targets like trips, laptop, emergency fund.",
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavingGoalsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _toolOption(
                  sheetContext,
                  icon: Icons.event_repeat,
                  title: "Recurring Transactions",
                  subtitle:
                      "Plan salary, rent, subscriptions, and fixed bills.",
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecurringTransactionsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _toolOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF6F6F8);
    final card = isDark ? theme.cardColor : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 0,
        title: Text(
          "Monthly Budget",
          style: TextStyle(color: text, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Budget tools",
            icon: Icon(Icons.more_vert, color: text),
            onPressed: _showBudgetTools,
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
                final remaining = (summary.totalBudget - summary.totalSpent)
                    .clamp(0.0, double.infinity);

                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      _summaryCard(context, summary, remaining),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                            Text(
                              summary.monthLabel,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (summary.categories.isEmpty)
                        _emptyCard(
                          context,
                          icon: Icons.category,
                          title: "No categories yet",
                          message:
                              "Add categories from Add Transaction to set monthly limits.",
                        )
                      else
                        ...summary.categories.map(
                          (item) => _budgetItem(context, item),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    _BudgetSummary summary,
    double remaining,
  ) {
    final hasBudget = summary.totalBudget > 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Spent this month",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      summary.monthLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            currencyFormat.format(summary.totalSpent),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            hasBudget
                ? "of ${currencyFormat.format(summary.totalBudget)} planned"
                : "Set category budgets to track limits",
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: summary.overallProgress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 8),
          Text(
            hasBudget
                ? "${currencyFormat.format(remaining)} remaining"
                : "No monthly limits yet",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _budgetItem(BuildContext context, _BudgetCategory item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitle = item.monthlyLimit <= 0
        ? "${currencyFormat.format(item.spent)} spent - no limit"
        : "${currencyFormat.format(item.spent)} spent of ${currencyFormat.format(item.monthlyLimit)}";

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
                backgroundColor: item.color.withValues(alpha: 0.1),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _editBudget(item),
                child: const Text(
                  "Edit",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: item.percent,
            minHeight: 6,
            borderRadius: BorderRadius.circular(20),
            color: item.color,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _primary.withValues(alpha: 0.1),
            child: Icon(icon, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSummary {
  final String monthLabel;
  final double totalSpent;
  final double totalBudget;
  final double overallProgress;
  final List<_BudgetCategory> categories;

  const _BudgetSummary({
    required this.monthLabel,
    required this.totalSpent,
    required this.totalBudget,
    required this.overallProgress,
    required this.categories,
  });
}

class _BudgetCategory {
  final String title;
  final double spent;
  final double monthlyLimit;
  final double percent;
  final Color color;
  final IconData icon;

  const _BudgetCategory({
    required this.title,
    required this.spent,
    required this.monthlyLimit,
    required this.percent,
    required this.color,
    required this.icon,
  });
}

class _CategoryStyle {
  final IconData icon;
  final Color color;

  const _CategoryStyle({required this.icon, required this.color});
}
