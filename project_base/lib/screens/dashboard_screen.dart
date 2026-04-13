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
  static const double _chartMaxBarHeight = 95;

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

  _CategoryStyle _categoryStyle(String category) {
    switch (category.trim().toLowerCase()) {
      case 'food':
      case 'food & drink':
      case 'food & dining':
        return const _CategoryStyle(
          title: 'Food & Dining',
          icon: Icons.restaurant,
          color: Colors.orange,
        );
      case 'housing':
      case 'home':
        return const _CategoryStyle(
          title: 'Housing',
          icon: Icons.home,
          color: Color(0xFF1132D4),
        );
      case 'entertainment':
        return const _CategoryStyle(
          title: 'Entertainment',
          icon: Icons.movie,
          color: Colors.red,
        );
      case 'shopping':
        return const _CategoryStyle(
          title: 'Shopping',
          icon: Icons.shopping_bag,
          color: Colors.green,
        );
      default:
        return const _CategoryStyle(
          title: '',
          icon: Icons.attach_money,
          color: Color(0xFF1132D4),
        );
    }
  }

  DateTime? _parseTransactionDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final direct = DateTime.tryParse(trimmed);
    if (direct != null) return direct;

    for (final pattern in ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy/MM/dd']) {
      try {
        return DateFormat(pattern).parseStrict(trimmed);
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  List<_ChartDayData> _buildWeeklyExpenseData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = today.subtract(const Duration(days: 6));
    final expenseByDay = <DateTime, double>{};

    for (var i = 0; i < 7; i++) {
      final day = startDay.add(Duration(days: i));
      expenseByDay[day] = 0;
    }

    for (final tx in transactions) {
      if (!tx.isExpense) continue;

      final parsedDate = _parseTransactionDate(tx.date);
      if (parsedDate == null) continue;

      final txDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      if (txDay.isBefore(startDay) || txDay.isAfter(today)) continue;

      expenseByDay.update(txDay, (value) => value + tx.amount);
    }

    final maxAmount = expenseByDay.values.fold<double>(
      0,
      (current, value) => value > current ? value : current,
    );

    return expenseByDay.entries.map((entry) {
      final normalizedHeight = maxAmount == 0
          ? 8.0
          : (entry.value / maxAmount) * _chartMaxBarHeight;

      return _ChartDayData(
        label: DateFormat('E', 'en_US').format(entry.key),
        amount: entry.value,
        height: normalizedHeight.clamp(8.0, _chartMaxBarHeight).toDouble(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weeklyExpenseData = _buildWeeklyExpenseData();

    /// 🎯 COLOR SYSTEM (match Tailwind)
    const primary = Color(0xFF1132D4);
    final bg = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF6F6F8);
    final card = isDark ? theme.cardColor : Colors.white;
    final border = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = isDark ? Colors.white70 : Colors.grey;

    return Scaffold(
      backgroundColor: bg,

      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
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
                      backgroundImage: NetworkImage(
                        "https://i.pravatar.cc/150",
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "Welcome back,",
                            style: TextStyle(fontSize: 12, color: subText),
                          ),
                          Text(
                            widget.userName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: text,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(Icons.notifications, color: text),
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
                      const Text(
                        "Total Balance",
                        style: TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Text(
                            currencyFormat.format(totalBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "+2.4%",
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
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
                          ),
                        ],
                      ),
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
                          Text(
                            "Spending Summary",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: text,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Last 7 Days",
                              style: TextStyle(fontSize: 10, color: primary),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: weeklyExpenseData
                            .map(
                              (day) => chartBar(
                                height: day.height,
                                label: day.label,
                                amount: currencyFormat.format(day.amount),
                                textColor: subText,
                              ),
                            )
                            .toList(),
                      ),
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
                        Text(
                          "Recent Transactions",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: text,
                          ),
                        ),
                        const Text(
                          "See All",
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ...transactions.map((tx) {
                      final isExpense = tx.isExpense;
                      final amountColor = isExpense ? Colors.red : Colors.green;
                      final categoryStyle = _categoryStyle(tx.category);
                      final categoryLabel = categoryStyle.title.isEmpty
                          ? tx.category
                          : categoryStyle.title;

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
                              backgroundColor: categoryStyle.color.withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                categoryStyle.icon,
                                color: categoryStyle.color,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.description,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: text,
                                    ),
                                  ),
                                  Text(
                                    categoryLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subText,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              (isExpense ? "-" : "+") +
                                  currencyFormat.format(tx.amount),
                              style: TextStyle(
                                color: amountColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: text),
          ),
        ],
      ),
    );
  }

  static Widget chartBar({
    required double height,
    required String label,
    required String amount,
    required Color textColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, color: textColor),
            ),
            const SizedBox(height: 6),
            Container(
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFF1132D4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11, color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _ChartDayData {
  final String label;
  final double amount;
  final double height;

  const _ChartDayData({
    required this.label,
    required this.amount,
    required this.height,
  });
}

class _CategoryStyle {
  final String title;
  final IconData icon;
  final Color color;

  const _CategoryStyle({
    required this.title,
    required this.icon,
    required this.color,
  });
}
