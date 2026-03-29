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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "AI Expense Manager",

      /// 🌙 DARK MODE
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
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