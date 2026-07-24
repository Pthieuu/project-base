import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/language_controller.dart';
import '../services/user_session.dart';

class NoSpendChallengeCard extends StatefulWidget {
  const NoSpendChallengeCard({super.key});

  @override
  State<NoSpendChallengeCard> createState() => _NoSpendChallengeCardState();
}

class _NoSpendChallengeCardState extends State<NoSpendChallengeCard> {
  _ChallengeState _state = const _ChallengeState();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await _ChallengeStore.load();
    if (mounted) setState(() => _state = state);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageController>().text;
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final progress = _state.completedDays.length / 7;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoSpendChallengeScreen()),
          );
          await _load();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.local_fire_department, color: primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('no_spend_challenge'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _state.isActive
                          ? t('challenge_progress')
                                .replaceAll(
                                  '{count}',
                                  _state.completedDays.length.toString(),
                                )
                                .replaceAll('{total}', '7')
                          : t('challenge_card_subtitle'),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (_state.isActive) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class NoSpendChallengeScreen extends StatefulWidget {
  const NoSpendChallengeScreen({super.key});

  @override
  State<NoSpendChallengeScreen> createState() => _NoSpendChallengeScreenState();
}

class _NoSpendChallengeScreenState extends State<NoSpendChallengeScreen> {
  _ChallengeState _state = const _ChallengeState();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await _ChallengeStore.load();
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final state = _ChallengeState(startDate: _dateOnly(DateTime.now()));
    await _ChallengeStore.save(state);
    if (mounted) setState(() => _state = state);
  }

  Future<void> _checkIn() async {
    if (!_state.canCheckInToday) return;
    final updated = _state.copyWith(
      completedDays: {..._state.completedDays, _dateKey(DateTime.now())},
    );
    await _ChallengeStore.save(updated);
    if (!mounted) return;
    setState(() => _state = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<LanguageController>().text('check_in_success'),
        ),
      ),
    );
  }

  Future<void> _confirmRestart() async {
    final t = context.read<LanguageController>().text;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('restart_challenge')),
        content: Text(t('restart_challenge_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t('restart')),
          ),
        ],
      ),
    );
    if (confirmed == true) await _start();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageController>().text;
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(title: Text(t('no_spend_challenge'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.72)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 54,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t('challenge_hero_title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t('challenge_hero_subtitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  t('seven_day_journey'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final completed = _state.isDayCompleted(day);
                    final current = _state.currentDay == day;
                    return Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: completed
                                  ? const Color(0xFF16A34A)
                                  : current
                                  ? primary
                                  : theme.colorScheme.surfaceContainerHighest,
                            ),
                            child: Center(
                              child: completed
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : Text(
                                      '$day',
                                      style: TextStyle(
                                        color: current ? Colors.white : null,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            t('day_short').replaceAll('{day}', '$day'),
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                if (!_state.isActive)
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.flag),
                    label: Text(t('start_challenge')),
                  )
                else if (_state.isCompleted)
                  _statusCard(
                    icon: Icons.workspace_premium,
                    color: const Color(0xFF16A34A),
                    title: t('challenge_completed'),
                    body: t('challenge_completed_body'),
                  )
                else if (_state.hasExpired)
                  _statusCard(
                    icon: Icons.refresh,
                    color: const Color(0xFFF59E0B),
                    title: t('challenge_missed'),
                    body: t('challenge_missed_body'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _state.canCheckInToday ? _checkIn : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      _state.hasCheckedInToday
                          ? t('checked_in_today')
                          : t('check_in_today'),
                    ),
                  ),
                if (_state.isActive) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _confirmRestart,
                    child: Text(t('restart_challenge')),
                  ),
                ],
                const SizedBox(height: 22),
                _statusCard(
                  icon: Icons.lightbulb_outline,
                  color: primary,
                  title: t('what_counts_unnecessary'),
                  body: t('unnecessary_examples'),
                ),
                const SizedBox(height: 12),
                _statusCard(
                  icon: Icons.shield_outlined,
                  color: const Color(0xFF0284C7),
                  title: t('essential_spending'),
                  body: t('essential_examples'),
                ),
              ],
            ),
    );
  }

  Widget _statusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeStore {
  static String get _key =>
      'no_spend_challenge_${UserSession.user_id ?? 'local'}';

  static Future<_ChallengeState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const _ChallengeState();
    try {
      return _ChallengeState.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const _ChallengeState();
    }
  }

  static Future<void> save(_ChallengeState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

class _ChallengeState {
  final DateTime? startDate;
  final Set<String> completedDays;

  const _ChallengeState({this.startDate, this.completedDays = const {}});

  bool get isActive => startDate != null;
  bool get isCompleted => completedDays.length >= 7;
  int get currentDay {
    if (startDate == null) return 0;
    return _dateOnly(DateTime.now()).difference(startDate!).inDays + 1;
  }

  bool get hasExpired => isActive && !isCompleted && currentDay > 7;
  bool get hasCheckedInToday =>
      completedDays.contains(_dateKey(DateTime.now()));
  bool get canCheckInToday =>
      isActive &&
      !isCompleted &&
      !hasExpired &&
      currentDay >= 1 &&
      currentDay <= 7 &&
      !hasCheckedInToday;

  bool isDayCompleted(int day) {
    if (startDate == null) return false;
    return completedDays.contains(
      _dateKey(startDate!.add(Duration(days: day - 1))),
    );
  }

  _ChallengeState copyWith({Set<String>? completedDays}) {
    return _ChallengeState(
      startDate: startDate,
      completedDays: completedDays ?? this.completedDays,
    );
  }

  Map<String, dynamic> toJson() => {
    'start_date': startDate?.toIso8601String(),
    'completed_days': completedDays.toList(),
  };

  factory _ChallengeState.fromJson(Map<String, dynamic> json) {
    return _ChallengeState(
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? ''),
      completedDays: (json['completed_days'] as List? ?? const [])
          .map((item) => item.toString())
          .toSet(),
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
