import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  bool agree_terms = false;
  bool hide_password = true;

  final name_controller = TextEditingController();
  final email_controller = TextEditingController();
  final pass_controller = TextEditingController();
  final confirm_controller = TextEditingController();

  Future<void> register() async {

    if(name_controller.text.isEmpty ||
        email_controller.text.isEmpty ||
        pass_controller.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if(pass_controller.text != confirm_controller.text){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password does not match")),
      );
      return;
    }

    if(!agree_terms){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept terms")),
      );
      return;
    }

    var result = await AuthService.register(
      name_controller.text,
      email_controller.text,
      pass_controller.text,
    );

    if(result["status"] == "success"){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Register successful")),
      );
      Navigator.pop(context);
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Register failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final is_dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: is_dark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF6F6F8),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: is_dark ? theme.scaffoldBackgroundColor : Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Create Account",
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
              color: is_dark ? theme.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),

              /// 👇 tạo cảm giác "card nổi" giống light mode
              boxShadow: is_dark
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Join AI Expense Manager",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Start tracking your finances smarter with AI-driven insights.",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 24),

                build_text_field(
                  "Full Name",
                  "Enter your full name",
                  name_controller,
                  Icons.person,
                  is_dark,
                ),

                build_text_field(
                  "Email Address",
                  "name@example.com",
                  email_controller,
                  Icons.email,
                  is_dark,
                ),

                build_password_field(is_dark),

                build_text_field(
                  "Confirm Password",
                  "Repeat your password",
                  confirm_controller,
                  Icons.lock,
                  is_dark,
                  obscure: true,
                ),

                const SizedBox(height: 10),

                Row(
                  children: [

                    Checkbox(
                      value: agree_terms,
                      activeColor: const Color(0xFF1132D4),
                      onChanged: (value) {
                        setState(() {
                          agree_terms = value!;
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

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1132D4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: register,
                    child: const Text(
                      "Register",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("Or continue with"),
                    ),
                    Expanded(child: Divider()),
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

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
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
        ),
      ),
    );
  }

  /// TEXT FIELD
  Widget build_text_field(
      String label,
      String hint,
      TextEditingController controller,
      IconData icon,
      bool is_dark,
      {bool obscure = false}) {

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
          fillColor: is_dark ? Colors.grey[900] : Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// PASSWORD FIELD
  Widget build_password_field(bool is_dark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: pass_controller,
        obscureText: hide_password,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          labelText: "Password",
          hintText: "Create a strong password",
          prefixIcon: const Icon(Icons.lock),

          suffixIcon: IconButton(
            icon: Icon(
              hide_password ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                hide_password = !hide_password;
              });
            },
          ),

          filled: true,
          fillColor: is_dark ? Colors.grey[900] : Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}