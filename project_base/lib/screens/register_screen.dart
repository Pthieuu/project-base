import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_base/controller/language_controller.dart';
import 'package:project_base/widgets/app_logo.dart';
import '../services/auth_service.dart';
import 'account_created_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool agreeTerms = false;
  bool hidePassword = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final t = context.read<LanguageController>().text;
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('please_fill_all_fields'))));
      return;
    }

    if (passController.text != confirmController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('password_mismatch'))));
      return;
    }

    if (!agreeTerms) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('accept_terms'))));
      return;
    }

    var result = await AuthService.register(
      nameController.text,
      emailController.text,
      passController.text,
    );

    if (!mounted) return;

    if (result["status"] == "success") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountCreatedScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('register_failed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageController>().text;
    final primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF6F6F8),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          t('create_account'),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          /// 🔥 CARD CONTAINER (quan trọng nhất)
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),

              /// 👇 tạo cảm giác "card nổi" giống light mode
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(size: 42, iconSize: 24),
                const SizedBox(height: 18),
                Text(
                  t('join_app'),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  t('register_subtitle'),
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 24),

                buildTextField(
                  t('full_name'),
                  t('enter_full_name'),
                  nameController,
                  Icons.person,
                  isDark,
                ),

                buildTextField(
                  t('email_address'),
                  "name@example.com",
                  emailController,
                  Icons.email,
                  isDark,
                ),

                buildPasswordField(isDark, t),

                buildTextField(
                  t('confirm_password'),
                  t('repeat_password'),
                  confirmController,
                  Icons.lock,
                  isDark,
                  obscure: true,
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Checkbox(
                      value: agreeTerms,
                      activeColor: primary,
                      onChanged: (value) {
                        setState(() {
                          agreeTerms = value!;
                        });
                      },
                    ),

                    Expanded(
                      child: Text(
                        t('terms_text'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: register,
                    child: Text(
                      t('register'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(t('or_continue_with')),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Image.network(
                          "https://cdn-icons-png.flaticon.com/512/300/300221.png",
                          width: 20,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : primary,
                        ),
                        label: const Text("Google"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.apple),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : primary,
                        ),
                        label: const Text("Apple"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      t('already_account_login'),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// TEXT FIELD
  Widget buildTextField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon,
    bool isDark, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),

          filled: true,
          fillColor: isDark ? Colors.grey[900] : Colors.white,

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// PASSWORD FIELD
  Widget buildPasswordField(bool isDark, String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: passController,
        obscureText: hidePassword,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          labelText: t('password'),
          hintText: t('enter_password'),
          prefixIcon: const Icon(Icons.lock),

          suffixIcon: IconButton(
            icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                hidePassword = !hidePassword;
              });
            },
          ),

          filled: true,
          fillColor: isDark ? Colors.grey[900] : Colors.white,

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
