import 'package:flutter/material.dart';
import 'login_screen.dart';

class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screen_width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      body: SafeArea(
        child: Stack(
          children: [
            /// 🔵 Background decoration
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: Stack(
                  children: [
                    Positioned(
                      left: screen_width * 0.4,
                      top: -200,
                      child: _circle(const Color(0x0C3D5AFE)),
                    ),
                    Positioned(
                      left: -200,
                      bottom: -200,
                      child: _circle(const Color(0x0CC04500)),
                    ),
                  ],
                ),
              ),
            ),

            /// 🔵 Main content
            SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 512),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        /// 🔵 Icon
                        _buildIcon(context),

                        const SizedBox(height: 40),

                        /// 🔵 Title
                        Text(
                          'Account Created!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF1132D4),
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// 🔵 Description
                        Text(
                          'Your AI Expense Manager account is ready.\n'
                          'Start tracking your finances smarter today.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 80),

                        /// 🔵 Button
                        _buildButton(context),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔵 Circle background
  Widget _circle(Color color) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  /// 🔵 Icon
  Widget _buildIcon(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF3D5AFE).withOpacity(0.1),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4C3D5AFE),
                blurRadius: 40,
                spreadRadius: -10,
              )
            ],
          ),
          child: const Icon(
            Icons.check,
            size: 48,
            color: Color(0xFF1132D4),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false, // 🔥 xóa toàn bộ stack
      );
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1132D4),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x333D5AFE),
            blurRadius: 10,
            offset: Offset(0, 8),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Color(0x333D5AFE),
            blurRadius: 25,
            offset: Offset(0, 20),
            spreadRadius: -5,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Get Started',
          style: TextStyle(
            color: Color(0xFFF1F0FF),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}
}