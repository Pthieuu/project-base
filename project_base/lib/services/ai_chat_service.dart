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

  Future<AiAssistantResponse> askFinancialAssistant({
    required String userMessage,
    required List<AiChatTurn> history,
    required List<TransactionModel> transactions,
  }) async {
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
}

class AiAssistantResponse {
  final String text;
  final AiAssistantAction? action;

  const AiAssistantResponse({required this.text, this.action});

  factory AiAssistantResponse.fromText(String rawText) {
    final decoded = _tryDecodeAction(rawText);
    if (decoded == null) {
      return AiAssistantResponse(text: rawText);
    }

    final message = decoded['message']?.toString().trim();
    return AiAssistantResponse(
      text: message == null || message.isEmpty
          ? 'I understood your request. Please review the details below before saving.'
          : message,
      action: AiAssistantAction.fromJson(decoded),
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
            decoded['type'] == 'action' &&
            decoded['action'] is String &&
            decoded['payload'] is Map) {
          return decoded;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
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
