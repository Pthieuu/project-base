import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/language_controller.dart';
import 'dashboard_screen.dart';
import 'transaction_history.dart';
import 'budget_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final String userName;

  const MainScreen({super.key, required this.userName});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      DashboardScreen(userName: widget.userName),
      const TransactionHistoryScreen(),
      const BudgetScreen(),
      const InsightsScreen(),
      ProfileScreen(userName: widget.userName),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 3) {
        _screens[3] = InsightsScreen(key: UniqueKey());
      }
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final language = context.watch<LanguageController>();

    return Scaffold(
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: isDark ? Colors.white60 : Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,

        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: language.text('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: language.text('history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: language.text('budget'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.insights),
            label: language.text('insights'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: language.text('profile'),
          ),
        ],
      ),
    );
  }
}
