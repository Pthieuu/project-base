import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_base/controller/language_controller.dart';
import 'package:project_base/models/saving_goal_model.dart';
import 'package:project_base/screens/main_screen.dart';
import 'package:project_base/services/api_service.dart';
import 'package:project_base/services/user_session.dart';
import 'package:project_base/utils/app_date_picker.dart';

class SavingGoalsScreen extends StatefulWidget {
  const SavingGoalsScreen({super.key});

  @override
  State<SavingGoalsScreen> createState() => _SavingGoalsScreenState();
}

class _SavingGoalsScreenState extends State<SavingGoalsScreen> {
  Color get _primary => Theme.of(context).primaryColor;
  static const Color _ink = Color(0xFF0F172A);
  static const Color _secondaryBlue = Color(0xFF1D4ED8);
  static const List<Color> _goalPalette = [
    Color(0xFF1D4ED8),
    Color(0xFF059669),
    Color(0xFFEA580C),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFCA8A04),
    Color(0xFF0F766E),
    Color(0xFF9333EA),
    Color(0xFFBE123C),
    Color(0xFF64748B),
  ];
  late Future<List<SavingGoalModel>> futureGoals;

  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    futureGoals = ApiService().getGoals();
  }

  void _reload() {
    setState(() {
      futureGoals = ApiService().getGoals();
    });
  }

  void _goBackToBudget() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            MainScreen(userName: UserSession.name ?? '', initialIndex: 2),
      ),
    );
  }

  static double _parseAmount(String value) {
    return double.tryParse(value.replaceAll(".", "").replaceAll(",", "")) ?? 0;
  }

  Color _goalAccentColor(SavingGoalModel goal, int index) {
    if (goal.isCompleted) return Colors.green;

    final seed = goal.id ?? goal.title.codeUnits.fold<int>(0, (a, b) => a + b);
    return _goalPalette[(seed + index) % _goalPalette.length];
  }

  Future<void> _showGoalForm({SavingGoalModel? goal}) async {
    final t = context.read<LanguageController>().text;
    final titleController = TextEditingController(text: goal?.title ?? '');
    final targetController = TextEditingController(
      text: goal == null ? '' : goal.targetAmount.toStringAsFixed(0),
    );
    final currentController = TextEditingController(
      text: goal == null ? '' : goal.currentAmount.toStringAsFixed(0),
    );
    final noteController = TextEditingController(text: goal?.note ?? '');
    DateTime? targetDate = goal?.targetDate == null || goal!.targetDate!.isEmpty
        ? null
        : DateTime.tryParse(goal.targetDate!);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  MediaQuery.viewInsetsOf(context).bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetHeader(
                      icon: Icons.flag,
                      title: goal == null
                          ? t('new_saving_goal')
                          : t('edit_goal'),
                      subtitle: t('goal_sheet_subtitle'),
                    ),
                    const SizedBox(height: 14),
                    _sheetTextField(
                      context,
                      controller: titleController,
                      label: t('goal_name'),
                      icon: Icons.edit,
                      hint: t('emergency_fund'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _sheetTextField(
                            context,
                            controller: targetController,
                            label: t('target'),
                            icon: Icons.track_changes,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _sheetTextField(
                            context,
                            controller: currentController,
                            label: t('saved'),
                            icon: Icons.savings,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _sheetTextField(
                      context,
                      controller: noteController,
                      label: t('note'),
                      icon: Icons.notes,
                      hint: t('optional'),
                    ),
                    const SizedBox(height: 10),
                    _datePickerCard(
                      context,
                      targetDate: targetDate,
                      onPicked: (picked) {
                        setSheetState(() => targetDate = picked);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(t('cancel')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final title = titleController.text.trim();
                              final target = _parseAmount(
                                targetController.text,
                              );
                              final current = _parseAmount(
                                currentController.text,
                              );
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t('enter_goal_name'))),
                                );
                                return;
                              }
                              if (target <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t('target_gt_zero'))),
                                );
                                return;
                              }
                              if (current < 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(t('saved_not_negative')),
                                  ),
                                );
                                return;
                              }

                              await ApiService().saveGoal(
                                id: goal?.id,
                                title: title,
                                targetAmount: target,
                                currentAmount: current,
                                targetDate: targetDate == null
                                    ? null
                                    : DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(targetDate!),
                                note: noteController.text.trim(),
                                isCompleted: current >= target,
                              );

                              if (context.mounted) {
                                Navigator.pop(context, true);
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
      },
    );

    if (saved == true) _reload();
  }

  Future<void> _addMoney(SavingGoalModel goal) async {
    final t = context.read<LanguageController>().text;
    final controller = TextEditingController();
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHeader(
                  icon: Icons.add,
                  title: t('add_money'),
                  subtitle: goal.title,
                ),
                const SizedBox(height: 14),
                _sheetTextField(
                  context,
                  controller: controller,
                  label: t('amount'),
                  icon: Icons.payments,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(t('cancel')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final amount = _parseAmount(controller.text);
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t('added_gt_zero'))),
                            );
                            return;
                          }
                          Navigator.pop(context, amount);
                        },
                        icon: const Icon(Icons.add),
                        label: Text(t('add')),
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

    if (amount == null || amount <= 0) return;
    final nextAmount = goal.currentAmount + amount;
    await ApiService().saveGoal(
      id: goal.id,
      title: goal.title,
      targetAmount: goal.targetAmount,
      currentAmount: nextAmount,
      targetDate: goal.targetDate,
      note: goal.note,
      isCompleted: nextAmount >= goal.targetAmount,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<LanguageController>().text;
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF6F6F8);
    final card = isDark ? theme.cardColor : Colors.white;
    final text = isDark ? Colors.white : _ink;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: card,
        iconTheme: IconThemeData(color: text),
        leading: IconButton(
          tooltip: t('back'),
          onPressed: _goBackToBudget,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          t('saving_goals'),
          style: TextStyle(color: text, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: t('add_goal'),
            onPressed: () => _showGoalForm(),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: FutureBuilder<List<SavingGoalModel>>(
        future: futureGoals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("${t('error_prefix')}: ${snapshot.error}"),
            );
          }

          final goals = snapshot.data ?? [];
          if (goals.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [_emptyStateCard(context)],
            );
          }

          final totalTarget = goals.fold<double>(
            0,
            (sum, goal) => sum + goal.targetAmount,
          );
          final totalSaved = goals.fold<double>(
            0,
            (sum, goal) => sum + goal.currentAmount,
          );

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _summaryCard(totalSaved, totalTarget, goals.length);
                }
                return _goalCard(goals[index - 1], index - 1);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(double totalSaved, double totalTarget, int goalCount) {
    final t = context.watch<LanguageController>().text;
    final progress = totalTarget <= 0
        ? 0.0
        : (totalSaved / totalTarget).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.savings, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t('saving_progress'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _whitePill("${(progress * 100).toInt()}%"),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            currencyFormat.format(totalSaved),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            t(
              'of_target',
            ).replaceAll('{amount}', currencyFormat.format(totalTarget)),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryMetric(
                  label: t('goals'),
                  value: goalCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetric(
                  label: t('remaining'),
                  value: currencyFormat.format(
                    (totalTarget - totalSaved).clamp(0.0, double.infinity),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goalCard(SavingGoalModel goal, int index) {
    final theme = Theme.of(context);
    final t = context.watch<LanguageController>().text;
    final isDark = theme.brightness == Brightness.dark;
    final progress = goal.targetAmount <= 0
        ? 0.0
        : (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(
      0.0,
      double.infinity,
    );
    final accentColor = _goalAccentColor(goal, index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: accentColor.withValues(alpha: 0.1),
                          child: Icon(
                            goal.isCompleted ? Icons.check : Icons.flag,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                "${currencyFormat.format(remaining)} ${t('remaining').toLowerCase()}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _progressPill(progress, accentColor),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        color: accentColor,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${currencyFormat.format(goal.currentAmount)} / ${currencyFormat.format(goal.targetAmount)}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: t('edit'),
                          onPressed: () => _showGoalForm(goal: goal),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: goal.isCompleted
                            ? null
                            : () => _addMoney(goal),
                        icon: const Icon(Icons.add),
                        label: Text(
                          goal.isCompleted ? t('completed') : t('add_money'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyStateCard(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<LanguageController>().text;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _secondaryBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.savings,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  t('empty_goal_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t('empty_goal_subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showGoalForm(),
              icon: const Icon(Icons.add),
              label: Text(t('add_goal')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primary,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _sheetTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: theme.textTheme.bodyLarge?.color,
        fontWeight: keyboardType == TextInputType.number
            ? FontWeight.bold
            : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _datePickerCard(
    BuildContext context, {
    required DateTime? targetDate,
    required ValueChanged<DateTime> onPicked,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageController>().text;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final picked = await showAppDatePicker(
          context: context,
          initialDate: targetDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.event, color: _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                targetDate == null
                    ? t('no_target_date')
                    : DateFormat('dd/MM/yyyy').format(targetDate),
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget _whitePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _summaryMetric({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressPill(double progress, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "${(progress * 100).toInt()}%",
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
