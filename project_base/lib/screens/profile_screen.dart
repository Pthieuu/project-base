import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/language_controller.dart';
import '../controller/theme_controller.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import 'insights_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;

  const ProfileScreen({super.key, required this.userName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> _avatarOptions = [
    'https://i.pravatar.cc/150?img=3',
    'https://i.pravatar.cc/150?img=5',
    'https://i.pravatar.cc/150?img=12',
    'https://i.pravatar.cc/150?img=16',
    'https://i.pravatar.cc/150?img=24',
    'https://i.pravatar.cc/150?img=32',
  ];

  String _avatarUrl = _avatarOptions.first;
  String? _avatarFilePath;
  late String _displayName;
  late String _email;
  bool _notificationsEnabled = true;
  bool _aiInsightsEnabled = true;
  String _currency = 'VND (₫)';
  final ImagePicker _imagePicker = ImagePicker();

  String get _avatarFileKey =>
      'profile_avatar_file_${UserSession.user_id ?? 'local'}';
  String get _avatarUrlKey =>
      'profile_avatar_url_${UserSession.user_id ?? 'local'}';
  String get _notificationsKey =>
      'profile_notifications_${UserSession.user_id ?? 'local'}';
  String get _aiInsightsKey =>
      'profile_ai_insights_${UserSession.user_id ?? 'local'}';
  String get _currencyKey =>
      'profile_currency_${UserSession.user_id ?? 'local'}';
  static const List<String> _currencyOptions = [
    'VND (₫)',
    'USD (\$)',
    'EUR (€)',
    'JPY (¥)',
  ];

  @override
  void initState() {
    super.initState();
    _displayName = UserSession.name ?? widget.userName;
    _email = UserSession.email ?? 'No email available';
    _loadSavedAvatar();
    _loadProfileSettings();
  }

  Future<void> _loadSavedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFilePath = prefs.getString(_avatarFileKey);
    final savedAvatarUrl = prefs.getString(_avatarUrlKey);

    if (!mounted) return;

    if (savedFilePath != null && File(savedFilePath).existsSync()) {
      setState(() {
        _avatarFilePath = savedFilePath;
      });
      return;
    }

    if (savedAvatarUrl != null && savedAvatarUrl.isNotEmpty) {
      setState(() {
        _avatarUrl = savedAvatarUrl;
        _avatarFilePath = null;
      });
    }
  }

  Future<void> _loadProfileSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _aiInsightsEnabled = prefs.getBool(_aiInsightsKey) ?? true;
      _currency = prefs.getString(_currencyKey) ?? 'VND (₫)';
    });
  }

  Future<void> _setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _setAiInsights(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiInsightsKey, value);
    if (!mounted) return;
    setState(() => _aiInsightsEnabled = value);
  }

  Future<void> _showNotificationsSheet() async {
    final t = context.read<LanguageController>().text;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHeader(
                    icon: Icons.notifications,
                    title: t('notifications'),
                    subtitle: t('notifications_subtitle'),
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    icon: Icons.notifications_active,
                    title: t('budget_reminders'),
                    subtitle: _notificationsEnabled
                        ? 'Notifications are enabled for local reminders.'
                        : 'Notifications are muted on this device.',
                  ),
                  const SizedBox(height: 10),
                  ProfileItem(
                    icon: Icons.notifications,
                    title: t('enable_notifications'),
                    subtitle: _notificationsEnabled ? t('on') : t('off'),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        _setNotifications(value);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  ImageProvider<Object> get _avatarImageProvider {
    final filePath = _avatarFilePath;
    if (filePath != null && File(filePath).existsSync()) {
      return FileImage(File(filePath));
    }

    return NetworkImage(_avatarUrl);
  }

  Future<void> _showAvatarPicker() async {
    final t = context.read<LanguageController>().text;
    final selectedAvatar = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetHeader(
                    icon: Icons.account_circle,
                    title: t('avatar'),
                    subtitle: t('avatar_subtitle'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _AvatarActionButton(
                          icon: Icons.photo_library,
                          label: t('gallery'),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _pickAvatar(ImageSource.gallery);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AvatarActionButton(
                          icon: Icons.photo_camera,
                          label: t('camera'),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _pickAvatar(ImageSource.camera);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    t('template_avatar'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _avatarOptions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                    itemBuilder: (context, index) {
                      final avatarUrl = _avatarOptions[index];
                      final isSelected =
                          _avatarFilePath == null && avatarUrl == _avatarUrl;

                      return GestureDetector(
                        onTap: () => Navigator.pop(sheetContext, avatarUrl),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? context.read<ThemeController>().accentColor
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: CircleAvatar(
                            radius: 34,
                            backgroundImage: NetworkImage(avatarUrl),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selectedAvatar == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarUrlKey, selectedAvatar);
    await prefs.remove(_avatarFileKey);

    setState(() {
      _avatarUrl = selectedAvatar;
      _avatarFilePath = null;
    });
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final pickedImage = await _imagePicker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (pickedImage == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final extension = pickedImage.path.split('.').last;
    final fileName =
        'profile_avatar_${UserSession.user_id ?? 'local'}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final savedImage = await File(
      pickedImage.path,
    ).copy('${directory.path}/$fileName');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarFileKey, savedImage.path);
    await prefs.remove(_avatarUrlKey);

    if (!mounted) return;

    setState(() {
      _avatarFilePath = savedImage.path;
    });
  }

  Future<void> _showEditProfileSheet() async {
    final t = context.read<LanguageController>().text;
    final nameController = TextEditingController(text: _displayName);
    final emailController = TextEditingController(
      text: UserSession.email ?? (_email == 'No email available' ? '' : _email),
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetHeader(
                  icon: Icons.person,
                  title: t('edit_profile_title'),
                  subtitle: t('edit_profile_subtitle'),
                ),
                const SizedBox(height: 14),
                _profileTextField(
                  sheetContext,
                  controller: nameController,
                  label: t('name'),
                  icon: Icons.badge,
                ),
                const SizedBox(height: 10),
                _profileTextField(
                  sheetContext,
                  controller: emailController,
                  label: t('email'),
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: Text(t('cancel')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final email = emailController.text.trim();
                          if (name.isEmpty || email.isEmpty) return;

                          try {
                            final result = await ApiService().updateProfile(
                              name: name,
                              email: email,
                            );
                            UserSession.name =
                                result['name']?.toString() ?? name;
                            UserSession.email =
                                result['email']?.toString() ?? email;
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext, true);
                            }
                          } catch (error) {
                            if (!sheetContext.mounted) return;
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: Text(t('save')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved == true && mounted) {
      setState(() {
        _displayName = UserSession.name ?? _displayName;
        _email = UserSession.email ?? _email;
      });
    }
  }

  Future<void> _showCurrencySheet() async {
    final t = context.read<LanguageController>().text;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHeader(
                    icon: Icons.payments,
                    title: t('currency'),
                    subtitle: t('choose_currency'),
                  ),
                  const SizedBox(height: 14),
                  ..._currencyOptions.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SelectionTile(
                        title: item,
                        selected: item == _currency,
                        onTap: () => Navigator.pop(sheetContext, item),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, selected);
    if (!mounted) return;
    setState(() => _currency = selected);
  }

  Future<void> _showLanguageSheet() async {
    final languageController = context.read<LanguageController>();
    final t = languageController.text;
    final selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHeader(
                    icon: Icons.language,
                    title: t('language'),
                    subtitle: t('choose_language'),
                  ),
                  const SizedBox(height: 14),
                  ...AppLanguage.values.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SelectionTile(
                        title: item.label,
                        icon: Icons.language,
                        selected: item == languageController.language,
                        onTap: () => Navigator.pop(sheetContext, item),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    await languageController.setLanguage(selected);
  }

  Future<void> _showAccentSheet() async {
    final themeController = context.read<ThemeController>();
    final t = context.read<LanguageController>().text;
    final selected = await showModalBottomSheet<AppAccent>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHeader(
                    icon: Icons.palette_outlined,
                    title: t('accent_color'),
                    subtitle: t('choose_accent_color'),
                  ),
                  const SizedBox(height: 14),
                  ...AppAccent.values.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SelectionTile(
                        title: item.label,
                        icon: item.icon,
                        selected: item == themeController.accent,
                        color: item.color,
                        onTap: () => Navigator.pop(sheetContext, item),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    await themeController.setAccent(selected);
  }

  Future<void> _showAiInsightsSheet() async {
    final t = context.read<LanguageController>().text;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHeader(
                    icon: Icons.psychology,
                    title: t('ai_insights'),
                    subtitle: t('ai_subtitle'),
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    icon: Icons.auto_awesome,
                    title: t('personalized_analysis'),
                    subtitle: _aiInsightsEnabled
                        ? t('ai_enabled_note')
                        : t('ai_disabled_note'),
                  ),
                  const SizedBox(height: 10),
                  ProfileItem(
                    icon: Icons.psychology,
                    title: t('enable_ai'),
                    subtitle: _aiInsightsEnabled ? t('on') : t('off'),
                    trailing: Switch(
                      value: _aiInsightsEnabled,
                      onChanged: (value) {
                        _setAiInsights(value);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final t = context.read<LanguageController>().text;
    final shouldLogout = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHeader(
                    icon: Icons.logout,
                    title: t('logout'),
                    subtitle: t('logout_subtitle'),
                    color: const Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext, false),
                          child: Text(t('cancel')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            iconColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(sheetContext, true),
                          icon: const Icon(Icons.logout),
                          label: Text(t('logout')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldLogout != true || !mounted) return;
    InsightsScreen.clearSessionChat();
    UserSession.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _profileTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isDark ? const Color(0xFF111111) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = context.watch<LanguageController>();
    final themeController = context.watch<ThemeController>();
    final t = language.text;
    final isDark = theme.brightness == Brightness.dark;
    final primary = themeController.accentColor;
    final bg = isDark ? Colors.black : const Color(0xFFF6F6F8);
    final card = isDark ? theme.cardColor : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = isDark ? Colors.white70 : Colors.grey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: card,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          t('profile_title'),
          style: TextStyle(color: text, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: t('edit_profile'),
            onPressed: _showEditProfileSheet,
            icon: Icon(Icons.edit_outlined, color: text),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _avatarImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _showAvatarPicker,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _showAvatarPicker,
                    child: Text(t('change_avatar')),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _displayName.isNotEmpty ? _displayName : "User",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_email, style: TextStyle(color: subText)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "LOCAL ACCOUNT",
                      style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showEditProfileSheet,
                      icon: const Icon(Icons.manage_accounts),
                      label: Text(t('edit_profile')),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t('account_settings'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ProfileItem(
                    icon: Icons.dark_mode,
                    title: t('dark_mode'),
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
                    title: t('notifications'),
                    subtitle: _notificationsEnabled ? t('on') : t('off'),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: _setNotifications,
                    ),
                    onTap: _showNotificationsSheet,
                  ),
                  ProfileItem(
                    icon: Icons.payments,
                    title: t('currency'),
                    subtitle: _currency,
                    onTap: _showCurrencySheet,
                  ),
                  ProfileItem(
                    icon: Icons.language,
                    title: t('language'),
                    subtitle: language.label,
                    onTap: _showLanguageSheet,
                  ),
                  ProfileItem(
                    icon: Icons.palette_outlined,
                    title: t('accent_color'),
                    subtitle: themeController.accent.label,
                    onTap: _showAccentSheet,
                  ),
                  ProfileItem(
                    icon: Icons.psychology,
                    title: t('ai_insights'),
                    subtitle: _aiInsightsEnabled ? t('enabled') : t('disabled'),
                    trailing: Switch(
                      value: _aiInsightsEnabled,
                      onChanged: _setAiInsights,
                    ),
                    onTap: _showAiInsightsSheet,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF7F1D1D)
                            : const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        iconColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout),
                      label: Text(
                        t('logout'),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    final primary = context.watch<ThemeController>().accentColor;

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
          backgroundColor: primary.withValues(alpha: 0.1),
          child: Icon(icon, color: primary),
        ),
        title: Text(title, style: TextStyle(color: text)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(color: Colors.grey))
            : null,
        trailing:
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;

  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor = color ?? context.watch<ThemeController>().accentColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _SelectionTile({
    required this.title,
    this.icon = Icons.payments,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = color ?? context.watch<ThemeController>().accentColor;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primary : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primary.withValues(alpha: 0.1),
              child: Icon(icon, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: primary),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = context.watch<ThemeController>().accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primary.withValues(alpha: 0.1),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AvatarActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = context.watch<ThemeController>().accentColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
