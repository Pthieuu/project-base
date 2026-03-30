import 'dart:math';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF101322) : const Color(0xFFF6F6F8),
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
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1132D4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1132D4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                          color: Color(0xFF1132D4),
                          fontWeight: FontWeight.w500),
                    ),
                  )
                ],
              ),
            ),

            /// ILLUSTRATION
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    /// vòng quay ngoài
                    _SpinningCircle(size: 260, duration: 20),

                    /// vòng quay trong
                    _SpinningCircle(size: 320, duration: 30, reverse: true),

                    /// CARD
                    Container(
                      width: 260,
                      height: 260,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// icon lớn
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1132D4).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.show_chart,
                              color: Color(0xFF1132D4), size: 40),
                          ),

                          /// fake text line
                          Column(
                            children: [
                              Container(
                                height: 6,
                                width: 140,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 6,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),

                          /// chart
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _bar(20),
                                  _bar(30),
                                  _bar(40),
                                ],
                              ),
                              const Icon(Icons.account_balance_wallet,
                                  color: Color(0xFF1132D4), size: 30)
                            ],
                          )
                        ],
                      ),
                    ),

                    /// floating icon 1
                    Positioned(
                      top: 20,
                      right: 10,
                      child: _floatingIcon(Icons.psychology),
                    ),

                    /// floating icon 2
                    Positioned(
                      bottom: 20,
                      left: 10,
                      child: _floatingIcon(Icons.insights),
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
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Experience the future of personal finance with AI-powered tracking.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),

                  const SizedBox(height: 30),

                  /// DOTS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(active: true),
                      _dot(),
                      _dot(),
                    ],
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
                            color: const Color(0xFF1132D4).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Get Started",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward, color: Colors.white)
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// bar chart nhỏ
  static Widget _bar(double h) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF1132D4),
        borderRadius: BorderRadius.circular(3),
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

  /// icon nổi
  static Widget _floatingIcon(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: const Color(0xFF1132D4)),
    );
  }
}

/// vòng quay animation
class _SpinningCircle extends StatefulWidget {
  final double size;
  final int duration;
  final bool reverse;

  const _SpinningCircle({
    required this.size,
    required this.duration,
    this.reverse = false,
  });

  @override
  State<_SpinningCircle> createState() => _SpinningCircleState();
}

class _SpinningCircleState extends State<_SpinningCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    )..repeat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: widget.reverse
          ? Tween(begin: 1.0, end: 0.0).animate(controller)
          : controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF1132D4).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }
}