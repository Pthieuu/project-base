import 'package:flutter/material.dart';
import 'package:project_base/models/transaction_model.dart';
import 'package:project_base/services/api_service.dart';
import 'package:project_base/services/user_session.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<TransactionModel>> futureTransactions;

  @override
  void initState() {
    super.initState();
    if (UserSession.user_id != null) {
      futureTransactions = ApiService().get_transactions(UserSession.user_id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? theme.iconTheme.color : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Transaction History",
          style: TextStyle(color: isDark ? theme.textTheme.titleLarge?.color : Colors.black),
        ),
        centerTitle: true,
      ),
      body: UserSession.user_id == null
          ? const Center(child: Text("User not logged in"))
          : FutureBuilder<List<TransactionModel>>(
              future: futureTransactions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No transactions found."));
                }

                final transactions = snapshot.data!;
                final now = DateTime.now();
                final today = DateFormat('yyyy-MM-dd').format(now);
                final yesterday = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

                final todayList = transactions.where((tx) => tx.date.startsWith(today)).toList();
                final yesterdayList = transactions.where((tx) => tx.date.startsWith(yesterday)).toList();

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      buildSummaryCard(transactions),
                      if (todayList.isNotEmpty) sectionTitle("Today", isDark),
                      ...todayList.map((tx) => TransactionTile.fromModel(tx)).toList(),
                      if (yesterdayList.isNotEmpty) sectionTitle("Yesterday", isDark),
                      ...yesterdayList.map((tx) => TransactionTile.fromModel(tx)).toList(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Build summary card
  Widget buildSummaryCard(List<TransactionModel> transactions) {
    double totalBalance = 0;
    double totalIncome = 0;
    double totalExpense = 0;

    for (var tx in transactions) {
      if (tx.isExpense) {
        totalExpense += tx.amount;
        totalBalance -= tx.amount;
      } else {
        totalIncome += tx.amount;
        totalBalance += tx.amount;
      }
    }

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1132D4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Balance", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            formatter.format(totalBalance),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CardStat(
                  title: "Income",
                  value: formatter.format(totalIncome),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CardStat(
                  title: "Expenses",
                  value: formatter.format(totalExpense),
                  color: Colors.red,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  static Widget sectionTitle(String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? Colors.grey[850] : Colors.grey.shade200,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: isDark ? Colors.grey[400] : Colors.grey,
        ),
      ),
    );
  }
}

/// Small card stat
class CardStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const CardStat({super.key, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String category;
  final String amount;

  const TransactionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.category,
    required this.amount,
  });

  factory TransactionTile.fromModel(TransactionModel tx) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final categoryStyle = _categoryStyle(tx.category);
    final displayCategory = _displayCategory(tx.category);
    final displayName = displayCategory == "Food & Dining"
        ? "Food & Dining"
        : tx.description;

    return TransactionTile(
      icon: categoryStyle.icon,
      iconColor: categoryStyle.color,
      name: displayName,
      category: "$displayCategory • ${tx.date.substring(11, 16)}",
      amount: "${tx.isExpense ? '-' : '+'}${formatter.format(tx.amount)}",
    );
  }

  static String _displayCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'food':
      case 'food & drink':
      case 'food & dining':
        return 'Food & Dining';
      default:
        return category;
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
          icon: Icons.payment,
          color: Color(0xFF1132D4),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    /// 🔥 xác định income / expense
    final isExpense = amount.startsWith('-');

    /// 🎨 màu số tiền theo income / expense
    final amountColor = isExpense
        ? (isDark ? Colors.red[300]! : Colors.red)
        : (isDark ? Colors.green[300]! : Colors.green);

    /// 🎨 background icon
    final bgColor = iconColor.withOpacity(isDark ? 0.2 : 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),

        /// ✨ shadow nhẹ cho light mode
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Row(
        children: [
          /// ICON
          CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(icon, color: iconColor),
          ),

          const SizedBox(width: 12),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),

          /// AMOUNT
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStyle {
  final IconData icon;
  final Color color;

  const _CategoryStyle({
    required this.icon,
    required this.color,
  });
}
