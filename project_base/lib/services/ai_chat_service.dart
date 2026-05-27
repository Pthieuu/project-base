import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project_base/models/transaction_model.dart';
import 'package:project_base/services/api_service.dart';

class AiChatService {
  static const Duration _defaultRateLimitCooldown = Duration(seconds: 45);
  static const String _offTopicReply =
      'Mình chỉ hỗ trợ các câu hỏi liên quan đến quản lý tài chính cá nhân như chi tiêu, thu nhập, ngân sách, tiết kiệm, giao dịch, dự đoán chi tiêu hoặc mục tiêu tài chính. Bạn hỏi mình theo hướng đó nhé.';

  DateTime? _rateLimitedUntil;

  bool get isConfigured => true;

  List<AiChatTurn> trimHistory(List<AiChatTurn> history) {
    if (history.length <= 8) return history;
    return history.sublist(history.length - 8);
  }

  Future<AiAssistantResponse> askFinancialAssistant({
    required String userMessage,
    required List<AiChatTurn> history,
    required List<TransactionModel> transactions,
    String? offTopicReply,
    String responseLanguageCode = 'vi',
  }) async {
    if (!_isFinancialQuestion(userMessage)) {
      return AiAssistantResponse(text: offTopicReply ?? _offTopicReply);
    }

    final localActionResponse = _tryBuildLocalTransactionActions(
      userMessage,
      responseLanguageCode,
    );
    if (localActionResponse != null) {
      return localActionResponse;
    }

    final rateLimitedUntil = _rateLimitedUntil;
    if (rateLimitedUntil != null && DateTime.now().isBefore(rateLimitedUntil)) {
      throw AiChatException(
        'AI is temporarily rate-limited. Please try again later.',
        statusCode: 429,
        retryAfter: rateLimitedUntil.difference(DateTime.now()),
      );
    }

    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}ai_chat.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': userMessage,
            'language': responseLanguageCode,
            'history': history.map((turn) => turn.toJson()).toList(),
            'transactions': transactions.map((tx) => tx.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 120));

    final data = _decodeResponse(response.body);
    if (response.statusCode != 200 ||
        data['status'] != 'success' ||
        data['reply'] is! String) {
      final retryAfter = _readRetryAfter(data);
      if (response.statusCode == 429 || data['status_code'] == 429) {
        if (!_isQuotaNotAvailable(data)) {
          _rateLimitedUntil = DateTime.now().add(
            retryAfter ?? _defaultRateLimitCooldown,
          );
        }
      }

      throw AiChatException(
        _readErrorMessage(data, response.statusCode),
        statusCode: data['status_code'] is int
            ? data['status_code'] as int
            : response.statusCode,
        retryAfter: _isQuotaNotAvailable(data) ? null : retryAfter,
      );
    }

    final reply = (data['reply'] as String).trim();
    if (reply.isEmpty) {
      throw const AiChatException('AI returned an invalid response.');
    }

    return AiAssistantResponse.fromText(reply);
  }

  Map<String, dynamic> _decodeResponse(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) return data;
    } catch (_) {
      // The backend should always return JSON. Keep a readable error below.
    }
    return {
      'status': 'error',
      'message': body.trim().isEmpty ? 'Backend returned no data.' : body,
    };
  }

  String _readErrorMessage(Map<String, dynamic> data, int statusCode) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'AI backend error $statusCode.';
  }

  Duration? _readRetryAfter(Map<String, dynamic> data) {
    final retryAfter = data['retry_after_seconds'];
    if (retryAfter is num && retryAfter > 0) {
      return Duration(milliseconds: (retryAfter * 1000).ceil());
    }
    return null;
  }

  bool _isQuotaNotAvailable(Map<String, dynamic> data) {
    final message = data['message'];
    return message is String && message.contains('limit: 0');
  }

  bool _isFinancialQuestion(String rawMessage) {
    final message = rawMessage.trim().toLowerCase();
    if (message.isEmpty) return false;

    final financialKeywords = <String>[
      'chi tiêu',
      'chi tieu',
      'chi phí',
      'chi phi',
      'thu nhập',
      'thu nhap',
      'tiền',
      'tien',
      'lương',
      'luong',
      'ngân sách',
      'ngan sach',
      'giao dịch',
      'giao dich',
      'tiết kiệm',
      'tiet kiem',
      'mục tiêu',
      'muc tieu',
      'số dư',
      'so du',
      'ví',
      'nợ',
      'vay',
      'trả góp',
      'tra gop',
      'hóa đơn',
      'hoa don',
      'thuê nhà',
      'thue nha',
      'dự đoán',
      'du doan',
      'danh mục',
      'danh muc',
      'quá tay',
      'qua tay',
      'cắt giảm',
      'cat giam',
      'salary',
      'expense',
      'income',
      'money',
      'budget',
      'transaction',
      'saving',
      'goal',
      'debt',
      'bill',
      'rent',
      'spend',
      'forecast',
      'cash',
      'card',
      '支出',
      '収入',
      'お金',
      '予算',
      '取引',
      '貯蓄',
      '節約',
    ];

    if (financialKeywords.any(message.contains)) return true;

    final categoryWords = <String>[
      'cafe',
      'cà phê',
      'ca phe',
      'xăng',
      'xang',
      'shopping',
      'food',
      'transport',
      'coffee',
      'rent',
    ];

    final financeContextWords = <String>[
      'tháng',
      'thang',
      'tuần',
      'tuan',
      'hôm nay',
      'hom nay',
      'bao nhiêu',
      'bao nhieu',
      'tăng',
      'tang',
      'giảm',
      'giam',
      'chi',
      'tiêu',
      'tieu',
      'dự đoán',
      'du doan',
      'nhập',
      'nhap',
      'thêm',
      'them',
      'lưu',
      'luu',
    ];

    if (categoryWords.any(message.contains) &&
        financeContextWords.any(message.contains)) {
      return true;
    }

    final hasCurrencyAmount = RegExp(
      r'(\d+([.,]\d+)?\s*(k|đ|d|vnd|vnđ|dong|nghìn|ngan|triệu|trieu|m|yen|円|\$))|((k|đ|d|vnd|vnđ|\$)\s*\d+)',
      caseSensitive: false,
    ).hasMatch(message);
    if (!hasCurrencyAmount) return false;

    final actionOrCategoryWords = <String>[
      'nhập',
      'nhap',
      'thêm',
      'them',
      'lưu',
      'luu',
      'tạo',
      'tao',
      'ăn',
      'an ',
      'uống',
      'uong',
      'đi',
      'di ',
      'mua',
      'xăng',
      'xang',
      'lương',
      'luong',
      'salary',
      'paid',
      'spent',
    ];

    return actionOrCategoryWords.any(message.contains) ||
        categoryWords.any(message.contains);
  }

  AiAssistantResponse? _tryBuildLocalTransactionActions(
    String rawMessage,
    String languageCode,
  ) {
    final message = rawMessage.trim();
    final lower = message.toLowerCase();
    final wantsDataEntry = [
      'thêm',
      'them',
      'nhập',
      'nhap',
      'lưu',
      'luu',
      'ghi',
      'add',
      'save',
    ].any(lower.contains);
    if (!wantsDataEntry) return null;

    final amountPattern = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(k|nghìn|ngan|triệu|trieu|tr|m|đ|d|vnd|vnđ|dong)',
      caseSensitive: false,
    );
    final matches = amountPattern.allMatches(message).toList(growable: false);
    if (matches.isEmpty) return null;

    final isExpense = ![
      'thu nhập',
      'thu nhap',
      'lương',
      'luong',
      'nhận',
      'nhan',
      'salary',
      'income',
      'paid me',
    ].any(lower.contains);

    final actions = <AiAssistantAction>[];
    var previousEnd = 0;
    for (final match in matches) {
      final phrase = message.substring(previousEnd, match.start);
      final description = _cleanTransactionDescription(phrase);
      final amount = _parseVietnameseAmount(match.group(1), match.group(2));
      previousEnd = match.end;

      if (description.isEmpty || amount <= 0) continue;

      actions.add(
        AiAssistantAction(
          action: 'add_transaction',
          payload: {
            'description': description,
            'category': _guessCategory(description, isExpense: isExpense),
            'account': 'Cash',
            'amount': amount,
            'is_expense': isExpense,
            'notes': '',
            'date': _todayDate(),
          },
        ),
      );
    }

    if (actions.isEmpty) return null;

    return AiAssistantResponse(
      text: _localActionMessage(actions.length, languageCode),
      actions: actions,
    );
  }

  String _localActionMessage(int count, String languageCode) {
    if (languageCode == 'en') {
      return count == 1
          ? 'I separated the transaction below. Please review and confirm to save it.'
          : 'I separated this into $count transactions below. Please review and confirm each one to save.';
    }
    if (languageCode == 'ja') {
      return count == 1
          ? '下の取引に分けました。内容を確認して保存してください。'
          : '$count 件の取引に分けました。内容を確認して保存してください。';
    }
    return count == 1
        ? 'Mình đã tách được giao dịch bên dưới, bạn kiểm tra rồi xác nhận để lưu.'
        : 'Mình đã tách thành $count giao dịch bên dưới, bạn kiểm tra rồi xác nhận để lưu.';
  }

  String _cleanTransactionDescription(String rawPhrase) {
    var text = rawPhrase.toLowerCase();
    text = text.replaceAll(RegExp(r'[,;。،]+'), ' ');
    text = text.replaceAll(
      RegExp(
        r'\b(hãy|hay|thêm|them|nhập|nhap|lưu|luu|ghi|giúp|giup|cho|tôi|toi|mình|minh|chi tiêu|chi tieu|thu nhập|thu nhap|hôm nay|hom nay|ngày hôm nay|ngay hom nay|tôi đã|toi da|mình đã|minh da|đã|da|vừa|vua)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    text = text.replaceAll(
      RegExp(r'\b(hết|het|mất|mat|tốn|ton|là|la|khoảng|khoang)\s*$'),
      ' ',
    );
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  double _parseVietnameseAmount(String? numberText, String? unitText) {
    if (numberText == null || unitText == null) return 0;

    final normalizedNumber = numberText.replaceAll(',', '.');
    final number = double.tryParse(normalizedNumber) ?? 0;
    final unit = unitText.toLowerCase();

    if (unit == 'k' || unit == 'nghìn' || unit == 'ngan') {
      return number * 1000;
    }
    if (unit == 'triệu' || unit == 'trieu' || unit == 'tr' || unit == 'm') {
      return number * 1000000;
    }
    return number;
  }

  String _guessCategory(String description, {required bool isExpense}) {
    final text = description.toLowerCase();
    if (!isExpense) return 'Salary';
    if ([
      'ăn',
      'an ',
      'sáng',
      'sang',
      'trưa',
      'trua',
      'tối',
      'toi',
      'cơm',
      'com',
      'phở',
      'pho',
      'bún',
      'bun',
      'cafe',
      'cà phê',
      'ca phe',
      'coffee',
      'food',
    ].any(text.contains)) {
      return 'Food & Drink';
    }
    if ([
      'xăng',
      'xang',
      'grab',
      'taxi',
      'xe',
      'bus',
      'transport',
    ].any(text.contains)) {
      return 'Transport';
    }
    if ([
      'mua',
      'shopping',
      'máy tính',
      'may tinh',
      'laptop',
      'điện thoại',
      'dien thoai',
      'áo',
      'ao ',
      'quần',
      'quan',
    ].any(text.contains)) {
      return 'Shopping';
    }
    if (['nhà', 'nha', 'thuê', 'thue', 'rent'].any(text.contains)) {
      return 'Housing';
    }
    return 'Other';
  }

  String _todayDate() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}

class AiAssistantResponse {
  final String text;
  final List<AiAssistantAction> actions;

  const AiAssistantResponse({required this.text, this.actions = const []});

  AiAssistantAction? get action => actions.isEmpty ? null : actions.first;

  factory AiAssistantResponse.fromText(String rawText) {
    final decoded = _tryDecodeAction(rawText);
    if (decoded == null) {
      return AiAssistantResponse(text: rawText);
    }

    final message = decoded['message']?.toString().trim();
    final actions = _readActions(decoded);
    return AiAssistantResponse(
      text: message == null || message.isEmpty
          ? 'I understood your request. Please review the details below before saving.'
          : message,
      actions: actions,
    );
  }

  static Map<String, dynamic>? _tryDecodeAction(String rawText) {
    final trimmed = rawText.trim();
    final candidates = <String>[trimmed];

    final fenced = RegExp(
      r'```(?:json)?\s*([\s\S]*?)\s*```',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (fenced != null) {
      candidates.insert(0, fenced.group(1)!.trim());
    }

    final firstBrace = trimmed.indexOf('{');
    final lastBrace = trimmed.lastIndexOf('}');
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      candidates.add(trimmed.substring(firstBrace, lastBrace + 1));
    }

    for (final candidate in candidates) {
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic> &&
            (decoded['type'] == 'action' || decoded['type'] == 'actions')) {
          return decoded;
        }
        if (decoded is List) {
          final actions = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .where(
                (item) => item['action'] is String && item['payload'] is Map,
              )
              .toList(growable: false);
          if (actions.isNotEmpty) {
            return {
              'type': 'actions',
              'message':
                  'I understood your request. Please review the details below before saving.',
              'actions': actions,
            };
          }
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  static List<AiAssistantAction> _readActions(Map<String, dynamic> decoded) {
    if (decoded['type'] == 'action' &&
        decoded['action'] is String &&
        decoded['payload'] is Map) {
      return [AiAssistantAction.fromJson(decoded)];
    }

    if (decoded['type'] == 'action' &&
        decoded['action'] is String &&
        decoded['payload'] is List) {
      return (decoded['payload'] as List)
          .whereType<Map>()
          .map(
            (payload) => {
              'action': decoded['action'],
              'payload': Map<String, dynamic>.from(payload),
            },
          )
          .map(AiAssistantAction.fromJson)
          .toList(growable: false);
    }

    final rawActions = decoded['actions'];
    if (decoded['type'] == 'actions' && rawActions is List) {
      return _readActionList(rawActions);
    }

    final rawTransactions = decoded['transactions'] ?? decoded['items'];
    if (rawTransactions is List) {
      return rawTransactions
          .whereType<Map>()
          .map(
            (payload) => {
              'action': decoded['action'] ?? 'add_transaction',
              'payload': Map<String, dynamic>.from(payload),
            },
          )
          .map(AiAssistantAction.fromJson)
          .toList(growable: false);
    }

    if (decoded['payload'] is Map) {
      final payload = Map<String, dynamic>.from(decoded['payload'] as Map);
      final nestedItems = payload['transactions'] ?? payload['items'];
      if (nestedItems is List) {
        return nestedItems
            .whereType<Map>()
            .map(
              (item) => {
                'action': decoded['action'] ?? 'add_transaction',
                'payload': Map<String, dynamic>.from(item),
              },
            )
            .map(AiAssistantAction.fromJson)
            .toList(growable: false);
      }
    }

    return const [];
  }

  static List<AiAssistantAction> _readActionList(List rawActions) {
    final actions = rawActions
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['payload'] is Map)
        .map((item) {
          final action = item['action'] ?? item['type'] ?? 'add_transaction';
          return {
            'action': action,
            'payload': Map<String, dynamic>.from(item['payload'] as Map),
          };
        })
        .where((item) => item['action'] is String)
        .map(AiAssistantAction.fromJson)
        .toList(growable: false);

    if (actions.isNotEmpty) {
      return actions;
    }

    final payloadOnlyActions = rawActions
        .whereType<Map>()
        .map(
          (payload) => {
            'action': 'add_transaction',
            'payload': Map<String, dynamic>.from(payload),
          },
        )
        .map(AiAssistantAction.fromJson)
        .toList(growable: false);

    if (payloadOnlyActions.isNotEmpty) {
      return payloadOnlyActions;
    }

    return const [];
  }
}

class AiAssistantAction {
  final String action;
  final Map<String, dynamic> payload;

  const AiAssistantAction({required this.action, required this.payload});

  factory AiAssistantAction.fromJson(Map<String, dynamic> json) {
    return AiAssistantAction(
      action: json['action'].toString(),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }
}

class AiChatTurn {
  final String text;
  final bool isUser;

  const AiChatTurn({required this.text, required this.isUser});

  Map<String, dynamic> toJson() {
    return {'text': text, 'is_user': isUser};
  }
}

class AiChatException implements Exception {
  final String message;
  final int? statusCode;
  final Duration? retryAfter;

  const AiChatException(this.message, {this.statusCode, this.retryAfter});

  @override
  String toString() => message;
}
