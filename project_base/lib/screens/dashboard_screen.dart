import 'dart:math' as math;

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

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
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

  late final AnimationController _chartAnimationController;
  late final Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeOutCubic,
    );
    loadTransactions();
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
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

    if (!mounted) return;
    setState(() {
      transactions = txList;
      totalIncome = income;
      totalExpense = expense;
      totalBalance = income - expense;
      monthlyIncome = currentMonthIncome;
      monthlyExpense = currentMonthExpense;
    });
    _chartAnimationController.forward(from: 0);
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

  List<_SpendingCategoryData> _buildCategoryExpenseData() {
    final now = DateTime.now();
    final totals = <String, double>{};

    for (final tx in transactions) {
      if (!tx.isExpense) continue;

      final parsedDate = _parseTransactionDate(tx.date);
      if (parsedDate == null) continue;
      if (parsedDate.year != now.year || parsedDate.month != now.month) {
        continue;
      }

      final label = _categoryStyle(tx.category).title;
      totals.update(
        label,
        (value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final visibleEntries = entries.take(5).toList();
    final otherTotal = entries
        .skip(5)
        .fold<double>(0, (sum, item) => sum + item.value);
    if (otherTotal > 0) {
      visibleEntries.add(MapEntry('Other', otherTotal));
    }

    final total = visibleEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );
    return visibleEntries.map((entry) {
      final style = _categoryStyle(entry.key);
      return _SpendingCategoryData(
        label: entry.key,
        amount: entry.value,
        percent: total <= 0 ? 0 : entry.value / total,
        color: _chartColorFor(style.title),
        icon: style.icon,
      );
    }).toList();
  }

  Color _chartColorFor(String category) {
    final key = category.toLowerCase();
    if (key.contains('food') || key.contains('dining')) {
      return const Color(0xFF5B7CFA);
    }
    if (key.contains('coffee')) {
      return const Color(0xFF6F8DE8);
    }
    if (key.contains('transport')) {
      return const Color(0xFF4AA6B5);
    }
    if (key.contains('sport')) {
      return const Color(0xFF3F66D6);
    }
    if (key.contains('shopping')) {
      return const Color(0xFF7E68D8);
    }
    if (key.contains('housing')) {
      return const Color(0xFF1132D4);
    }
    if (key.contains('entertainment')) {
      return const Color(0xFF8068C9);
    }
    if (key.contains('health')) {
      return const Color(0xFF49A98C);
    }
    if (key.contains('education')) {
      return const Color(0xFF4C9BCB);
    }
    return const Color(0xFF7B8BA8);
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
    final categoryExpenseData = _buildCategoryExpenseData();

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
                              t('this_month'),
                              style: const TextStyle(
                                fontSize: 10,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      if (categoryExpenseData.isEmpty)
                        _emptySpendingChart(context, subText)
                      else
                        _categorySpendingChart(
                          data: categoryExpenseData,
                          total: monthlyExpense,
                          text: text,
                          subText: subText,
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
                      final date = _parseTransactionDate(tx.date);
                      final timeLabel = date == null
                          ? tx.date
                          : DateFormat('dd/MM/yyyy HH:mm').format(date);

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
                                    "$categoryLabel • $timeLabel",
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

  Widget _emptySpendingChart(BuildContext context, Color subText) {
    final t = context.watch<LanguageController>().text;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline, size: 42, color: subText),
          const SizedBox(height: 10),
          Text(
            t('no_month_activity'),
            textAlign: TextAlign.center,
            style: TextStyle(color: subText),
          ),
        ],
      ),
    );
  }

  Widget _categorySpendingChart({
    required List<_SpendingCategoryData> data,
    required double total,
    required Color text,
    required Color subText,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _chartAnimation,
                      builder: (context, _) {
                        return Transform.scale(
                          scale: 0.96 + (_chartAnimation.value * 0.04),
                          child: CustomPaint(
                            size: const Size(170, 170),
                            painter: _DonutChartPainter(
                              data,
                              progress: _chartAnimation.value,
                            ),
                          ),
                        );
                      },
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencyFormat.format(total),
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM yyyy').format(DateTime.now()),
                          style: TextStyle(color: subText, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 118,
              child: AnimatedBuilder(
                animation: _chartAnimation,
                builder: (context, _) {
                  final opacity = _chartAnimation.value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(16 * (1 - _chartAnimation.value), 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: data.take(5).map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: text,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(item.percent * 100).round()}%',
                                  style: TextStyle(
                                    color: subText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (data.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '+${data.length - 5}',
                style: TextStyle(
                  color: subText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<_SpendingCategoryData> data;
  final double progress;

  const _DonutChartPainter(this.data, {required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 18.0;

    final backgroundPaint = Paint()
      ..color = const Color(0xFFDDE5F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, backgroundPaint);

    var start = -math.pi / 2;
    for (final item in data) {
      final sweep = math.max(item.percent * math.pi * 2 * progress, 0.0);
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + 0.035;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.progress != progress;
  }
}

class _SpendingCategoryData {
  final String label;
  final double amount;
  final double percent;
  final Color color;
  final IconData icon;

  const _SpendingCategoryData({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
    required this.icon,
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
