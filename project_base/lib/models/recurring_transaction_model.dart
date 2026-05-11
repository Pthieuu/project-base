class RecurringTransactionModel {
  final int? id;
  final String description;
  final String category;
  final String account;
  final double amount;
  final bool isExpense;
  final String notes;
  final String frequency;
  final String nextRunDate;
  final bool isActive;

  const RecurringTransactionModel({
    this.id,
    required this.description,
    required this.category,
    required this.account,
    required this.amount,
    required this.isExpense,
    required this.notes,
    required this.frequency,
    required this.nextRunDate,
    required this.isActive,
  });

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionModel(
      id: int.tryParse(json['id']?.toString() ?? ''),
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      account: json['account']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      isExpense: json['is_expense']?.toString() == '1',
      notes: json['notes']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? 'monthly',
      nextRunDate: json['next_run_date']?.toString() ?? '',
      isActive: json['is_active']?.toString() != '0',
    );
  }
}
