class CategoryBudgetModel {
  final int? id;
  final String category;
  final String month;
  final double monthlyLimit;

  const CategoryBudgetModel({
    this.id,
    required this.category,
    required this.month,
    required this.monthlyLimit,
  });

  factory CategoryBudgetModel.fromJson(Map<String, dynamic> json) {
    return CategoryBudgetModel(
      id: int.tryParse(json['id']?.toString() ?? ''),
      category: json['category']?.toString() ?? '',
      month: json['month']?.toString() ?? '',
      monthlyLimit:
          double.tryParse(json['monthly_limit']?.toString() ?? '') ?? 0,
    );
  }
}
