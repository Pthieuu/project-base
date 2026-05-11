class CategoryModel {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final String type;

  const CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'wallet',
      color: json['color']?.toString() ?? '#1132D4',
      type: json['type']?.toString() ?? 'expense',
    );
  }
}
