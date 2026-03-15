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

  Map<String,dynamic> toJson(){
    return {
      "description": description,
      "category": category,
      "account": account,
      "amount": amount,
      "is_expense": isExpense ? 1 : 0,
      "notes": notes,
      "date": date
    };
  }

}