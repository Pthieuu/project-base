import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controller/theme_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    final theme = Provider.of<ThemeController>(context);
    const primary = Color(0xFF1132D4);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "AI Expense Manager",

      /// 🌙 DARK MODE
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        primaryColor: primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          surfaceTintColor: Colors.transparent,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Color(0xFF0F172A)),
          bodyLarge: TextStyle(color: Color(0xFF0F172A)),
          bodyMedium: TextStyle(color: Color(0xFF475569)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? primary
                : Colors.white;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? primary.withOpacity(0.35)
                : const Color(0xFFE2E8F0);
          }),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        cardColor: const Color(0xFF111111),
        primaryColor: primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? primary
                : const Color(0xFFCBD5E1);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? primary.withOpacity(0.45)
                : Colors.white24;
          }),
        ),
      ),
      themeMode: theme.isDark
          ? ThemeMode.dark
          : ThemeMode.light,

      initialRoute: "/",

      routes: {
        "/": (context) => const SplashScreen(),
        "/login": (context) => const LoginScreen(),
      },
    );
  }
}
