import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  bool agreeTerms = false;
  bool hidePassword = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Create Account",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            const Text(
              "Join AI Expense Manager",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Start tracking your finances smarter with AI-driven insights.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            /// FULL NAME
            buildTextField(
              "Full Name",
              "Enter your full name",
              nameController,
              Icons.person,
            ),

            /// EMAIL
            buildTextField(
              "Email Address",
              "name@example.com",
              emailController,
              Icons.email,
            ),

            /// PASSWORD
            buildPasswordField(),

            /// CONFIRM PASSWORD
            buildTextField(
              "Confirm Password",
              "Repeat your password",
              confirmController,
              Icons.lock,
              obscure: true,
            ),

            const SizedBox(height: 10),

            /// TERMS
            Row(
              children: [

                Checkbox(
                  value: agreeTerms,
                  activeColor: const Color(0xFF1132D4),
                  onChanged: (value) {
                    setState(() {
                      agreeTerms = value!;
                    });
                  },
                ),

                const Expanded(
                  child: Text(
                    "By registering, you agree to our Terms of Service and Privacy Policy.",
                    style: TextStyle(fontSize: 12),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            /// REGISTER BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1132D4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {},
                child: const Text(
                  "Register",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// DIVIDER
            Row(
              children: [
                Expanded(child: Divider()),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("Or continue with"),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 20),

            /// SOCIAL LOGIN
            Row(
              children: [

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Image.network(
                      "https://cdn-icons-png.flaticon.com/512/300/300221.png",
                      width: 20,
                    ),
                    label: const Text("Google"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.apple),
                    label: const Text("Apple"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// LOGIN LINK
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(
                    color: Color(0xFF1132D4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
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
      {bool obscure = false}) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// PASSWORD FIELD
  Widget buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: passController,
        obscureText: hidePassword,
        decoration: InputDecoration(
          labelText: "Password",
          hintText: "Create a strong password",
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(
              hidePassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                hidePassword = !hidePassword;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}