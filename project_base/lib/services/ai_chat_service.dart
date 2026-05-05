import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project_base/models/transaction_model.dart';
import 'package:project_base/services/api_service.dart';

class AiChatService {
  static const Duration _defaultRateLimitCooldown = Duration(seconds: 45);

  DateTime? _rateLimitedUntil;

  bool get isConfigured => true;

  List<AiChatTurn> trimHistory(List<AiChatTurn> history) {
    if (history.length <= 8) return history;
    return history.sublist(history.length - 8);
  }

  Future<String> askFinancialAssistant({
    required String userMessage,
    required List<AiChatTurn> history,
    required List<TransactionModel> transactions,
  }) async {
    final rateLimitedUntil = _rateLimitedUntil;
    if (rateLimitedUntil != null && DateTime.now().isBefore(rateLimitedUntil)) {
      throw AiChatException(
        'AI đang giới hạn tạm thời. Hãy thử lại sau.',
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
      throw const AiChatException('AI không trả về nội dung hợp lệ.');
    }

    return reply;
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
      'message': body.trim().isEmpty ? 'Backend không trả về dữ liệu.' : body,
    };
  }

  String _readErrorMessage(Map<String, dynamic> data, int statusCode) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'AI backend lỗi $statusCode.';
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
