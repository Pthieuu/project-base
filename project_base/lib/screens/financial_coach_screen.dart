import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controller/language_controller.dart';
import '../models/category_budget_model.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/financial_coach_service.dart';

class FinancialCoachScreen extends StatefulWidget {
  final List<TransactionModel> transactions;

  const FinancialCoachScreen({super.key, required this.transactions});

  @override
  State<FinancialCoachScreen> createState() => _FinancialCoachScreenState();
}

class _FinancialCoachScreenState extends State<FinancialCoachScreen> {
  late Future<FinancialCoachReport> _futureReport;
  final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _futureReport = _load();
  }

  Future<FinancialCoachReport> _load() async {
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    final budgets = await ApiService()
        .getBudgets(month)
        .catchError((_) => const <CategoryBudgetModel>[]);
    return FinancialCoachService().build(
      transactions: widget.transactions,
      budgets: budgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageController>().text;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: isDark ? theme.cardColor : Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(t('financial_coach')),
      ),
      body: FutureBuilder<FinancialCoachReport>(
        future: _futureReport,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _errorState(t, snapshot.error);
          }
          return _report(context, snapshot.data!, primary, isDark);
        },
      ),
    );
  }

  Widget _report(
    BuildContext context,
    FinancialCoachReport report,
    Color primary,
    bool isDark,
  ) {
    final t = context.read<LanguageController>().text;
    final theme = Theme.of(context);
    final riskColor = switch (report.riskLevel) {
      CoachRiskLevel.high => const Color(0xFFDC2626),
      CoachRiskLevel.medium => const Color(0xFFF59E0B),
      CoachRiskLevel.low => const Color(0xFF16A34A),
    };

    return RefreshIndicator(
      onRefresh: () async {
        final next = _load();
        setState(() => _futureReport = next);
        await next;
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.psychology_alt_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('coach_weekly_summary'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${DateFormat('dd/MM').format(report.weekStart)} – '
                            '${DateFormat('dd/MM').format(report.weekEnd)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _heroMetric(
                        t('expenses'),
                        _currency.format(report.weeklyExpense),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _heroMetric(
                        t('income'),
                        _currency.format(report.weeklyIncome),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  t(
                    'coach_based_on',
                  ).replaceAll('{count}', report.transactionCount.toString()),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle(t('coach_where_money_went'), Icons.route_rounded),
          const SizedBox(height: 10),
          if (report.moneyFlow.isEmpty)
            _emptyCard(t('coach_not_enough_data'))
          else
            ...report.moneyFlow.map(
              (item) => _findingCard(item, primary, isDark),
            ),
          const SizedBox(height: 18),
          _sectionTitle(t('coach_month_risk'), Icons.shield_outlined),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: riskColor.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                Icon(Icons.speed_rounded, color: riskColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${t('forecast')}: ${_currency.format(report.monthForecast)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                _riskBadge(t, report.riskLevel, riskColor),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...report.risks.map((item) => _findingCard(item, riskColor, isDark)),
          const SizedBox(height: 18),
          _sectionTitle(t('coach_actions'), Icons.task_alt_rounded),
          const SizedBox(height: 4),
          Text(t('coach_actions_subtitle'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          ...report.actions.indexed.map(
            (entry) => _actionCard(entry.$1 + 1, entry.$2, primary, isDark),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: primary, size: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    t('coach_data_limit'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _findingCard(CoachFinding item, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(item.detail),
          const SizedBox(height: 9),
          _evidence(item.evidence, color),
        ],
      ),
    );
  }

  Widget _actionCard(
    int number,
    CoachAction action,
    Color primary,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            child: Text(
              '$number',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(action.detail),
                const SizedBox(height: 9),
                _evidence(action.evidence, primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _evidence(String text, Color color) {
    final t = context.read<LanguageController>().text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.analytics_outlined, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${t('coach_evidence')}: $text',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskBadge(
    String Function(String) t,
    CoachRiskLevel level,
    Color color,
  ) {
    final key = switch (level) {
      CoachRiskLevel.high => 'coach_risk_high',
      CoachRiskLevel.medium => 'coach_risk_medium',
      CoachRiskLevel.low => 'coach_risk_low',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        t(key),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text),
    );
  }

  Widget _errorState(String Function(String) t, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(error?.toString() ?? t('coach_load_failed')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => setState(() => _futureReport = _load()),
              child: Text(t('retry')),
            ),
          ],
        ),
      ),
    );
  }
}
