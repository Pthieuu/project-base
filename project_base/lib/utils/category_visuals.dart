import 'package:flutter/material.dart';

class CategoryVisual {
  final String label;
  final IconData icon;
  final Color color;

  const CategoryVisual({
    required this.label,
    required this.icon,
    required this.color,
  });
}

String displayCategoryName(String category) {
  return categoryVisual(category).label;
}

CategoryVisual categoryVisual(String category) {
  final raw = category.trim();
  final key = raw.toLowerCase();

  if (_matches(key, [
    'food',
    'food & drink',
    'food & dining',
    'meal',
    'ăn uống',
    'an uong',
    'đồ ăn',
    'do an',
  ])) {
    return const CategoryVisual(
      label: 'Food & Dining',
      icon: Icons.ramen_dining,
      color: Color(0xFFEA580C),
    );
  }

  if (_matches(key, [
    'coffee',
    'cafe',
    'tea',
    'milk tea',
    'trà sữa',
    'tra sua',
  ])) {
    return const CategoryVisual(
      label: 'Coffee',
      icon: Icons.local_cafe,
      color: Color(0xFFB45309),
    );
  }

  if (_matches(key, [
    'transport',
    'transportation',
    'xăng xe',
    'xang xe',
    'di chuyển',
    'di chuyen',
    'gas',
    'fuel',
  ])) {
    return const CategoryVisual(
      label: 'Transport',
      icon: Icons.local_gas_station,
      color: Color(0xFF0F766E),
    );
  }

  if (_matches(key, [
    'sport',
    'sports',
    'gym',
    'fitness',
    'thể thao',
    'the thao',
  ])) {
    return const CategoryVisual(
      label: 'Sport',
      icon: Icons.sports_basketball,
      color: Color(0xFF2563EB),
    );
  }

  if (_matches(key, ['shopping', 'clothes', 'fashion', 'mua sắm', 'mua sam'])) {
    return const CategoryVisual(
      label: 'Shopping',
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFDB2777),
    );
  }

  if (_matches(key, [
    'housing',
    'home',
    'rent',
    'house',
    'nhà',
    'nha',
    'nhà cửa',
  ])) {
    return const CategoryVisual(
      label: 'Housing',
      icon: Icons.maps_home_work_outlined,
      color: Color(0xFF1132D4),
    );
  }

  if (_matches(key, [
    'entertainment',
    'movie',
    'game',
    'games',
    'giải trí',
    'giai tri',
  ])) {
    return const CategoryVisual(
      label: 'Entertainment',
      icon: Icons.sports_esports_outlined,
      color: Color(0xFF7C3AED),
    );
  }

  if (_matches(key, [
    'health',
    'medical',
    'medicine',
    'sức khỏe',
    'suc khoe',
  ])) {
    return const CategoryVisual(
      label: 'Health',
      icon: Icons.health_and_safety_outlined,
      color: Color(0xFF059669),
    );
  }

  if (_matches(key, ['education', 'study', 'school', 'book', 'học', 'hoc'])) {
    return const CategoryVisual(
      label: 'Education',
      icon: Icons.menu_book_outlined,
      color: Color(0xFF0891B2),
    );
  }

  if (_matches(key, ['salary', 'income', 'paycheck', 'lương'])) {
    return const CategoryVisual(
      label: 'Salary',
      icon: Icons.payments_outlined,
      color: Color(0xFF059669),
    );
  }

  if (_matches(key, ['saving', 'savings', 'save'])) {
    return const CategoryVisual(
      label: 'Saving',
      icon: Icons.savings_outlined,
      color: Color(0xFF1132D4),
    );
  }

  return CategoryVisual(
    label: raw.isEmpty ? 'Other' : raw,
    icon: Icons.category_outlined,
    color: const Color(0xFF64748B),
  );
}

bool _matches(String key, List<String> values) {
  return values.any((value) => key == value || key.contains(value));
}
