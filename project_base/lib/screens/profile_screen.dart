import 'package:flutter/material.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// USER PROFILE
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [

                  Stack(
                    children: [

                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          "https://lh3.googleusercontent.com/aida-public/AB6AXuDYVlfdE66iMDk1qyNz48S1VGQB9MHs9ft3FTnrFAvMhY481FrRNhPtYlIEm_9qz_I66DXI-Sl4hXscYFzw5vQsVLZp2ebKU5iH1kC5Y_DsfcNPIBPFDU1FCtsD2Uwhb_OFDhlu9YfJHSr5dFbib0lvvQTkzMwTSzDmbGx1UXum8gEpvKr2OzLbBE0eUVtJJL-V5vq6CT2LP5XcdANtS-HpW3b2Vuwan9PgfDqRkL8lu7L0wsdJO6xYrnMuuJVNAFuxI3P1BWeo4Rk",
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

                  const Text(
                    "Alex Rivera",
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "alex.rivera@aiexpense.ai",
                    style: TextStyle(color: Colors.grey),
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
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
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
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1132D4).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF1132D4)),
        ),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing ??
            const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}