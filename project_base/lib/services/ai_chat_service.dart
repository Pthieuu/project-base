import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:project_base/models/transaction_model.dart';

class AiChatService {
  static const String _localApiKey = '';
  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: _localApiKey);
  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
  ];
  static const int _maxOutputTokens = 1024;
  static const int _maxContinuationRequests = 2;

  bool get isConfigured => _apiKey.isNotEmpty;

  List<AiChatTurn> trimHistory(List<AiChatTurn> history) {
    if (history.length <= 4) return history;
    return history.sublist(history.length - 4);
  }

  Future<String> askFinancialAssistant({
    required String userMessage,
    required List<AiChatTurn> history,
    required List<TransactionModel> transactions,
  }) async {
    if (!isConfigured) {
      throw const AiChatException(
        'Chưa cấu hình GEMINI_API_KEY. Hãy chạy app với --dart-define=GEMINI_API_KEY=your_key hoặc đặt key tạm vào _localApiKey để test.',
      );
    }

    AiChatException? lastError;

    for (final model in _models) {
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          return await _callGemini(
            model: model,
            userMessage: userMessage,
            history: history,
            transactions: transactions,
          );
        } on AiChatException catch (e) {
          lastError = e;
          final shouldRetry =
              e.statusCode == 503 || e.statusCode == 429 || e.statusCode == 500;
          final isLastAttempt = attempt == 2;

          if (!shouldRetry || isLastAttempt) {
            break;
          }

          await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
    }

    throw lastError ??
        const AiChatException('Không thể kết nối Gemini lúc này.');
  }

  Future<String> _callGemini({
    required String model,
    required String userMessage,
    required List<AiChatTurn> history,
    required List<TransactionModel> transactions,
  }) async {
    final contents = <Map<String, Object>>[
      ...history.map(_turnToContent),
      _textContent('user', userMessage),
    ];

    final result = await _generateContent(
      model: model,
      transactions: transactions,
      contents: contents,
    );

    if (result.text.isEmpty) {
      throw const AiChatException('Gemini không trả về nội dung hợp lệ.');
    }

    var combinedText = result.text;
    var finishReason = result.finishReason;

    for (var attempt = 0; attempt < _maxContinuationRequests; attempt++) {
      if (finishReason != 'MAX_TOKENS') break;

      contents.add(_textContent('model', combinedText));
      contents.add(
        _textContent(
          'user',
          'Tiếp tục đúng phần trả lời trước đang dang dở. Không lặp lại ý đã nói.',
        ),
      );

      final continuation = await _generateContent(
        model: model,
        transactions: transactions,
        contents: contents,
      );

      if (continuation.text.isEmpty) break;

      combinedText = _mergeText(combinedText, continuation.text);
      finishReason = continuation.finishReason;
    }

    return combinedText;
  }

  Future<_GeminiResponse> _generateContent({
    required String model,
    required List<TransactionModel> transactions,
    required List<Map<String, Object>> contents,
  }) async {
    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {
              'text': _buildInstructions(transactions),
            }
          ],
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.5,
          'maxOutputTokens': _maxOutputTokens,
        },
      }),
    );

    if (response.statusCode != 200) {
      final errorMessage = _extractErrorMessage(response.body);
      throw AiChatException(
        'Gemini API lỗi ${response.statusCode}: $errorMessage',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body);
    return _extractResponse(data);
  }

  String _buildInstructions(List<TransactionModel> transactions) {
    final sortedTransactions = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentTransactions = sortedTransactions.take(8).toList();
    final expenseTransactions = recentTransactions.where((tx) => tx.isExpense).toList();
    final totalExpense = expenseTransactions.fold<double>(0, (sum, tx) => sum + tx.amount);
    final totalIncome = recentTransactions
        .where((tx) => !tx.isExpense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    final categoryTotals = <String, double>{};
    for (final tx in expenseTransactions) {
      categoryTotals.update(tx.category, (value) => value + tx.amount, ifAbsent: () => tx.amount);
    }

    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recent = recentTransactions.map((tx) {
      final sign = tx.isExpense ? '-' : '+';
      return '- ${tx.date} | ${tx.category} | ${tx.description} | $sign${tx.amount}';
    }).join('\n');

    final categorySummary = topCategories
        .take(3)
        .map((item) => '- ${item.key}: ${item.value}')
        .join('\n');

    return '''
Bạn là trợ lý tài chính cá nhân trong app quản lý chi tiêu.
Luôn trả lời bằng tiếng Việt.
Trả lời ngắn gọn, hữu ích, cụ thể, ưu tiên hành động.
Ưu tiên trả lời trong 3-5 câu, không dài dòng.
Nếu người dùng hỏi về chi tiêu của họ, hãy dựa trên dữ liệu giao dịch dưới đây.
Nếu câu hỏi ngoài phạm vi dữ liệu, vẫn trả lời bình thường như một trợ lý AI đa năng.
Không bịa ra số liệu không có trong dữ liệu.

Tóm tắt dữ liệu người dùng:
- Tổng thu: $totalIncome
- Tổng chi: $totalExpense
- Số giao dịch gần nhất dùng để phân tích: ${recentTransactions.length}

3 danh mục chi lớn nhất:
$categorySummary

8 giao dịch gần nhất:
$recent
''';
  }

  _GeminiResponse _extractResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final candidates = data['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final first = candidates.first;
        if (first is Map<String, dynamic>) {
          final finishReason = first['finishReason'] as String?;
          final content = first['content'];
          if (content is Map<String, dynamic>) {
            final parts = content['parts'];
            if (parts is List) {
              final texts = parts
                  .whereType<Map<String, dynamic>>()
                  .map((part) => part['text'])
                  .whereType<String>()
                  .map((text) => text.trim())
                  .where((text) => text.isNotEmpty)
                  .toList();
              return _GeminiResponse(
                text: texts.join('\n').trim(),
                finishReason: finishReason,
              );
            }
          }
        }
      }
    }
    return const _GeminiResponse(text: '');
  }

  String _extractErrorMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final error = data['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      }
    } catch (_) {
      // Fallback to raw body.
    }
    return body;
  }

  Map<String, Object> _turnToContent(AiChatTurn turn) {
    return _textContent(turn.isUser ? 'user' : 'model', turn.text);
  }

  Map<String, Object> _textContent(String role, String text) {
    return {
      'role': role,
      'parts': [
        {'text': text}
      ],
    };
  }

  String _mergeText(String previous, String next) {
    final trimmedPrevious = previous.trimRight();
    final trimmedNext = next.trimLeft();
    if (trimmedPrevious.isEmpty) return trimmedNext;
    if (trimmedNext.isEmpty) return trimmedPrevious;

    final needsSpace =
        !trimmedPrevious.endsWith('\n') &&
        !trimmedNext.startsWith('\n') &&
        !_isPunctuation(trimmedNext[0]);

    return needsSpace
        ? '$trimmedPrevious $trimmedNext'
        : '$trimmedPrevious$trimmedNext';
  }

  bool _isPunctuation(String char) {
    const punctuation = '.,!?;:)]}';
    return punctuation.contains(char);
  }
}

class AiChatTurn {
  final String text;
  final bool isUser;

  const AiChatTurn({
    required this.text,
    required this.isUser,
  });
}

class AiChatException implements Exception {
  final String message;
  final int? statusCode;

  const AiChatException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class _GeminiResponse {
  final String text;
  final String? finishReason;

  const _GeminiResponse({
    required this.text,
    this.finishReason,
  });
}
