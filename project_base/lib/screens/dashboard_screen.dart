import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'addtransaction_screen.dart';
import 'transaction_history.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import 'package:intl/intl.dart';
import 'package:project_base/controller/language_controller.dart';
import 'package:project_base/models/transaction_model.dart';
import 'package:project_base/utils/category_visuals.dart';

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
  double monthlyIncome = 0;
  double monthlyExpense = 0;

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
    final txList = await ApiService().getTransactions(UserSession.user_id!);
    txList.sort((a, b) {
      final dateA = _parseTransactionDate(a.date);
      final dateB = _parseTransactionDate(b.date);

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    double income = 0;
    double expense = 0;
    double currentMonthIncome = 0;
    double currentMonthExpense = 0;
    final now = DateTime.now();

    for (var tx in txList) {
      if (tx.isExpense) {
        expense += tx.amount;
      } else {
        income += tx.amount;
      }

      final date = _parseTransactionDate(tx.date);
      if (date != null && date.year == now.year && date.month == now.month) {
        if (tx.isExpense) {
          currentMonthExpense += tx.amount;
        } else {
          currentMonthIncome += tx.amount;
        }
      }
    }

    setState(() {
      transactions = txList;
      totalIncome = income;
      totalExpense = expense;
      totalBalance = income - expense;
      monthlyIncome = currentMonthIncome;
      monthlyExpense = currentMonthExpense;
    });
  }

  _CategoryStyle _categoryStyle(String category) {
    final visual = categoryVisual(category);
    return _CategoryStyle(
      title: visual.label,
      icon: visual.icon,
      color: visual.color,
    );
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

  double _monthlyTotal({required bool expense}) {
    return expense ? monthlyExpense : monthlyIncome;
  }

  void _openTransactionHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
    );
    if (mounted) loadTransactions();
  }

  void _showBalanceDetails() {
    final theme = Theme.of(context);
    final t = context.read<LanguageController>().text;
    final isDark = theme.brightness == Brightness.dark;
    const primary = Color(0xFF1132D4);
    final monthlyIncome = _monthlyTotal(expense: false);
    final monthlyExpense = _monthlyTotal(expense: true);
    final monthlyBalance = monthlyIncome - monthlyExpense;
    final savedRate = monthlyIncome <= 0
        ? 0
        : (monthlyBalance / monthlyIncome * 100).clamp(0, 100).round();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('balance_details'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(DateTime.now()),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _detailRow(
                    title: t('income_this_month'),
                    value: currencyFormat.format(monthlyIncome),
                    icon: Icons.arrow_upward,
                    color: const Color(0xFF059669),
                  ),
                  _detailRow(
                    title: t('expense_this_month'),
                    value: currencyFormat.format(monthlyExpense),
                    icon: Icons.arrow_downward,
                    color: const Color(0xFFDC2626),
                  ),
                  _detailRow(
                    title: t('month_balance'),
                    value: currencyFormat.format(monthlyBalance),
                    icon: Icons.savings_outlined,
                    color: primary,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      monthlyIncome <= 0
                          ? t('no_month_income_rate')
                          : t(
                              'keeping_income',
                            ).replaceAll('{rate}', savedRate.toString()),
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      iconColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _openTransactionHistory();
                    },
                    icon: const Icon(Icons.history),
                    label: Text(
                      t('view_transaction_history'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _monthlyBalanceNote() {
    final balance = monthlyIncome - monthlyExpense;
    final t = context.read<LanguageController>().text;
    if (monthlyIncome <= 0 && monthlyExpense <= 0) {
      return t('no_month_activity');
    }
    if (balance >= 0) {
      return t(
        'month_left',
      ).replaceAll('{amount}', currencyFormat.format(balance));
    }
    return t(
      'month_short',
    ).replaceAll('{amount}', currencyFormat.format(balance.abs()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<LanguageController>().text;
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
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
          if (result == true) loadTransactions();
        },
        child: const Icon(Icons.add, color: Colors.white),
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
                            t('welcome_back'),
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
                      Text(
                        t('available_balance'),
                        style: const TextStyle(color: Colors.white70),
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
                          Expanded(
                            child: Text(
                              _monthlyBalanceNote(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primary,
                            ),
                            onPressed: _showBalanceDetails,
                            child: Text(t('details')),
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
                        title: t('income'),
                        subtitle: DateFormat('MMM yyyy').format(DateTime.now()),
                        value: currencyFormat.format(monthlyIncome),
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
                        title: t('expenses'),
                        subtitle: DateFormat('MMM yyyy').format(DateTime.now()),
                        value: currencyFormat.format(monthlyExpense),
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
                            t('spending_summary'),
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
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              t('last_7_days'),
                              style: const TextStyle(
                                fontSize: 10,
                                color: primary,
                              ),
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
                          t('recent_transactions'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: text,
                          ),
                        ),
                        TextButton(
                          onPressed: _openTransactionHistory,
                          style: TextButton.styleFrom(
                            foregroundColor: primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            t('see_all'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ...transactions.take(5).map((tx) {
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
                              backgroundColor: categoryStyle.color.withValues(
                                alpha: 0.1,
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
                    }),
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

  Widget _detailRow({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget statCard({
    required String title,
    required String subtitle,
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
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: subText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
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
