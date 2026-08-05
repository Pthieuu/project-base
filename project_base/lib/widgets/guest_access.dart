import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/language_controller.dart';
import '../screens/login_screen.dart';

Future<void> openGuestLogin(BuildContext context) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
}

class GuestModeBanner extends StatelessWidget {
  const GuestModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageController>().text;
    final primary = Theme.of(context).primaryColor;
    return Material(
      color: primary.withValues(alpha: 0.1),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, color: primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t('guest_banner'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () => openGuestLogin(context),
                child: Text(t('login_now')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GuestAccessView extends StatelessWidget {
  final IconData icon;
  final String? title;

  const GuestAccessView({
    super.key,
    this.icon = Icons.lock_outline,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageController>().text;
    final primary = Theme.of(context).primaryColor;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primary, size: 38),
              ),
              const SizedBox(height: 20),
              Text(
                title ?? t('guest_feature_title'),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                t('guest_feature_body'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => openGuestLogin(context),
                  icon: const Icon(Icons.login),
                  label: Text(t('login_now')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
