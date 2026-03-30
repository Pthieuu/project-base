import 'package:flutter/material.dart';
import 'addtransaction_screen.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import 'package:intl/intl.dart';
import 'package:project_base/models/transaction_model.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  const DashboardScreen({super.key, required this.userName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<TransactionModel> transactions = [];

  double totalIncome = 0;
  double totalExpense = 0;
  double totalBalance = 0;

  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future loadTransactions() async {
    final txList = await ApiService().get_transactions(UserSession.user_id!);

    double income = 0;
    double expense = 0;

    for (var tx in txList) {
      if (tx.isExpense) {
        expense += tx.amount;
      } else {
        income += tx.amount;
      }
    }

    setState(() {
      transactions = txList;
      totalIncome = income;
      totalExpense = expense;
      totalBalance = income - expense;
    });
  }

  /// Map category name to icon
  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'shopping':
        return Icons.shopping_cart;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'salary':
        return Icons.attach_money;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primaryColor,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
          if (result == true) {
            loadTransactions();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// HEADER
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.cardColor,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3"),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Welcome back,", style: TextStyle(fontSize: 12, color: theme.hintColor)),
                          Text(widget.userName.isNotEmpty ? widget.userName : "User",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.notifications, color: theme.iconTheme.color),
                      onPressed: () {},
                    )
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// BALANCE CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1132D4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Balance", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(currencyFormat.format(totalBalance),
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(width: 10),
                        Chip(label: const Text("+2.4%"), backgroundColor: Colors.white24)
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("AI Insight", style: TextStyle(color: Colors.white70)),
                              SizedBox(height: 4),
                              Text("You're on track to save ₫500,000 more this month.", style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1132D4)),
                          onPressed: () {},
                          child: const Text("Details"),
                        )
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// INCOME / EXPENSE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: statCard(
                        context: context,
                        icon: Icons.arrow_downward,
                        color: Colors.green,
                        title: "Income",
                        value: currencyFormat.format(totalIncome),
                        percent: "+12%",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: statCard(
                        context: context,
                        icon: Icons.arrow_upward,
                        color: Colors.red,
                        title: "Expenses",
                        value: currencyFormat.format(totalExpense),
                        percent: "-5%",
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// SPENDING SUMMARY
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Spending Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                        Chip(label: const Text("This Week"), backgroundColor: const Color(0x221132D4))
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        chartBar(40),
                        chartBar(65),
                        chartBar(35),
                        chartBar(85),
                        chartBar(50),
                        chartBar(75),
                        chartBar(95),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// RECENT TRANSACTIONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                        const Text("See All", style: TextStyle(color: Color(0xFF1132D4), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final isExpense = tx.isExpense;
                        final icon = getCategoryIcon(tx.category);
                        return TransactionItem(
                          icon: icon,
                          title: tx.description,
                          category: tx.category.isNotEmpty ? tx.category : "No Category",
                          amount: isExpense
                              ? "-${currencyFormat.format(tx.amount)}"
                              : "+${currencyFormat.format(tx.amount)}",
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  /// STAT CARD
  static Widget statCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String percent,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: theme.hintColor)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.textTheme.bodyLarge?.color)),
          Text(percent, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  /// CHART BAR
  static Widget chartBar(double height) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: height,
        decoration: BoxDecoration(color: const Color(0xFF1132D4).withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String category;
  final String amount;

  const TransactionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.category,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: theme.primaryColor.withOpacity(0.1), child: Icon(icon, color: theme.primaryColor)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                Text(category, style: TextStyle(fontSize: 12, color: theme.hintColor)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }
}