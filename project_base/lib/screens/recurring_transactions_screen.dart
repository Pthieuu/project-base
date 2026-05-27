import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_base/controller/language_controller.dart';
import 'package:project_base/models/recurring_transaction_model.dart';
import 'package:project_base/services/api_service.dart';
import 'package:project_base/utils/app_date_picker.dart';
import 'package:project_base/utils/category_visuals.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  Color get _primary => Theme.of(context).primaryColor;
  late Future<List<RecurringTransactionModel>> futureItems;

  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    futureItems = ApiService().getRecurringTransactions();
  }

  void _reload() {
    setState(() {
      futureItems = ApiService().getRecurringTransactions();
    });
  }

  Future<void> _showForm({RecurringTransactionModel? item}) async {
    final t = context.read<LanguageController>().text;
    final descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    final categoryController = TextEditingController(
      text: item?.category ?? '',
    );
    final amountController = TextEditingController(
      text: item == null ? '' : item.amount.toStringAsFixed(0),
    );
    final notesController = TextEditingController(text: item?.notes ?? '');
    var account = item?.account ?? 'Main Card';
    var isExpense = item?.isExpense ?? true;
    var frequency = item?.frequency ?? 'monthly';
    var nextRunDate = item == null
        ? DateTime.now()
        : DateTime.tryParse(item.nextRunDate) ?? DateTime.now();
    var isActive = item?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                item == null ? t('new_recurring') : t('edit_recurring'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(isExpense ? t('expense') : t('income_type')),
                      value: isExpense,
                      onChanged: (value) {
                        setDialogState(() => isExpense = value);
                      },
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: t('description')),
                    ),
                    TextField(
                      controller: categoryController,
                      decoration: InputDecoration(labelText: t('category')),
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: t('amount')),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: account,
                      items: [
                        DropdownMenuItem(
                          value: "Main Card",
                          child: Text(t('main_card')),
                        ),
                        DropdownMenuItem(value: "Cash", child: Text(t('cash'))),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => account = value);
                        }
                      },
                      decoration: InputDecoration(labelText: t('account')),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: frequency,
                      items: [
                        DropdownMenuItem(
                          value: "daily",
                          child: Text(t('daily')),
                        ),
                        DropdownMenuItem(
                          value: "weekly",
                          child: Text(t('weekly')),
                        ),
                        DropdownMenuItem(
                          value: "monthly",
                          child: Text(t('monthly')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => frequency = value);
                        }
                      },
                      decoration: InputDecoration(labelText: t('frequency')),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_repeat),
                      title: Text(DateFormat('dd/MM/yyyy').format(nextRunDate)),
                      onTap: () async {
                        final picked = await showAppDatePicker(
                          context: context,
                          initialDate: nextRunDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => nextRunDate = picked);
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('active')),
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() => isActive = value);
                      },
                    ),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(labelText: t('notes')),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(t('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final description = descriptionController.text.trim();
                    final category = categoryController.text.trim();
                    final amount = _parseAmount(amountController.text);
                    if (description.isEmpty ||
                        category.isEmpty ||
                        amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            amount <= 0
                                ? t('amount_gt_zero')
                                : t('required_info'),
                          ),
                        ),
                      );
                      return;
                    }

                    await ApiService().saveRecurringTransaction(
                      id: item?.id,
                      description: description,
                      category: category,
                      account: account,
                      amount: amount,
                      isExpense: isExpense,
                      frequency: frequency,
                      nextRunDate: DateFormat('yyyy-MM-dd').format(nextRunDate),
                      notes: notesController.text.trim(),
                      isActive: isActive,
                    );

                    if (context.mounted) Navigator.pop(context, true);
                  },
                  child: Text(t('save')),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) _reload();
  }

  static double _parseAmount(String value) {
    return double.tryParse(value.replaceAll(".", "").replaceAll(",", "")) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<LanguageController>().text;
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF6F6F8);
    final card = isDark ? theme.cardColor : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: card,
        iconTheme: IconThemeData(color: text),
        title: Text(
          t('recurring'),
          style: TextStyle(color: text, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: t('add_recurring'),
            onPressed: () => _showForm(),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: FutureBuilder<List<RecurringTransactionModel>>(
        future: futureItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("${t('error_prefix')}: ${snapshot.error}"),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? theme.cardColor : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _primary.withValues(alpha: 0.1),
                        child: Icon(Icons.event_repeat, color: _primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t('no_recurring'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('no_recurring_subtitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showForm(),
                          icon: const Icon(Icons.add),
                          label: Text(t('add_recurring')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _summaryCard(items);
                return _itemCard(items[index - 1]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(List<RecurringTransactionModel> items) {
    final t = context.watch<LanguageController>().text;
    final activeItems = items.where((item) => item.isActive).toList();
    final monthlyImpact = activeItems.fold<double>(0, (sum, item) {
      final signed = item.isExpense ? -item.amount : item.amount;
      switch (item.frequency) {
        case 'daily':
          return sum + signed * 30;
        case 'weekly':
          return sum + signed * 4;
        default:
          return sum + signed;
      }
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_repeat, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('estimated_monthly_impact'),
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  currencyFormat.format(monthlyImpact),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${activeItems.length} active",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(RecurringTransactionModel item) {
    final theme = Theme.of(context);
    final t = context.watch<LanguageController>().text;
    final isDark = theme.brightness == Brightness.dark;
    final amountColor = item.isExpense ? Colors.red : Colors.green;
    final visual = categoryVisual(item.category);
    final sign = item.isExpense ? '-' : '+';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: visual.color.withValues(alpha: 0.12),
            child: Icon(visual.icon, color: visual.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  "${visual.label} - ${item.frequency} - next ${item.nextRunDate}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$sign${currencyFormat.format(item.amount)}",
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _showForm(item: item),
                child: Text(t('edit')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
