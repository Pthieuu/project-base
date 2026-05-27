class TransactionModel {
  int? id;
  String description;
  String category;
  String account;
  double amount;
  bool isExpense;
  String notes;
  String date;

  TransactionModel({
    this.id,
    required this.description,
    required this.category,
    required this.account,
    required this.amount,
    required this.isExpense,
    required this.notes,
    required this.date,
  });

  /// 🔹 Từ JSON -> Object
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: int.tryParse(json['id'].toString()),
      description: json['description'] ?? "",
      category: json['category'] ?? "",
      account: json['account'] ?? "",
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      isExpense: _parseBool(json['is_expense']),
      notes: json['notes'] ?? "",
      date: json['date'] ?? "",
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == '1' || text == 'true' || text == 'expense';
  }

  /// 🔹 Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "description": description,
      "category": category,
      "account": account,
      "amount": amount,
      "is_expense": isExpense ? 1 : 0,
      "notes": notes,
      "date": date,
    };
  }
}
