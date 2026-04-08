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

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    /// 🎯 COLOR SYSTEM (match Tailwind)
    const primary = Color(0xFF1132D4);
    final bg = isDark ? const Color(0xFF101322) : const Color(0xFFF6F6F8);
    final card = isDark ? const Color(0xFF0F172A) : Colors.white;
    final border = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = Colors.grey;

    return Scaffold(
      backgroundColor: bg,

      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
          if (result == true) loadTransactions();
        },
        child: const Icon(Icons.add),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              /// ================= HEADER =================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  border: Border(bottom: BorderSide(color: border)),
                ),
                child: Row(
                  children: [

                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage("https://i.pravatar.cc/150"),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        children: [
                          Text("Welcome back,", style: TextStyle(fontSize: 12, color: subText)),
                          Text(widget.userName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: text)),
                        ],
                      ),
                    ),

                    Icon(Icons.notifications, color: text)
                  ],
                ),
              ),

              /// ================= BALANCE =================
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text("Total Balance", style: TextStyle(color: Colors.white70)),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Text(currencyFormat.format(totalBalance),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),

                          const SizedBox(width: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text("+2.4%", style: TextStyle(fontSize: 10)),
                          )
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "You're on track to save ₫500,000 more this month.",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primary,
                            ),
                            onPressed: () {},
                            child: const Text("Details"),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),

              /// ================= STATS =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [

                    Expanded(
                      child: statCard(
                        title: "Income",
                        value: currencyFormat.format(totalIncome),
                        icon: Icons.arrow_downward,
                        color: Colors.green,
                        card: card,
                        text: text,
                        subText: subText,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: statCard(
                        title: "Expenses",
                        value: currencyFormat.format(totalExpense),
                        icon: Icons.arrow_upward,
                        color: Colors.red,
                        card: card,
                        text: text,
                        subText: subText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// ================= CHART =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Spending Summary",
                              style: TextStyle(fontWeight: FontWeight.bold, color: text)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text("This Week",
                                style: TextStyle(fontSize: 10, color: primary)),
                          )
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
              ),

              const SizedBox(height: 20),

              /// ================= TRANSACTIONS =================
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Recent Transactions",
                            style: TextStyle(fontWeight: FontWeight.bold, color: text)),
                        const Text("See All",
                            style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ...transactions.map((tx) {
                      final isExpense = tx.isExpense;
                      final color = isExpense ? Colors.red : Colors.green;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [

                            CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(Icons.attach_money, color: color),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tx.description,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: text)),
                                  Text(tx.category,
                                      style: TextStyle(fontSize: 12, color: subText)),
                                ],
                              ),
                            ),

                            Text(
                              (isExpense ? "-" : "+") + currencyFormat.format(tx.amount),
                              style: TextStyle(color: color, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      );
                    }).toList()
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= COMPONENT =================

  static Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color card,
    required Color text,
    required Color subText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(color: subText, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: text)),
        ],
      ),
    );
  }

  static Widget chartBar(double height) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1132D4),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}