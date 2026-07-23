import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_base/controller/language_controller.dart';
import 'package:project_base/models/transaction_model.dart';
import 'package:project_base/services/ai_chat_service.dart';
import 'package:project_base/services/api_service.dart';
import 'package:project_base/services/user_session.dart';
import 'package:project_base/utils/category_visuals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  static int? _chatSessionUserId;
  static final List<_ChatMessage> _chatSessionMessages = [];

  static void clearSessionChat() {
    _chatSessionUserId = null;
    _chatSessionMessages.clear();
  }

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late Future<_InsightsData> futureInsights;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late final List<_ChatMessage> messages;
  final AiChatService aiChatService = AiChatService();
  _InsightsData? currentInsights;
  List<TransactionModel> currentTransactions = [];
  bool isSending = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    if (InsightsScreen._chatSessionUserId != UserSession.user_id) {
      InsightsScreen._chatSessionUserId = UserSession.user_id;
      InsightsScreen._chatSessionMessages.clear();
    }
    messages = InsightsScreen._chatSessionMessages;
    futureInsights = _loadInsights();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<_InsightsData> _loadInsights() async {
    if (UserSession.user_id == null) {
      throw Exception("User is not logged in");
    }

    final prefs = await SharedPreferences.getInstance();
    final aiEnabled =
        prefs.getBool(
          'profile_ai_insights_${UserSession.user_id ?? 'local'}',
        ) ??
        true;

    if (!aiEnabled) {
      currentTransactions = [];
      if (messages.isEmpty) {
        messages.add(
          _ChatMessage(
            text:
                "AI Insights is turned off in Profile. Turn it back on when you want smart spending analysis and chat-based data entry.",
            isUser: false,
          ),
        );
      }
      return _InsightsData.disabled();
    }

    final transactions = await ApiService().getTransactions(
      UserSession.user_id!,
    );
    currentTransactions = transactions;
    final data = _buildInsights(transactions);

    if (messages.isEmpty) {
      messages.addAll([
        _ChatMessage(
          text:
              "I reviewed your recent transactions. Your highest spending category this month is ${data.topCategoryName}, and at the current pace you may spend around ${currencyFormat.format(data.predictedSpend)} by month end.",
          isUser: false,
        ),
        _ChatMessage(
          text:
              "You can ask me about overspending, spending categories, month-end forecasts, or ways to save.",
          isUser: false,
        ),
      ]);
    }

    currentInsights = data;
    return data;
  }

  _InsightsData _buildInsights(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final currentMonth = transactions.where((tx) {
      final date = DateTime.tryParse(tx.date);
      return date != null && date.year == now.year && date.month == now.month;
    }).toList();

    final previousMonthDate = DateTime(now.year, now.month - 1, 1);
    final previousMonth = transactions.where((tx) {
      final date = DateTime.tryParse(tx.date);
      return date != null &&
          date.year == previousMonthDate.year &&
          date.month == previousMonthDate.month;
    }).toList();

    final currentExpenses = currentMonth.where((tx) => tx.isExpense).toList();
    final previousExpenses = previousMonth.where((tx) => tx.isExpense).toList();

    final currentSpent = currentExpenses.fold<double>(
      0,
      (sum, tx) => sum + tx.amount,
    );
    final previousSpent = previousExpenses.fold<double>(
      0,
      (sum, tx) => sum + tx.amount,
    );

    final currentByCategory = _groupCategoryTotals(currentExpenses);
    final previousByCategory = _groupCategoryTotals(previousExpenses);

    final sortedCategories = currentByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategoryEntry = sortedCategories.isNotEmpty
        ? sortedCategories.first
        : const MapEntry('No spending yet', 0.0);

    final topCategoryName = _displayCategory(topCategoryEntry.key);
    final topCategorySpend = topCategoryEntry.value;
    final previousTopCategorySpend =
        previousByCategory[topCategoryEntry.key] ?? 0.0;
    final topCategoryChange = previousTopCategorySpend == 0
        ? (topCategorySpend > 0 ? 1.0 : 0.0)
        : ((topCategorySpend - previousTopCategorySpend) /
              previousTopCategorySpend);

    final dayOfMonth = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final predictedSpend = dayOfMonth == 0
        ? currentSpent
        : currentSpent / dayOfMonth * daysInMonth;
    final suggestedCut = topCategorySpend * 0.1;

    final weeklySpend = List<double>.generate(4, (index) {
      final startDay = (index * 7) + 1;
      final endDay = index == 3
          ? daysInMonth
          : math.min(startDay + 6, daysInMonth);
      final total = currentExpenses.fold<double>(0, (sum, tx) {
        final date = DateTime.tryParse(tx.date);
        if (date == null) return sum;
        if (date.day >= startDay && date.day <= endDay) {
          return sum + tx.amount;
        }
        return sum;
      });
      return total;
    });

    final insightText = _buildHeadlineInsight(
      currentSpent: currentSpent,
      previousSpent: previousSpent,
      topCategoryName: topCategoryName,
      topCategoryChange: topCategoryChange,
      predictedSpend: predictedSpend,
      suggestedCut: suggestedCut,
    );

    return _InsightsData(
      currentSpent: currentSpent,
      previousSpent: previousSpent,
      predictedSpend: predictedSpend,
      topCategoryName: topCategoryName,
      topCategorySpend: topCategorySpend,
      previousTopCategorySpend: previousTopCategorySpend,
      topCategoryChange: topCategoryChange,
      suggestedCut: suggestedCut,
      weeklySpend: weeklySpend,
      categoryTotals: currentByCategory,
      insightText: insightText,
      aiEnabled: true,
    );
  }

  Future<void> _setAiInsightsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      'profile_ai_insights_${UserSession.user_id ?? 'local'}',
      value,
    );
    if (!mounted) return;
    setState(() {
      if (value) {
        messages.clear();
      }
      futureInsights = _loadInsights();
    });
  }

  Map<String, double> _groupCategoryTotals(List<TransactionModel> expenses) {
    final grouped = <String, double>{};
    for (final tx in expenses) {
      final key = _displayCategory(tx.category);
      grouped.update(
        key,
        (value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }
    return grouped;
  }

  String _displayCategory(String category) {
    return displayCategoryName(category);
  }

  _CategoryVisual _categoryVisual(String category) {
    final visual = categoryVisual(category);
    return _CategoryVisual(icon: visual.icon, color: visual.color);
  }

  String _buildHeadlineInsight({
    required double currentSpent,
    required double previousSpent,
    required String topCategoryName,
    required double topCategoryChange,
    required double predictedSpend,
    required double suggestedCut,
  }) {
    if (currentSpent == 0) {
      return "You have no expense transactions this month yet. Add a few transactions so I can start analyzing your spending habits.";
    }

    final monthTrend = previousSpent == 0
        ? "This is the first month with enough data to track."
        : currentSpent > previousSpent
        ? "You are spending more than last month."
        : "You are spending less than last month.";

    final categoryTrend = topCategoryChange > 0
        ? "$topCategoryName is trending upward."
        : "$topCategoryName is relatively stable.";

    return "$monthTrend $categoryTrend If you cut about ${currencyFormat.format(suggestedCut)} from $topCategoryName, your projected month-end spending could drop to around ${currencyFormat.format(math.max(predictedSpend - suggestedCut, 0))}.";
  }

  String _buildSpendingWarningTitle(_InsightsData insights) {
    final current = insights.topCategorySpend;
    final previous = insights.previousTopCategorySpend;
    final category = insights.topCategoryName;

    if (current <= 0) {
      return "No notable spending this month yet";
    }

    if (previous <= 0) {
      return "$category newly reached ${currencyFormat.format(current)}";
    }

    final diff = current - previous;
    final percent = (diff / previous * 100).abs().round();

    if (previous < 100000 && diff > 0) {
      return "$category increased from ${currencyFormat.format(previous)} to ${currencyFormat.format(current)}";
    }

    if (diff.abs() < 50000) {
      return "$category is nearly unchanged from last month";
    }

    return "$category is ${diff >= 0 ? 'up' : 'down'} $percent%";
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? messageController.text).trim();
    if (text.isEmpty || currentInsights == null || isSending) return;
    final languageController = context.read<LanguageController>();
    final t = languageController.text;

    setState(() {
      isSending = true;
      messages.add(_ChatMessage(text: text, isUser: true));
      messageController.clear();
    });

    AiAssistantResponse? aiResponse;
    String reply;
    try {
      if (aiChatService.isConfigured) {
        final previousMessages = messages.length > 1
            ? messages.sublist(0, messages.length - 1)
            : <_ChatMessage>[];

        final history = aiChatService.trimHistory(
          previousMessages
              .map(
                (message) =>
                    AiChatTurn(text: message.text, isUser: message.isUser),
              )
              .toList(),
        );

        aiResponse = await aiChatService.askFinancialAssistant(
          userMessage: text,
          history: history,
          transactions: currentTransactions,
          offTopicReply: t('financial_scope_reply'),
          responseLanguageCode: languageController.language.code,
        );
        reply = aiResponse.text;
      } else {
        reply = _buildAiUnavailableReply();
      }
    } on AiChatException catch (e) {
      reply = _buildAiUnavailableReply(e);
    } catch (_) {
      reply = _buildAiUnavailableReply();
    }

    if (!mounted) return;

    setState(() {
      final actions = aiResponse?.actions ?? const <AiAssistantAction>[];
      if (actions.isEmpty) {
        messages.add(_ChatMessage(text: reply, isUser: false));
      } else {
        for (var index = 0; index < actions.length; index++) {
          messages.add(
            _ChatMessage(
              text: actions.length == 1
                  ? reply
                  : '$reply\n${index + 1}/${actions.length}',
              isUser: false,
              action: actions[index],
            ),
          );
        }
      }
      isSending = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmAiAction(_ChatMessage message) async {
    final action = message.action;
    if (action == null || message.actionCompleted) return;

    try {
      await _executeAiAction(action);
      if (!mounted) return;
      setState(() {
        message.actionCompleted = true;
        messages.add(
          _ChatMessage(
            text: context.read<LanguageController>().text('saved_to_app'),
            isUser: false,
          ),
        );
        futureInsights = _loadInsights();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _cancelAiAction(_ChatMessage message) {
    if (message.actionCompleted) return;
    setState(() {
      message.actionCompleted = true;
      messages.add(
        _ChatMessage(
          text: context.read<LanguageController>().text('action_canceled'),
          isUser: false,
        ),
      );
    });
  }

  Future<void> _executeAiAction(AiAssistantAction action) async {
    final payload = action.payload;
    final api = ApiService();

    switch (action.action) {
      case 'add_transaction':
        final amount = _positiveAmount(payload['amount'], 'Transaction amount');
        await api.addTransaction({
          "description": _stringValue(
            payload['description'],
            fallback: 'AI entry',
          ),
          "category": _stringValue(payload['category'], fallback: 'Other'),
          "account": _stringValue(payload['account'], fallback: 'Main Card'),
          "amount": amount,
          "is_expense": _boolValue(payload['is_expense'], fallback: true)
              ? 1
              : 0,
          "notes": _stringValue(payload['notes']),
          "date": _dateValue(payload['date']).toString(),
        });
        break;
      case 'add_saving_goal':
        final targetAmount = _positiveAmount(
          payload['target_amount'],
          'Goal amount',
        );
        final currentAmount = _doubleValue(payload['current_amount']);
        if (currentAmount < 0) {
          throw Exception("Current saved amount cannot be less than 0.");
        }
        await api.saveGoal(
          title: _stringValue(payload['title'], fallback: 'Saving goal'),
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          targetDate: _dateOnlyValue(payload['target_date']),
          note: _stringValue(payload['note']),
        );
        break;
      case 'set_budget':
        final monthlyLimit = _positiveAmount(
          payload['monthly_limit'],
          'Budget limit',
        );
        await api.saveBudget(
          category: _stringValue(payload['category'], fallback: 'Other'),
          month: _monthValue(payload['month']),
          monthlyLimit: monthlyLimit,
        );
        break;
      case 'add_recurring_transaction':
        final amount = _positiveAmount(payload['amount'], 'Recurring amount');
        await api.saveRecurringTransaction(
          description: _stringValue(
            payload['description'],
            fallback: 'Recurring',
          ),
          category: _stringValue(payload['category'], fallback: 'Other'),
          account: _stringValue(payload['account'], fallback: 'Main Card'),
          amount: amount,
          isExpense: _boolValue(payload['is_expense'], fallback: true),
          frequency: _frequencyValue(payload['frequency']),
          nextRunDate: _dateOnlyValue(payload['next_run_date'])!,
          notes: _stringValue(payload['notes']),
        );
        break;
      default:
        throw Exception('Unsupported action: ${action.action}');
    }
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    final normalized = value
        ?.toString()
        .replaceAll(RegExp(r'[^0-9.,]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(normalized ?? '') ?? 0;
  }

  double _positiveAmount(dynamic value, String fieldName) {
    final amount = _doubleValue(value);
    if (amount <= 0) {
      throw Exception("$fieldName must be greater than 0.");
    }
    return amount;
  }

  bool _boolValue(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase().trim();
    if (text == 'true' || text == '1' || text == 'expense') return true;
    if (text == 'false' || text == '0' || text == 'income') return false;
    return fallback;
  }

  DateTime _dateValue(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    final parsed = DateTime.tryParse(raw);
    if (parsed != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      final now = DateTime.now();
      return DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
        now.hour,
        now.minute,
        now.second,
      );
    }
    return parsed ?? DateTime.now();
  }

  String? _dateOnlyValue(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    final parsed = _dateValue(value);
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  String _monthValue(dynamic value) {
    final parsed = DateTime.tryParse('${value ?? ''}-01');
    final now = DateTime.now();
    return DateFormat('yyyy-MM').format(parsed ?? now);
  }

  String _frequencyValue(dynamic value) {
    final text = value?.toString().toLowerCase().trim();
    if (text == 'daily' || text == 'weekly' || text == 'monthly') return text!;
    return 'monthly';
  }

  String _buildAiUnavailableReply([AiChatException? error]) {
    final message = error?.message ?? '';

    if (message.contains('Ollama')) {
      return message;
    }

    if (error?.statusCode == 429) {
      final retryAfter = error?.retryAfter;
      final retryText = retryAfter == null
          ? 'a moment'
          : '${math.max(1, retryAfter.inSeconds)} seconds';
      return "I cannot reach the real AI right now because the local model is busy. Try again in $retryText.";
    }

    if (!aiChatService.isConfigured) {
      return "The real AI is not connected. Check the PHP backend and local Ollama service.";
    }

    return message.isEmpty
        ? "I cannot reach the real AI right now. Please try again shortly."
        : message;
  }

  Widget _disabledInsightsView({
    required ThemeData theme,
    required bool isDark,
    required Color text,
    required Color subText,
  }) {
    final primary = theme.primaryColor;
    final t = context.watch<LanguageController>().text;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.psychology, color: primary, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                t('ai_off'),
                style: TextStyle(
                  color: text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('ai_off_body'),
                style: TextStyle(color: subText, height: 1.4),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  iconColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _setAiInsightsEnabled(true),
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  t('turn_on_ai'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final t = context.watch<LanguageController>().text;
    final isDark = theme.brightness == Brightness.dark;
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = isDark ? Colors.white70 : Colors.grey;

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark
            ? theme.appBarTheme.backgroundColor
            : Colors.white,
        title: Text(
          t('ai_insights'),
          style: TextStyle(
            color: isDark ? theme.textTheme.titleLarge?.color : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.auto_awesome,
              color: isDark ? theme.iconTheme.color : Colors.black,
            ),
          ),
        ],
      ),
      body: UserSession.user_id == null
          ? Center(child: Text(t('user_not_logged_in')))
          : FutureBuilder<_InsightsData>(
              future: futureInsights,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("${t('error_prefix')}: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(child: Text(t('no_insight_data')));
                }

                final insights = snapshot.data!;
                if (!insights.aiEnabled) {
                  return _disabledInsightsView(
                    theme: theme,
                    isDark: isDark,
                    text: text,
                    subText: subText,
                  );
                }

                final visual = _categoryVisual(insights.topCategoryName);
                final warningTitle = _buildSpendingWarningTitle(insights);
                final maxWeek = insights.weeklySpend.fold<double>(0, math.max);

                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? theme.cardColor : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        visual.color.withValues(alpha: 0.75),
                                        visual.color,
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      visual.icon,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            t('spending_alert'),
                                            style: TextStyle(
                                              color: visual.color,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            t('this_month'),
                                            style: TextStyle(color: subText),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        warningTitle,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: text,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        insights.insightText,
                                        style: TextStyle(color: subText),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primary,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => _sendMessage(
                                                "How can I reduce spending in ${insights.topCategoryName}?",
                                              ),
                                              child: Text(t('analyze_habits')),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: text,
                                            ),
                                            onPressed: () => _sendMessage(
                                              "What should I do this week?",
                                            ),
                                            child: Text(
                                              t('ask_ai'),
                                              style: TextStyle(color: text),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? theme.cardColor : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Color(0xFFDFF5E1),
                                      child: Icon(
                                        Icons.savings,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      t('saving_suggestion'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  t('saving_suggestion_detail')
                                      .replaceAll(
                                        '{category}',
                                        insights.topCategoryName,
                                      )
                                      .replaceAll(
                                        '{amount}',
                                        currencyFormat.format(
                                          insights.suggestedCut,
                                        ),
                                      ),
                                  style: TextStyle(color: subText),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  t('saving_suggestion_basis'),
                                  style: TextStyle(
                                    color: subText,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: insights.currentSpent == 0
                                        ? 0
                                        : (insights.suggestedCut /
                                                  insights.currentSpent)
                                              .clamp(0.0, 1.0),
                                    minHeight: 10,
                                    backgroundColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey.shade300,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        _sendMessage(t('saving_plan_prompt')),
                                    child: Text(t('create_saving_plan')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? theme.cardColor : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t('this_month_forecast'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: text,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(4, (index) {
                                    final value = insights.weeklySpend[index];
                                    final normalized = maxWeek == 0
                                        ? 0.15
                                        : (value / maxWeek).clamp(0.15, 1.0);
                                    return ForecastBar(
                                      height: 50 + (90 * normalized),
                                      label: "W${index + 1}",
                                      active: index == 3,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          t('spent_this_month'),
                                          style: TextStyle(color: subText),
                                        ),
                                        Text(
                                          currencyFormat.format(
                                            insights.currentSpent,
                                          ),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: text,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          t('forecast'),
                                          style: TextStyle(color: subText),
                                        ),
                                        Text(
                                          currencyFormat.format(
                                            insights.predictedSpend,
                                          ),
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info, color: primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "At the current pace, you will likely end the month at around ${currencyFormat.format(insights.predictedSpend)}.",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? theme.cardColor : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.smart_toy, color: primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      t('ai_assistant'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: text,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _PromptChip(
                                      label: t('am_i_overspending'),
                                      onTap: () =>
                                          _sendMessage("Am I overspending?"),
                                    ),
                                    _PromptChip(
                                      label: t('which_category_cut'),
                                      onTap: () => _sendMessage(
                                        "Which category should I cut?",
                                      ),
                                    ),
                                    _PromptChip(
                                      label: t('this_month_forecast'),
                                      onTap: () =>
                                          _sendMessage("This month forecast"),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...messages.map((message) {
                                  if (message.action != null) {
                                    return _AiActionMessageCard(
                                      message: message,
                                      currencyFormat: currencyFormat,
                                      onConfirm: () =>
                                          _confirmAiAction(message),
                                      onCancel: () => _cancelAiAction(message),
                                    );
                                  }

                                  return Align(
                                    alignment: message.isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      constraints: const BoxConstraints(
                                        maxWidth: 300,
                                      ),
                                      decoration: BoxDecoration(
                                        color: message.isUser
                                            ? primary
                                            : (isDark
                                                  ? const Color(0xFF1A1A1A)
                                                  : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        message.text,
                                        style: TextStyle(
                                          color: message.isUser
                                              ? Colors.white
                                              : text,
                                        ),
                                      ),
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
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      decoration: BoxDecoration(
                        color: isDark ? theme.cardColor : Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: InputDecoration(
                                hintText: t('ask_placeholder'),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF1A1A1A)
                                    : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 50,
                            width: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                iconColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: isSending ? null : _sendMessage,
                              child: isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class ForecastBar extends StatelessWidget {
  final double height;
  final String label;
  final bool active;

  const ForecastBar({
    super.key,
    required this.height,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Column(
      children: [
        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            color: active ? primary : primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PromptChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: primary.withValues(alpha: 0.08),
      labelStyle: TextStyle(color: primary, fontWeight: FontWeight.w600),
      side: BorderSide.none,
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final AiAssistantAction? action;
  bool actionCompleted = false;

  _ChatMessage({required this.text, required this.isUser, this.action});
}

class _AiActionMessageCard extends StatelessWidget {
  final _ChatMessage message;
  final NumberFormat currencyFormat;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _AiActionMessageCard({
    required this.message,
    required this.currencyFormat,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<LanguageController>().text;
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final action = message.action!;
    final payload = action.payload;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _actionRow(
                    Icons.bolt,
                    t('action'),
                    _actionLabel(action.action, t),
                    primary,
                  ),
                  ..._payloadRows(payload, t, primary),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: message.actionCompleted ? null : onCancel,
                    child: Text(t('cancel')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: message.actionCompleted ? null : onConfirm,
                    icon: Icon(
                      message.actionCompleted ? Icons.check : Icons.save,
                    ),
                    label: Text(
                      message.actionCompleted ? t('saved') : t('confirm'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _payloadRows(
    Map<String, dynamic> payload,
    String Function(String) t,
    Color primary,
  ) {
    final rows = <Widget>[];
    for (final entry in payload.entries) {
      final value = entry.value;
      if (value == null || value.toString().trim().isEmpty) continue;
      rows.add(
        _actionRow(
          Icons.circle,
          _fieldLabel(entry.key, t),
          _formatValue(entry.key, value, t),
          primary,
          smallIcon: true,
        ),
      );
    }
    return rows;
  }

  Widget _actionRow(
    IconData icon,
    String label,
    String value,
    Color primary, {
    bool smallIcon = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: smallIcon ? 8 : 16, color: primary),
          SizedBox(width: smallIcon ? 12 : 8),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _actionLabel(String action, String Function(String) t) {
    switch (action) {
      case 'add_transaction':
        return t('add_transaction');
      case 'add_saving_goal':
        return t('add_saving_goal');
      case 'set_budget':
        return t('set_budget');
      case 'add_recurring_transaction':
        return t('add_recurring');
      default:
        return action;
    }
  }

  String _fieldLabel(String key, String Function(String) t) {
    final labels = {
      'description': t('description'),
      'category': t('category'),
      'account': t('account'),
      'amount': t('amount'),
      'is_expense': t('transaction_type'),
      'notes': t('notes'),
      'date': t('date'),
      'title': t('goal_name'),
      'target_amount': t('target'),
      'current_amount': t('saved'),
      'monthly_limit': t('monthly_limit'),
      'frequency': t('frequency'),
    };
    if (labels.containsKey(key)) return labels[key]!;

    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _formatValue(String key, dynamic value, String Function(String) t) {
    if (key.contains('amount') || key.contains('limit')) {
      final amount = value is num
          ? value.toDouble()
          : double.tryParse(value.toString()) ?? 0;
      return currencyFormat.format(amount);
    }
    if (key == 'is_expense') {
      return value == true || value == 1 ? t('expense') : t('income_type');
    }
    return value.toString();
  }
}

class _CategoryVisual {
  final IconData icon;
  final Color color;

  const _CategoryVisual({required this.icon, required this.color});
}

class _InsightsData {
  final double currentSpent;
  final double previousSpent;
  final double predictedSpend;
  final String topCategoryName;
  final double topCategorySpend;
  final double previousTopCategorySpend;
  final double topCategoryChange;
  final double suggestedCut;
  final List<double> weeklySpend;
  final Map<String, double> categoryTotals;
  final String insightText;
  final bool aiEnabled;

  const _InsightsData({
    required this.currentSpent,
    required this.previousSpent,
    required this.predictedSpend,
    required this.topCategoryName,
    required this.topCategorySpend,
    required this.previousTopCategorySpend,
    required this.topCategoryChange,
    required this.suggestedCut,
    required this.weeklySpend,
    required this.categoryTotals,
    required this.insightText,
    required this.aiEnabled,
  });

  factory _InsightsData.disabled() {
    return const _InsightsData(
      currentSpent: 0,
      previousSpent: 0,
      predictedSpend: 0,
      topCategoryName: 'AI Insights',
      topCategorySpend: 0,
      previousTopCategorySpend: 0,
      topCategoryChange: 0,
      suggestedCut: 0,
      weeklySpend: [0, 0, 0, 0],
      categoryTotals: {},
      insightText: '',
      aiEnabled: false,
    );
  }
}
