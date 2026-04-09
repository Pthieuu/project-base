import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_base/models/transaction_model.dart';
import 'package:project_base/services/ai_chat_service.dart';
import 'package:project_base/services/api_service.dart';
import 'package:project_base/services/user_session.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late Future<_InsightsData> futureInsights;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<_ChatMessage> messages = [];
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
      throw Exception("Người dùng chưa đăng nhập");
    }

    final transactions = await ApiService().get_transactions(UserSession.user_id!);
    currentTransactions = transactions;
    final data = _buildInsights(transactions);

    if (messages.isEmpty) {
      messages.addAll([
        _ChatMessage(
          text:
              "Mình đã xem các giao dịch gần đây của bạn. Danh mục chi nhiều nhất tháng này là ${data.topCategoryName}, và với tốc độ hiện tại bạn có thể chi khoảng ${currencyFormat.format(data.predictedSpend)} trong tháng.",
          isUser: false,
        ),
        _ChatMessage(
          text: "Bạn có thể hỏi mình về việc chi quá tay, danh mục chi tiêu, dự đoán cuối tháng hoặc cách tiết kiệm.",
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

    final currentSpent = currentExpenses.fold<double>(0, (sum, tx) => sum + tx.amount);
    final previousSpent = previousExpenses.fold<double>(0, (sum, tx) => sum + tx.amount);

    final currentByCategory = _groupCategoryTotals(currentExpenses);
    final previousByCategory = _groupCategoryTotals(previousExpenses);

    final sortedCategories = currentByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategoryEntry = sortedCategories.isNotEmpty
        ? sortedCategories.first
        : const MapEntry('Chưa có chi tiêu', 0.0);

    final topCategoryName = _displayCategory(topCategoryEntry.key);
    final topCategorySpend = topCategoryEntry.value;
    final previousTopCategorySpend = previousByCategory[topCategoryEntry.key] ?? 0.0;
    final topCategoryChange = previousTopCategorySpend == 0
        ? (topCategorySpend > 0 ? 1.0 : 0.0)
        : ((topCategorySpend - previousTopCategorySpend) / previousTopCategorySpend);

    final dayOfMonth = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final predictedSpend = dayOfMonth == 0 ? currentSpent : currentSpent / dayOfMonth * daysInMonth;
    final suggestedCut = topCategorySpend * 0.1;

    final weeklySpend = List<double>.generate(4, (index) {
      final startDay = (index * 7) + 1;
      final endDay = index == 3 ? daysInMonth : math.min(startDay + 6, daysInMonth);
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
      topCategoryChange: topCategoryChange,
      suggestedCut: suggestedCut,
      weeklySpend: weeklySpend,
      categoryTotals: currentByCategory,
      insightText: insightText,
    );
  }

  Map<String, double> _groupCategoryTotals(List<TransactionModel> expenses) {
    final grouped = <String, double>{};
    for (final tx in expenses) {
      final key = _displayCategory(tx.category);
      grouped.update(key, (value) => value + tx.amount, ifAbsent: () => tx.amount);
    }
    return grouped;
  }

  String _displayCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'food':
      case 'food & drink':
      case 'food & dining':
        return 'Food & Dining';
      case 'home':
        return 'Housing';
      default:
        return category.isEmpty ? 'Other' : category;
    }
  }

  _CategoryVisual _categoryVisual(String category) {
    switch (category.trim().toLowerCase()) {
      case 'food & dining':
        return const _CategoryVisual(icon: Icons.restaurant, color: Colors.orange);
      case 'housing':
        return const _CategoryVisual(icon: Icons.home, color: Color(0xFF1132D4));
      case 'entertainment':
        return const _CategoryVisual(icon: Icons.movie, color: Colors.red);
      case 'shopping':
        return const _CategoryVisual(icon: Icons.shopping_bag, color: Colors.green);
      default:
        return const _CategoryVisual(
          icon: Icons.account_balance_wallet,
          color: Color(0xFF1132D4),
        );
    }
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
      return "Tháng này bạn chưa có giao dịch chi tiêu nào. Hãy thêm vài giao dịch để mình bắt đầu phân tích thói quen chi tiêu.";
    }

    final monthTrend = previousSpent == 0
        ? "Đây là tháng đầu tiên có dữ liệu để theo dõi."
        : currentSpent > previousSpent
            ? "Bạn đang chi nhiều hơn tháng trước."
            : "Bạn đang chi ít hơn tháng trước.";

    final categoryTrend = topCategoryChange > 0
        ? "$topCategoryName đang có xu hướng tăng."
        : "$topCategoryName hiện khá ổn định.";

    return "$monthTrend $categoryTrend Nếu cắt bớt ${currencyFormat.format(suggestedCut)} ở $topCategoryName, mức chi dự kiến cuối tháng sẽ giảm còn khoảng ${currencyFormat.format(math.max(predictedSpend - suggestedCut, 0))}.";
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? messageController.text).trim();
    if (text.isEmpty || currentInsights == null || isSending) return;

    setState(() {
      isSending = true;
      messages.add(_ChatMessage(text: text, isUser: true));
      messageController.clear();
    });

    String reply;
    try {
      if (aiChatService.isConfigured) {
        final previousMessages = messages.length > 1
            ? messages.sublist(0, messages.length - 1)
            : <_ChatMessage>[];

        final history = aiChatService.trimHistory(
          previousMessages
              .map((message) => AiChatTurn(
                    text: message.text,
                    isUser: message.isUser,
                  ))
              .toList(),
        );

        reply = await aiChatService.askFinancialAssistant(
          userMessage: text,
          history: history,
          transactions: currentTransactions,
        );
      } else {
        reply = "${_generateReply(text, currentInsights!)}\n\nĐể trả lời tự do bằng AI thật, hãy cấu hình `GEMINI_API_KEY` cho app.";
      }
    } catch (e) {
      reply = "${_generateReply(text, currentInsights!)}\n\nKhông gọi được AI API: $e";
    }

    if (!mounted) return;

    setState(() {
      messages.add(_ChatMessage(text: reply, isUser: false));
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

  String _generateReply(String question, _InsightsData data) {
    final q = question.toLowerCase();

    if (q.contains('overspend') || q.contains('too much') || q.contains('vượt')) {
      final changePct = (data.topCategoryChange * 100).round();
      return "${data.topCategoryName} đang là điểm cần chú ý nhất tháng này với mức chi ${currencyFormat.format(data.topCategorySpend)}. So với tháng trước, danh mục này thay đổi $changePct%. Bạn nên bắt đầu kiểm soát từ đây.";
    }

    if (q.contains('save') || q.contains('cut') || q.contains('tiết kiệm')) {
      return "Danh mục dễ cắt giảm nhất là ${data.topCategoryName}. Nếu giảm khoảng 10%, bạn có thể tiết kiệm được ${currencyFormat.format(data.suggestedCut)} trong tháng mà không cần động tới mọi danh mục.";
    }

    if (q.contains('forecast') || q.contains('predict') || q.contains('dự đoán')) {
      return "Theo tốc độ chi tiêu hiện tại, nhiều khả năng bạn sẽ kết thúc tháng với khoảng ${currencyFormat.format(data.predictedSpend)} tiền chi tiêu.";
    }

    if (q.contains('category') || q.contains('danh mục')) {
      final topThree = data.categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final summary = topThree.take(3).map((e) {
        return "${_displayCategory(e.key)}: ${currencyFormat.format(e.value)}";
      }).join(", ");
      return "Ba danh mục chi nhiều nhất tháng này là $summary.";
    }

    if (q.contains('what should i do') || q.contains('nên làm gì') || q.contains('advice')) {
      return "Hãy tập trung vào ${data.topCategoryName} trước, hạn chế các khoản mua phát sinh trong tuần này, rồi kiểm tra lại dự đoán sau khi có thêm 3-4 giao dịch mới. Đây là cách nhanh nhất để cải thiện xu hướng chi tiêu.";
    }

    return data.insightText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = isDark ? Colors.white70 : Colors.grey;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        title: Text(
          "Phân tích AI",
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
          ? const Center(child: Text("Người dùng chưa đăng nhập"))
          : FutureBuilder<_InsightsData>(
              future: futureInsights,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text("Không có dữ liệu phân tích."));
                }

                final insights = snapshot.data!;
                final visual = _categoryVisual(insights.topCategoryName);
                final changePercent = (insights.topCategoryChange * 100).abs().round();
                final isUp = insights.topCategoryChange >= 0;
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
                                        visual.color.withOpacity(0.75),
                                        visual.color,
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(visual.icon, size: 50, color: Colors.white),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Cảnh báo chi tiêu",
                                            style: TextStyle(
                                              color: visual.color,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "Tháng này",
                                            style: TextStyle(color: subText),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Chi tiêu ${insights.topCategoryName} đang ${isUp ? 'tăng' : 'giảm'} $changePercent%",
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
                                                backgroundColor: const Color(0xFF1132D4),
                                              ),
                                              onPressed: () => _sendMessage(
                                                "Làm sao để giảm chi tiêu ở ${insights.topCategoryName}?",
                                              ),
                                              child: const Text("Phân tích thói quen"),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          OutlinedButton(
                                            onPressed: () => _sendMessage(
                                              "Tuần này tôi nên làm gì?",
                                            ),
                                            child: Text(
                                              "Hỏi AI",
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
                                  children: const [
                                    CircleAvatar(
                                      backgroundColor: Color(0xFFDFF5E1),
                                      child: Icon(Icons.savings, color: Colors.green),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Gợi ý tiết kiệm",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Nếu giảm ${insights.topCategoryName} khoảng 10%, bạn có thể giữ lại ${currencyFormat.format(insights.suggestedCut)} trong tháng này.",
                                  style: TextStyle(color: subText),
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: insights.currentSpent == 0
                                        ? 0
                                        : (insights.suggestedCut / insights.currentSpent).clamp(0.0, 1.0),
                                    minHeight: 10,
                                    backgroundColor:
                                        isDark ? Colors.grey[800] : Colors.grey.shade300,
                                    color: const Color(0xFF1132D4),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1132D4),
                                    ),
                                    onPressed: () => _sendMessage("Hãy gợi ý cho tôi một kế hoạch tiết kiệm."),
                                    child: const Text("Tạo kế hoạch tiết kiệm"),
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
                                  "Dự đoán tháng này",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: text,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(4, (index) {
                                    final value = insights.weeklySpend[index];
                                    final normalized = maxWeek == 0 ? 0.15 : (value / maxWeek).clamp(0.15, 1.0);
                                    return ForecastBar(
                                      height: 50 + (90 * normalized),
                                      label: "W${index + 1}",
                                      active: index == 3,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text("Đã chi", style: TextStyle(color: subText)),
                                        Text(
                                          currencyFormat.format(insights.currentSpent),
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
                                        Text("Dự đoán", style: TextStyle(color: subText)),
                                        Text(
                                          currencyFormat.format(insights.predictedSpend),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF1132D4),
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
                                    color: const Color(0xFF1132D4).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info, color: Color(0xFF1132D4)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Với tốc độ hiện tại, nhiều khả năng bạn sẽ kết thúc tháng ở mức khoảng ${currencyFormat.format(insights.predictedSpend)}.",
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
                                    const Icon(Icons.smart_toy, color: Color(0xFF1132D4)),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Trợ lý AI",
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
                                      label: "Tôi có đang chi quá tay không?",
                                      onTap: () => _sendMessage("Tôi có đang chi quá tay không?"),
                                    ),
                                    _PromptChip(
                                      label: "Nên cắt giảm danh mục nào?",
                                      onTap: () => _sendMessage("Nên cắt giảm danh mục nào?"),
                                    ),
                                    _PromptChip(
                                      label: "Dự đoán tháng này",
                                      onTap: () => _sendMessage("Dự đoán tháng này"),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...messages.map((message) {
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
                                      constraints: const BoxConstraints(maxWidth: 300),
                                      decoration: BoxDecoration(
                                        color: message.isUser
                                            ? const Color(0xFF1132D4)
                                            : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        message.text,
                                        style: TextStyle(
                                          color: message.isUser ? Colors.white : text,
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
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
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
                                hintText: "Hỏi về chi tiêu, dự đoán hoặc tiết kiệm...",
                                filled: true,
                                fillColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC),
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
                                backgroundColor: const Color(0xFF1132D4),
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

    return Column(
      children: [
        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF1132D4)
                : const Color(0xFF1132D4).withOpacity(0.3),
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

  const _PromptChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: const Color(0xFF1132D4).withOpacity(0.08),
      labelStyle: const TextStyle(
        color: Color(0xFF1132D4),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class _CategoryVisual {
  final IconData icon;
  final Color color;

  const _CategoryVisual({
    required this.icon,
    required this.color,
  });
}

class _InsightsData {
  final double currentSpent;
  final double previousSpent;
  final double predictedSpend;
  final String topCategoryName;
  final double topCategorySpend;
  final double topCategoryChange;
  final double suggestedCut;
  final List<double> weeklySpend;
  final Map<String, double> categoryTotals;
  final String insightText;

  const _InsightsData({
    required this.currentSpent,
    required this.previousSpent,
    required this.predictedSpend,
    required this.topCategoryName,
    required this.topCategorySpend,
    required this.topCategoryChange,
    required this.suggestedCut,
    required this.weeklySpend,
    required this.categoryTotals,
    required this.insightText,
  });
}
