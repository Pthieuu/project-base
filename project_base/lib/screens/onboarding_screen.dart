import 'package:flutter/material.dart';
import 'package:project_base/widgets/app_logo.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101322)
          : const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const AppLogo(
                        size: 32,
                        iconSize: 18,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1132D4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        color: Color(0xFF1132D4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// ILLUSTRATION
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 280,
                      height: 280,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 28,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppLogo(size: 48, iconSize: 26),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Today",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "Money Flow",
                                      style: TextStyle(
                                        color: theme.textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _statusPill("+12%"),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _moneyCard(
                            isDark: isDark,
                            icon: Icons.arrow_upward,
                            title: "Income",
                            value: "+8.000.000đ",
                            color: const Color(0xFF059669),
                          ),
                          const SizedBox(height: 10),
                          _moneyCard(
                            isDark: isDark,
                            icon: Icons.arrow_downward,
                            title: "Expense",
                            value: "-245.000đ",
                            color: const Color(0xFFEA580C),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _bar(24, const Color(0xFF93C5FD)),
                                  _bar(36, const Color(0xFF1132D4)),
                                  _bar(48, const Color(0xFF7C3AED)),
                                  _bar(30, const Color(0xFFF59E0B)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1132D4,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.insights,
                                  color: Color(0xFF1132D4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 4,
                      child: _sticker(
                        icon: Icons.auto_awesome,
                        label: "AI",
                        color: const Color(0xFF7C3AED),
                        isDark: isDark,
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      child: _sticker(
                        icon: Icons.savings,
                        label: "Save",
                        color: const Color(0xFF059669),
                        isDark: isDark,
                      ),
                    ),
                    Positioned(
                      top: 88,
                      left: 0,
                      child: _sticker(
                        icon: Icons.restaurant,
                        label: "Food",
                        color: const Color(0xFFEA580C),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// CONTENT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    "Your Money, Smarter",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Experience the future of personal finance with AI-powered tracking.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// DOTS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_dot(active: true), _dot(), _dot()],
                  ),

                  const SizedBox(height: 30),

                  /// BUTTON
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1132D4),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1132D4,
                            ).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Get Started",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// bar chart nhỏ
  static Widget _bar(double h, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 8,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// dot indicator
  static Widget _dot({bool active = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1132D4) : Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  static Widget _statusPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF059669),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _moneyCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static Widget _sticker({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151827) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
