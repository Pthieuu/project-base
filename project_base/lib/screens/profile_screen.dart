import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:provider/provider.dart';
import '../controller/theme_controller.dart';

class ProfileScreen extends StatelessWidget {
  final String userName;
  const ProfileScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = isDark ? Colors.white70 : Colors.grey;

    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Profile",
          style: TextStyle(color: text),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// USER PROFILE
            Container(
              padding: const EdgeInsets.all(24),
              color: bg,
              child: Column(
                children: [

                  Stack(
                    children: [

                      const CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          "https://i.pravatar.cc/150?img=3",
                        ),
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF1132D4),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 18),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    userName.isNotEmpty ? userName : "User",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: text,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "user@email.com",
                    style: TextStyle(color: subText),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1132D4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "PREMIUM MEMBER",
                      style: TextStyle(
                        color: Color(0xFF1132D4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// SETTINGS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "ACCOUNT SETTINGS",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ProfileItem(
                    icon: Icons.dark_mode,
                    title: "Dark Mode",
                    trailing: Consumer<ThemeController>(
                      builder: (context, themeCtrl, child) {
                        return Switch(
                          value: themeCtrl.isDark,
                          onChanged: (value) {
                            themeCtrl.toggleTheme(value);
                          },
                        );
                      },
                    ),
                  ),

                  ProfileItem(
                    icon: Icons.notifications,
                    title: "Notifications",
                    onTap: () {},
                  ),

                  ProfileItem(
                    icon: Icons.payments,
                    title: "Currency",
                    subtitle: "USD (\$)",
                    onTap: () {},
                  ),

                  ProfileItem(
                    icon: Icons.psychology,
                    title: "AI Insights",
                    onTap: () {},
                  ),

                  const SizedBox(height: 20),

                  /// LOGOUT
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? const Color(0xFF2A1111) : Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        "Logout",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProfileItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF111111) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final border = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1132D4).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF1132D4)), // ✅ GIỮ NGUYÊN ICON
        ),
        title: Text(
          title,
          style: TextStyle(color: text),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(color: Colors.grey))
            : null,
        trailing: trailing ??
            const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
