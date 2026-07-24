import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_base/controller/language_controller.dart';
import 'package:project_base/models/transaction_model.dart';
import 'package:project_base/utils/category_visuals.dart';

class WeeklyRecapScreen extends StatefulWidget {
  final List<TransactionModel> transactions;

  const WeeklyRecapScreen({super.key, required this.transactions});

  @override
  State<WeeklyRecapScreen> createState() => _WeeklyRecapScreenState();
}

class _WeeklyRecapScreenState extends State<WeeklyRecapScreen> {
  static const int _pageCount = 5;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final _WeeklyRecapData recap;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    recap = _WeeklyRecapData.fromTransactions(widget.transactions);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 0) return;
    if (page >= _pageCount) {
      Navigator.pop(context);
      return;
    }
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageController>();
    final t = language.text;
    final colors = _storyColors(_currentPage);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: List.generate(_pageCount, (index) {
                              return Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 4,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: BoxDecoration(
                                    color: index <= _currentPage
                                        ? Colors.white
                                        : Colors.white30,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        IconButton(
                          tooltip: t('close'),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pageCount,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                      },
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) {
                            final width = MediaQuery.sizeOf(context).width;
                            _goToPage(
                              details.localPosition.dx < width * 0.35
                                  ? _currentPage - 1
                                  : _currentPage + 1,
                            );
                          },
                          child: _buildStory(index, t, language.language.code),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                    child: Row(
                      children: [
                        if (_currentPage > 0)
                          IconButton.filledTonal(
                            onPressed: () => _goToPage(_currentPage - 1),
                            icon: const Icon(Icons.arrow_back),
                          ),
                        const Spacer(),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: colors.last,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 13,
                            ),
                          ),
                          onPressed: () => _goToPage(_currentPage + 1),
                          icon: Icon(
                            _currentPage == _pageCount - 1
                                ? Icons.check
                                : Icons.arrow_forward,
                          ),
                          label: Text(
                            _currentPage == _pageCount - 1
                                ? t('finish')
                                : t('next'),
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
      ),
    );
  }

  Widget _buildStory(
    int index,
    String Function(String) t,
    String languageCode,
  ) {
    switch (index) {
      case 0:
        return _storyLayout(
          icon: Icons.auto_awesome,
          eyebrow: t('weekly_recap'),
          title: t('recap_intro_title'),
          subtitle: t('recap_period')
              .replaceAll('{start}', _formatDate(recap.startDate))
              .replaceAll('{end}', _formatDate(recap.endDate)),
          child: Row(
            children: [
              Expanded(
                child: _metricCard(
                  t('expense'),
                  currencyFormat.format(recap.expense),
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  t('income_type'),
                  currencyFormat.format(recap.income),
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),
        );
      case 1:
        final changeText = recap.expenseChangePercent == null
            ? t('recap_no_previous_data')
            : t(
                recap.expenseChangePercent! > 0
                    ? 'recap_spending_up'
                    : 'recap_spending_down',
              ).replaceAll(
                '{percent}',
                recap.expenseChangePercent!.abs().round().toString(),
              );
        return _storyLayout(
          icon:
              recap.expenseChangePercent != null &&
                  recap.expenseChangePercent! > 0
              ? Icons.trending_up
              : Icons.trending_down,
          eyebrow: t('recap_week_comparison'),
          title: changeText,
          subtitle: t(
            'recap_transaction_count',
          ).replaceAll('{count}', recap.transactionCount.toString()),
          child: _comparisonBars(t),
        );
      case 2:
        final visual = categoryVisual(recap.topCategory);
        return _storyLayout(
          icon: visual.icon,
          eyebrow: t('recap_top_category'),
          title: recap.hasExpenses ? recap.topCategory : t('recap_no_expenses'),
          subtitle: recap.hasExpenses
              ? t('recap_category_share')
                    .replaceAll(
                      '{amount}',
                      currencyFormat.format(recap.topCategoryAmount),
                    )
                    .replaceAll(
                      '{percent}',
                      recap.topCategoryShare.round().toString(),
                    )
              : t('recap_no_expenses_body'),
          child: _categoryRing(visual.color),
        );
      case 3:
        return _storyLayout(
          icon: Icons.calendar_view_week,
          eyebrow: t('recap_daily_rhythm'),
          title: recap.hasExpenses
              ? t('recap_peak_day').replaceAll(
                  '{date}',
                  DateFormat('dd/MM').format(recap.peakDate),
                )
              : t('recap_no_expenses'),
          subtitle: recap.hasExpenses
              ? t('recap_peak_amount').replaceAll(
                  '{amount}',
                  currencyFormat.format(recap.peakAmount),
                )
              : t('recap_no_expenses_body'),
          child: _dailyBars(languageCode),
        );
      default:
        return _storyLayout(
          icon: Icons.flag_outlined,
          eyebrow: t('recap_next_week'),
          title: recap.hasExpenses
              ? t('recap_save_opportunity').replaceAll(
                  '{amount}',
                  currencyFormat.format(recap.savingOpportunity),
                )
              : t('recap_start_tracking'),
          subtitle: recap.hasExpenses
              ? t('recap_next_week_plan')
                    .replaceAll('{category}', recap.topCategory)
                    .replaceAll(
                      '{target}',
                      currencyFormat.format(recap.nextWeekTarget),
                    )
              : t('recap_start_tracking_body'),
          child: _actionCard(t),
        );
    }
  }

  Widget _storyLayout({
    required IconData icon,
    required String eyebrow,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 22),
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 26),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonBars(String Function(String) t) {
    final maxValue = math.max(recap.expense, recap.previousExpense);
    final currentRatio = maxValue <= 0 ? 0.05 : recap.expense / maxValue;
    final previousRatio = maxValue <= 0
        ? 0.05
        : recap.previousExpense / maxValue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _comparisonBar(
          t('previous_week'),
          recap.previousExpense,
          previousRatio,
          Colors.white38,
        ),
        const SizedBox(width: 28),
        _comparisonBar(
          t('this_week'),
          recap.expense,
          currentRatio,
          Colors.white,
        ),
      ],
    );
  }

  Widget _comparisonBar(
    String label,
    double amount,
    double ratio,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 72,
          height: 40 + 150 * ratio.clamp(0.0, 1.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _categoryRing(Color accent) {
    final progress = (recap.topCategoryShare / 100).clamp(0.0, 1.0);
    return Center(
      child: SizedBox(
        width: 210,
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 18,
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${recap.topCategoryShare.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Icon(Icons.pie_chart_outline, color: accent, size: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyBars(String languageCode) {
    final maxValue = recap.dailyExpenses.fold<double>(0, math.max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final amount = recap.dailyExpenses[index];
        final ratio = maxValue <= 0 ? 0.05 : amount / maxValue;
        final date = recap.startDate.add(Duration(days: index));
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (amount > 0)
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      NumberFormat.compact(locale: 'vi').format(amount),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 24 + 150 * ratio.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: date.day == recap.peakDate.day && amount > 0
                        ? Colors.white
                        : Colors.white38,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _weekdayLabel(date.weekday, languageCode),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _actionCard(String Function(String) t) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.savings_outlined, color: Colors.white, size: 42),
            const SizedBox(height: 14),
            Text(
              recap.hasExpenses
                  ? t(
                      'recap_action_tip',
                    ).replaceAll('{category}', recap.topCategory)
                  : t('recap_action_empty'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _storyColors(int page) {
    const gradients = [
      [Color(0xFF4F46E5), Color(0xFF1E1B4B)],
      [Color(0xFFDB2777), Color(0xFF701A75)],
      [Color(0xFFEA580C), Color(0xFF7C2D12)],
      [Color(0xFF0891B2), Color(0xFF164E63)],
      [Color(0xFF059669), Color(0xFF064E3B)],
    ];
    return gradients[page.clamp(0, gradients.length - 1)];
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM').format(date);

  String _weekdayLabel(int weekday, String languageCode) {
    const vi = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const ja = ['月', '火', '水', '木', '金', '土', '日'];
    final labels = languageCode == 'vi'
        ? vi
        : languageCode == 'ja'
        ? ja
        : en;
    return labels[weekday - 1];
  }
}

class _WeeklyRecapData {
  final DateTime startDate;
  final DateTime endDate;
  final double expense;
  final double income;
  final double previousExpense;
  final int transactionCount;
  final String topCategory;
  final double topCategoryAmount;
  final List<double> dailyExpenses;
  final DateTime peakDate;
  final double peakAmount;

  const _WeeklyRecapData({
    required this.startDate,
    required this.endDate,
    required this.expense,
    required this.income,
    required this.previousExpense,
    required this.transactionCount,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.dailyExpenses,
    required this.peakDate,
    required this.peakAmount,
  });

  bool get hasExpenses => expense > 0;

  double? get expenseChangePercent {
    if (previousExpense <= 0) return null;
    return (expense - previousExpense) / previousExpense * 100;
  }

  double get topCategoryShare =>
      expense <= 0 ? 0 : topCategoryAmount / expense * 100;

  double get savingOpportunity => topCategoryAmount * 0.1;

  double get nextWeekTarget =>
      math.max(expense - savingOpportunity, 0).toDouble();

  factory _WeeklyRecapData.fromTransactions(
    List<TransactionModel> transactions,
  ) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(const Duration(days: 6));
    final previousStart = startDate.subtract(const Duration(days: 7));
    final previousEnd = startDate.subtract(const Duration(days: 1));

    bool isWithin(DateTime date, DateTime start, DateTime end) {
      final day = DateTime(date.year, date.month, date.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }

    final current = transactions.where((tx) {
      final date = DateTime.tryParse(tx.date);
      return date != null && isWithin(date, startDate, endDate);
    }).toList();
    final previous = transactions.where((tx) {
      final date = DateTime.tryParse(tx.date);
      return date != null && isWithin(date, previousStart, previousEnd);
    }).toList();

    final expense = current
        .where((tx) => tx.isExpense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final income = current
        .where((tx) => !tx.isExpense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final previousExpense = previous
        .where((tx) => tx.isExpense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    final categoryTotals = <String, double>{};
    final dailyExpenses = List<double>.filled(7, 0);
    for (final tx in current.where((tx) => tx.isExpense)) {
      final category = tx.category.trim().isEmpty
          ? 'Other'
          : tx.category.trim();
      categoryTotals.update(
        category,
        (value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );

      final date = DateTime.tryParse(tx.date);
      if (date != null) {
        final day = DateTime(date.year, date.month, date.day);
        final index = day.difference(startDate).inDays;
        if (index >= 0 && index < dailyExpenses.length) {
          dailyExpenses[index] += tx.amount;
        }
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategory = sortedCategories.isEmpty
        ? 'Other'
        : sortedCategories.first.key;
    final topCategoryAmount = sortedCategories.isEmpty
        ? 0.0
        : sortedCategories.first.value;

    var peakIndex = 0;
    for (var index = 1; index < dailyExpenses.length; index++) {
      if (dailyExpenses[index] > dailyExpenses[peakIndex]) {
        peakIndex = index;
      }
    }

    return _WeeklyRecapData(
      startDate: startDate,
      endDate: endDate,
      expense: expense,
      income: income,
      previousExpense: previousExpense,
      transactionCount: current.length,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      dailyExpenses: dailyExpenses,
      peakDate: startDate.add(Duration(days: peakIndex)),
      peakAmount: dailyExpenses[peakIndex],
    );
  }
}
