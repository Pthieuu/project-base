import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAccent {
  ocean('ocean', 'Ocean Blue', Color(0xFF1132D4), Icons.water_drop_outlined),
  mint('mint', 'Mint Green', Color(0xFF059669), Icons.eco_outlined),
  violet('violet', 'Violet Pop', Color(0xFF7C3AED), Icons.auto_awesome),
  rose('rose', 'Rose Glow', Color(0xFFE11D48), Icons.favorite_border),
  amber('amber', 'Amber Rush', Color(0xFFD97706), Icons.local_fire_department);

  final String key;
  final String label;
  final Color color;
  final IconData icon;

  const AppAccent(this.key, this.label, this.color, this.icon);

  static AppAccent fromKey(String? key) {
    return AppAccent.values.firstWhere(
      (item) => item.key == key,
      orElse: () => AppAccent.ocean,
    );
  }
}

class ThemeController extends ChangeNotifier {
  static const String _darkModeKey = 'app_dark_mode';
  static const String _accentKey = 'app_accent_color';

  bool isDark = false;
  AppAccent _accent = AppAccent.ocean;

  ThemeController() {
    _load();
  }

  AppAccent get accent => _accent;
  Color get accentColor => _accent.color;

  Future<void> toggleTheme(bool value) async {
    isDark = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> setAccent(AppAccent value) async {
    _accent = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentKey, value.key);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool(_darkModeKey) ?? false;
    _accent = AppAccent.fromKey(prefs.getString(_accentKey));
    notifyListeners();
  }
}
