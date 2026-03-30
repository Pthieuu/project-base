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
      id: json['id'],
      description: json['description'] ?? "",
      category: json['category'] ?? "",
      account: json['account'] ?? "",
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      isExpense: json['is_expense'] == 1, // convert int -> bool
      notes: json['notes'] ?? "",
      date: json['date'] ?? "",
    );
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