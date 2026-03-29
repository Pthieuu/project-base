import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../services/auth_service.dart';
import '../services/user_session.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;

  Future<void> login() async {

    if(emailController.text.isEmpty || passwordController.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    var result = await AuthService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if(result != null && result["status"] == "success"){

      UserSession.user_id = result["user_id"];
      UserSession.name = result["name"];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(
            userName: result["name"] ?? "",
          ),
        ),
      );

    }else{

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email or password incorrect"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A) // nền dark
          : const Color(0xFFF6F6F8),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),

            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B) // card nổi lên
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),

              // 👉 border nhẹ để tách nền
              border: isDark
                  ? Border.all(color: Colors.white.withOpacity(0.05))
                  : null,

              // 👉 shadow
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                /// HEADER
                Row(
                  children: [

                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1132D4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payments,
                        color: Color(0xFF1132D4),
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: Text(
                          "AI Expense Manager",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 40)
                  ],
                ),

                const SizedBox(height: 30),

                Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Log in to manage your finances with AI",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 40),

                /// EMAIL
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Email Address",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: emailController,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: "name@company.com",
                        prefixIcon: Icon(Icons.mail_outline, color: theme.iconTheme.color),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A) // input tối hơn card
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// PASSWORD
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Password",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const Text(
                          "Forgot password?",
                          style: TextStyle(
                            color: Color(0xFF1132D4),
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),

                      decoration: InputDecoration(
                        hintText: "Enter your password",
                        prefixIcon: Icon(Icons.lock_outline, color: theme.iconTheme.color),

                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: theme.iconTheme.color,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),

                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : Colors.white,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// LOGIN BUTTON
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1132D4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: login,
                    child: const Text(
                      "Log In",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// DIVIDER
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Or continue with",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                /// SOCIAL
                Row(
                  children: [

                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text("Google"),
                        onPressed: () {},
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.apple),
                        label: const Text("Apple"),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// REGISTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Register now",
                        style: TextStyle(
                          color: Color(0xFF1132D4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}