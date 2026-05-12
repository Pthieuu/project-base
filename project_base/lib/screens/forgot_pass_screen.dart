import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_base/controller/language_controller.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: Body()));
  }
}

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.watch<LanguageController>().text;

    /// 🎯 COLOR SYSTEM (giống LoginScreen)
    const primaryColor = Color(0xFF1132D4);

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputColor = isDark
        ? const Color(0xFF0B1220)
        : const Color(0xFFF8FAFC);

    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final hintColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

    return Container(
      color: bgColor,

      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),

            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// HEADER
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, color: textPrimary),
                    ),

                    const SizedBox(width: 12),

                    Text(
                      t('reset_password'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Text(
                  t('forgot_password_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  t('reset_password_body'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary),
                ),

                const SizedBox(height: 32),

                /// EMAIL INPUT
                TextField(
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: "name@example.com",
                    hintStyle: TextStyle(color: hintColor),

                    prefixIcon: Icon(Icons.mail_outline, color: textSecondary),

                    filled: true,
                    fillColor: inputColor,

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// BUTTON
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t('reset_link_sent'))),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      t('send_reset_link'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// SUCCESS BOX
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.green.withValues(alpha: 0.15)
                        : const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.green.withValues(alpha: 0.3)
                          : const Color(0xFFB7E1C1),
                    ),
                  ),
                  child: Text(
                    t('reset_success'),
                    style: TextStyle(color: textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
