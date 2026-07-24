import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:project_base/services/api_service.dart';
import 'package:project_base/services/user_session.dart';

class ReceiptOcrResult {
  final String merchant;
  final double amount;
  final String date;
  final String category;
  final String notes;
  final double confidence;
  final String rawText;

  const ReceiptOcrResult({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    required this.notes,
    required this.confidence,
    required this.rawText,
  });

  factory ReceiptOcrResult.fromJson(Map<String, dynamic> json) {
    return ReceiptOcrResult(
      merchant: json['merchant']?.toString().trim() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      date: json['date']?.toString().trim() ?? '',
      category: json['category']?.toString().trim() ?? 'Other',
      notes: json['notes']?.toString().trim() ?? '',
      confidence: (double.tryParse(json['confidence']?.toString() ?? '') ?? 0)
          .clamp(0, 1),
      rawText: json['raw_text']?.toString().trim() ?? '',
    );
  }
}

class ReceiptOcrService {
  static const Duration _timeout = Duration(seconds: 120);

  Future<ReceiptOcrResult> scan(XFile image) async {
    final token = UserSession.accessToken;
    if (token == null || token.isEmpty) {
      throw const ReceiptOcrException('User is not authenticated.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}receipt_ocr.php'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('receipt', image.path));

    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decode(response.body);

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw ReceiptOcrException(
        data['message']?.toString() ??
            'Receipt scanning failed (${response.statusCode}).',
      );
    }

    final receiptData = data['data'];
    if (receiptData is! Map) {
      throw const ReceiptOcrException('The AI returned invalid receipt data.');
    }

    return ReceiptOcrResult.fromJson(Map<String, dynamic>.from(receiptData));
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      // Return a readable backend error below.
    }
    return {
      'status': 'error',
      'message': body.trim().isEmpty
          ? 'The receipt service returned no data.'
          : body.trim(),
    };
  }
}

class ReceiptOcrException implements Exception {
  final String message;

  const ReceiptOcrException(this.message);

  @override
  String toString() => message;
}
