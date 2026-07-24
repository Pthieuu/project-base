import 'dart:math' as math;

import '../models/category_budget_model.dart';
import '../models/transaction_model.dart';

enum CoachRiskLevel { low, medium, high }

class FinancialCoachReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double weeklyExpense;
  final double weeklyIncome;
  final double previousWeeklyExpense;
  final String topCategory;
  final double topCategoryAmount;
  final double monthExpense;
  final double monthIncome;
  final double monthForecast;
  final CoachRiskLevel riskLevel;
  final List<CoachFinding> moneyFlow;
  final List<CoachFinding> risks;
  final List<CoachAction> actions;
  final int transactionCount;

  const FinancialCoachReport({
    required this.weekStart,
    required this.weekEnd,
    required this.weeklyExpense,
    required this.weeklyIncome,
    required this.previousWeeklyExpense,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.monthExpense,
    required this.monthIncome,
    required this.monthForecast,
    required this.riskLevel,
    required this.moneyFlow,
    required this.risks,
    required this.actions,
    required this.transactionCount,
  });

  bool get hasData => transactionCount > 0;
}

class CoachFinding {
  final String type;
  final String title;
  final String detail;
  final String evidence;
  final CoachRiskLevel level;

  const CoachFinding({
    required this.type,
    required this.title,
    required this.detail,
    required this.evidence,
    this.level = CoachRiskLevel.low,
  });
}

class CoachAction {
  final String title;
  final String detail;
  final String evidence;

  const CoachAction({
    required this.title,
    required this.detail,
    required this.evidence,
  });
}

class FinancialCoachService {
  FinancialCoachReport build({
    required List<TransactionModel> transactions,
    required List<CategoryBudgetModel> budgets,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final previousStart = weekStart.subtract(const Duration(days: 7));
    final previousEnd = weekStart.subtract(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    DateTime? parseDate(String raw) {
      final parsed = DateTime.tryParse(raw.trim());
      return parsed == null
          ? null
          : DateTime(parsed.year, parsed.month, parsed.day);
    }

    bool between(DateTime? value, DateTime start, DateTime end) =>
        value != null && !value.isBefore(start) && !value.isAfter(end);

    final currentWeek = transactions
        .where((tx) => between(parseDate(tx.date), weekStart, today))
        .toList();
    final previousWeek = transactions
        .where((tx) => between(parseDate(tx.date), previousStart, previousEnd))
        .toList();
    final month = transactions
        .where((tx) => between(parseDate(tx.date), monthStart, today))
        .toList();

    double sum(Iterable<TransactionModel> items) =>
        items.fold(0, (total, tx) => total + tx.amount);

    final weeklyExpenses = currentWeek.where((tx) => tx.isExpense);
    final weeklyExpense = sum(weeklyExpenses);
    final weeklyIncome = sum(currentWeek.where((tx) => !tx.isExpense));
    final previousWeeklyExpense = sum(previousWeek.where((tx) => tx.isExpense));
    final monthExpenses = month.where((tx) => tx.isExpense).toList();
    final monthExpense = sum(monthExpenses);
    final monthIncome = sum(month.where((tx) => !tx.isExpense));
    final monthForecast = now.day <= 0
        ? monthExpense
        : monthExpense / now.day * monthEnd.day;

    final weeklyCategories = _categoryTotals(weeklyExpenses);
    final monthCategories = _categoryTotals(monthExpenses);
    final sortedWeek = weeklyCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedMonth = monthCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategory = sortedWeek.isEmpty ? 'Other' : sortedWeek.first.key;
    final topCategoryAmount = sortedWeek.isEmpty ? 0.0 : sortedWeek.first.value;

    final moneyFlow = <CoachFinding>[];
    if (weeklyExpense > 0) {
      final share = weeklyExpense == 0
          ? 0
          : topCategoryAmount / weeklyExpense * 100;
      moneyFlow.add(
        CoachFinding(
          type: 'category',
          title: topCategory,
          detail: '${share.round()}% of weekly expenses',
          evidence:
              '${weeklyExpenses.length} expense transactions in the last 7 days',
        ),
      );
    }
    if (previousWeeklyExpense > 0) {
      final change =
          (weeklyExpense - previousWeeklyExpense) / previousWeeklyExpense * 100;
      moneyFlow.add(
        CoachFinding(
          type: 'trend',
          title: change >= 0
              ? 'Weekly spending increased'
              : 'Weekly spending decreased',
          detail: '${change.abs().round()}% versus the previous 7 days',
          evidence:
              '${_amount(weeklyExpense)} now vs ${_amount(previousWeeklyExpense)} before',
          level: change > 20 ? CoachRiskLevel.medium : CoachRiskLevel.low,
        ),
      );
    }

    final risks = <CoachFinding>[];
    var riskLevel = CoachRiskLevel.low;
    if (monthIncome > 0 && monthForecast > monthIncome) {
      riskLevel = CoachRiskLevel.high;
      risks.add(
        CoachFinding(
          type: 'cash_flow',
          title: 'Forecast expenses may exceed income',
          detail:
              'Projected by ${_amount(monthForecast - monthIncome)} at the current pace',
          evidence:
              '${_amount(monthExpense)} spent through day ${now.day}; forecast ${_amount(monthForecast)}',
          level: CoachRiskLevel.high,
        ),
      );
    } else if (monthIncome > 0 && monthForecast > monthIncome * 0.85) {
      riskLevel = CoachRiskLevel.medium;
      risks.add(
        CoachFinding(
          type: 'cash_flow',
          title: 'Low month-end buffer',
          detail: 'Forecast expenses use over 85% of recorded income',
          evidence:
              'Forecast ${_amount(monthForecast)} vs income ${_amount(monthIncome)}',
          level: CoachRiskLevel.medium,
        ),
      );
    }

    for (final budget in budgets) {
      final spent = monthCategories[budget.category] ?? 0;
      if (budget.monthlyLimit > 0 && spent > budget.monthlyLimit) {
        riskLevel = CoachRiskLevel.high;
        risks.add(
          CoachFinding(
            type: 'budget',
            title: '${budget.category} is over budget',
            detail: 'Exceeded by ${_amount(spent - budget.monthlyLimit)}',
            evidence:
                '${_amount(spent)} spent vs ${_amount(budget.monthlyLimit)} limit',
            level: CoachRiskLevel.high,
          ),
        );
      }
    }

    if (risks.isEmpty) {
      risks.add(
        CoachFinding(
          type: 'stable',
          title: month.isEmpty
              ? 'Not enough data to assess risk'
              : 'No major risk detected',
          detail: month.isEmpty
              ? 'Record transactions to improve the assessment'
              : 'Recorded cash flow is currently within the observed range',
          evidence: '${month.length} transactions recorded this month',
        ),
      );
    }

    final actions = <CoachAction>[];
    if (sortedMonth.isNotEmpty) {
      final category = sortedMonth.first;
      final target = category.value * 0.1;
      actions.add(
        CoachAction(
          title: 'Set a 10% guardrail for ${category.key}',
          detail:
              'Pause and review the next non-essential purchase in this category.',
          evidence:
              '${category.key} is the largest month category at ${_amount(category.value)}; 10% is ${_amount(target)}',
        ),
      );
    }
    final overBudget = risks.where((item) => item.type == 'budget').firstOrNull;
    if (overBudget != null) {
      actions.add(
        CoachAction(
          title: 'Review the exceeded budget today',
          detail:
              'Check whether the latest expenses were essential or movable.',
          evidence: overBudget.evidence,
        ),
      );
    }
    if (monthIncome <= 0) {
      actions.add(
        CoachAction(
          title: 'Record this month’s income',
          detail:
              'A risk forecast needs income to estimate the remaining buffer.',
          evidence: 'No income transaction is recorded this month',
        ),
      );
    } else if (monthForecast > monthIncome * 0.85) {
      actions.add(
        CoachAction(
          title: 'Use a weekly spending ceiling',
          detail:
              'Keep next week below ${_amount(math.max(0, monthIncome - monthExpense) / math.max(1, (monthEnd.day - now.day) / 7))}.',
          evidence:
              'Current forecast is ${_amount(monthForecast)} against ${_amount(monthIncome)} income',
        ),
      );
    }
    if (actions.isEmpty) {
      actions.add(
        CoachAction(
          title: 'Keep recording transactions for 7 more days',
          detail: 'More complete data produces a more reliable recommendation.',
          evidence: '${month.length} transactions recorded this month',
        ),
      );
    }

    return FinancialCoachReport(
      weekStart: weekStart,
      weekEnd: today,
      weeklyExpense: weeklyExpense,
      weeklyIncome: weeklyIncome,
      previousWeeklyExpense: previousWeeklyExpense,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      monthExpense: monthExpense,
      monthIncome: monthIncome,
      monthForecast: monthForecast,
      riskLevel: riskLevel,
      moneyFlow: moneyFlow.take(3).toList(),
      risks: risks.take(3).toList(),
      actions: actions.take(3).toList(),
      transactionCount: currentWeek.length,
    );
  }

  Map<String, double> _categoryTotals(Iterable<TransactionModel> transactions) {
    final totals = <String, double>{};
    for (final tx in transactions) {
      final category = tx.category.trim().isEmpty
          ? 'Other'
          : tx.category.trim();
      totals.update(
        category,
        (value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }
    return totals;
  }

  String _amount(double value) => '${value.round()} VND';
}
