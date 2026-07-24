import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_base/services/api_service.dart';
import '../controller/language_controller.dart';
import 'dashboard_screen.dart';
import 'transaction_history.dart';
import 'budget_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';
import 'weekly_recap_screen.dart';

class MainScreen extends StatefulWidget {
  final String userName;
  final int initialIndex;
  final bool showWeeklyRecapOnStart;

  const MainScreen({
    super.key,
    required this.userName,
    this.initialIndex = 0,
    this.showWeeklyRecapOnStart = false,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  bool _didOpenWeeklyRecap = false;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    _screens = [
      DashboardScreen(userName: widget.userName),
      const TransactionHistoryScreen(),
      const BudgetScreen(),
      const InsightsScreen(),
      ProfileScreen(userName: widget.userName),
    ];

    if (widget.showWeeklyRecapOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openWeeklyRecapAfterLogin();
      });
    }
  }

  Future<void> _openWeeklyRecapAfterLogin() async {
    if (_didOpenWeeklyRecap) return;
    _didOpenWeeklyRecap = true;

    try {
      // Let the login replacement transition finish before opening the story.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      final transactions = await ApiService().getTransactions();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => WeeklyRecapScreen(transactions: transactions),
        ),
      );
    } catch (_) {
      // The dashboard remains usable if recap data cannot be loaded.
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0) {
        _screens[0] = DashboardScreen(
          key: UniqueKey(),
          userName: widget.userName,
        );
      }
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
