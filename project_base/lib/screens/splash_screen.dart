import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: Stack(
        children: [

          /// background blur circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF1132D4).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF1132D4).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          /// main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                /// logo
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1132D4),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1132D4).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: Colors.white,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 30),

                /// app name
                const Text(
                  "AI Expense Manager",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "SMART FINANCIAL CONTROL",
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          /// loading section
          Positioned(
            bottom: 80,
            left: 40,
            right: 40,
            child: Column(
              children: [

                /// progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: 0.45,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade300,
                    color: const Color(0xFF1132D4),
                  ),
                ),

                const SizedBox(height: 15),

                /// loading text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    RotationTransition(
                      turns: _controller,
                      child: const Icon(
                        Icons.autorenew,
                        color: Color(0xFF1132D4),
                      ),
                    ),

                    const SizedBox(width: 10),

                    const Text(
                      "Analysing transactions...",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}