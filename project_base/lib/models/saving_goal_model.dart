class SavingGoalModel {
  final int? id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String? targetDate;
  final String note;
  final bool isCompleted;

  const SavingGoalModel({
    this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.note,
    required this.isCompleted,
  });

  factory SavingGoalModel.fromJson(Map<String, dynamic> json) {
    return SavingGoalModel(
      id: int.tryParse(json['id']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      targetAmount:
          double.tryParse(json['target_amount']?.toString() ?? '') ?? 0,
      currentAmount:
          double.tryParse(json['current_amount']?.toString() ?? '') ?? 0,
      targetDate: json['target_date']?.toString(),
      note: json['note']?.toString() ?? '',
      isCompleted: json['is_completed']?.toString() == '1',
    );
  }
}
