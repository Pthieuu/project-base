import 'package:flutter/material.dart';
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
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
        selectedItemColor: const Color(0xFF1132D4),
        unselectedItemColor: isDark ? Colors.white60 : Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Budget"),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: "Insights"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
