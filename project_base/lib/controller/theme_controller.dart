import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  bool isDark = false;

  void toggleTheme(bool value) {
    isDark = value;
    notifyListeners();
  }
}