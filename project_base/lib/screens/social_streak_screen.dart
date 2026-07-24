import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/language_controller.dart';
import '../models/social_streak_model.dart';
import '../services/api_service.dart';

class SocialStreakCard extends StatelessWidget {
  const SocialStreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageController>().text;
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SocialStreakScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [primary.withValues(alpha: 0.2), theme.cardColor]
                  : [primary.withValues(alpha: 0.12), Colors.white],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('friend_streaks'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('friend_streaks_subtitle'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right, color: primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialStreakScreen extends StatefulWidget {
  const SocialStreakScreen({super.key});

  @override
  State<SocialStreakScreen> createState() => _SocialStreakScreenState();
}

class _SocialStreakScreenState extends State<SocialStreakScreen> {
  final _api = ApiService();
  SocialOverviewModel _overview = const SocialOverviewModel();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final overview = await _api.getSocialStreakOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _invite() async {
    final t = context.read<LanguageController>().text;
    var enteredEmail = '';
    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final theme = Theme.of(context);
          final primary = theme.primaryColor;
          final isDark = theme.brightness == Brightness.dark;
          final valid =
              enteredEmail.contains('@') &&
              enteredEmail.split('@').last.contains('.');
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t('invite_friend'),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t('friend_streaks_subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    onChanged: (value) =>
                        setSheetState(() => enteredEmail = value.trim()),
                    onSubmitted: valid
                        ? (_) => Navigator.pop(sheetContext, enteredEmail)
                        : null,
                    decoration: InputDecoration(
                      labelText: t('friend_email'),
                      hintText: 'friend@example.com',
                      prefixIcon: Icon(Icons.email_outlined, color: primary),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: valid
                        ? () => Navigator.pop(sheetContext, enteredEmail)
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded),
                    label: Text(t('send_invitation')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (email == null || email.isEmpty) return;
    await _runAction(() => _api.inviteFriend(email), t('invitation_sent'));
  }

  Future<void> _respond(FriendInvitationModel invitation, bool accept) async {
    await _runAction(
      () => _api.respondToFriendInvitation(
        invitation.friendshipId,
        accept: accept,
      ),
      context.read<LanguageController>().text(
        accept ? 'invitation_accepted' : 'invitation_rejected',
      ),
    );
  }

  Future<void> _checkIn(SocialStreakModel streak) async {
    final t = context.read<LanguageController>().text;
    final status = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t('today_checkin'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(t('checkin_privacy_note')),
              const SizedBox(height: 12),
              _statusOption(sheetContext, 'mindful', t('status_mindful')),
              _statusOption(
                sheetContext,
                'paused_purchase',
                t('status_paused_purchase'),
              ),
              _statusOption(
                sheetContext,
                'unplanned_purchase',
                t('status_unplanned_purchase'),
              ),
              _statusOption(sheetContext, 'observed', t('status_observed')),
            ],
          ),
        ),
      ),
    );
    if (status == null) return;
    await _runAction(
      () => _api.checkInSocialStreak(streak.id, status),
      t('check_in_success'),
    );
  }

  Widget _statusOption(BuildContext context, String value, String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.radio_button_unchecked),
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
  }

  Future<void> _nudge(SocialStreakModel streak) async {
    final t = context.read<LanguageController>().text;
    await _runAction(() async {
      await _api.nudgeSocialStreak(streak.id);
    }, t('nudge_sent'));
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageController>().text;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final background = isDark
        ? theme.scaffoldBackgroundColor
        : const Color(0xFFF6F6F8);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: isDark ? theme.cardColor : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(t('friend_streaks')),
        actions: [
          IconButton(
            onPressed: _invite,
            tooltip: t('invite_friend'),
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  FilledButton(onPressed: _load, child: Text(t('retry'))),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withValues(alpha: 0.72)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('friend_streaks'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                t('friend_streaks_subtitle'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_overview.pendingInvitations.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          t('pending_invitations'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_overview.pendingInvitations.length}',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._overview.pendingInvitations.map(_invitationCard),
                    const SizedBox(height: 12),
                  ],
                  if (_overview.streaks.isEmpty)
                    _emptyState()
                  else
                    ..._overview.streaks.map(_streakCard),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: _invite,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(t('invite_friend')),
      ),
    );
  }

  Widget _invitationCard(FriendInvitationModel item) {
    final t = context.read<LanguageController>().text;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    _initial(item.name),
                    style: TextStyle(
                      color: primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.email,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: primary,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _respond(item, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(t('reject')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _respond(item, true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 19),
                  label: Text(t('accept')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _streakCard(SocialStreakModel streak) {
    final t = context.read<LanguageController>().text;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.65)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _initial(streak.friendName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streak.friendName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(streak.friendEmail),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.orange,
                      size: 22,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${streak.currentStreak}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (streak.nudgedMeToday && !streak.meCheckedIn) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.orange,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t('friend_reminded_you'))),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _checkStatus(t('you'), streak.meCheckedIn, primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _checkStatus(
                  streak.friendName,
                  streak.friendCheckedIn,
                  primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: streak.meCheckedIn ? null : () => _checkIn(streak),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    streak.meCheckedIn ? t('checked_in_today') : t('check_in'),
                  ),
                ),
              ),
              if (!streak.friendCheckedIn) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _nudge(streak),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(t('nudge')),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'longest_streak',
            ).replaceAll('{count}', streak.longestStreak.toString()),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _checkStatus(String name, bool checked, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: (checked ? Colors.green : primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.schedule,
            color: checked ? Colors.green : primary,
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final t = context.read<LanguageController>().text;
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white10
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_outlined, size: 34, color: primary),
          ),
          const SizedBox(height: 14),
          Text(
            t('no_friend_streaks'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(t('no_friend_streaks_body'), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }
}
