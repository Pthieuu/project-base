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
  final List<ReceiptLineItem> lineItems;

  const ReceiptOcrResult({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    required this.notes,
    required this.confidence,
    required this.rawText,
    required this.lineItems,
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
      lineItems: (json['line_items'] is List)
          ? (json['line_items'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      ReceiptLineItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .where((item) => item.name.isNotEmpty)
                .toList()
          : const [],
    );
  }
}

class ReceiptLineItem {
  final String name;
  final double quantity;
  final double unitPrice;
  final double total;

  const ReceiptLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) {
    return ReceiptLineItem(
      name: json['name']?.toString().trim() ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '') ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '') ?? 0,
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
      Uri.parse('${ApiService.baseUrl}endpoints/ai/receipt_ocr.php'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    // On Flutter Web, XFile.path is a browser blob URL rather than a readable
    // local path. Uploading bytes works consistently across all platforms.
    request.files.add(
      http.MultipartFile.fromBytes(
        'receipt',
        await image.readAsBytes(),
        filename: image.name.isEmpty ? 'receipt.jpg' : image.name,
      ),
    );

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
