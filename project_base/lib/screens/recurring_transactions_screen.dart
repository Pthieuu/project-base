import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_base/models/recurring_transaction_model.dart';
import 'package:project_base/services/api_service.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  static const Color _primary = Color(0xFF1132D4);
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
              title: Text(item == null ? "New recurring" : "Edit recurring"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(isExpense ? "Expense" : "Income"),
                      value: isExpense,
                      onChanged: (value) {
                        setDialogState(() => isExpense = value);
                      },
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                    ),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Amount"),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: account,
                      items: const [
                        DropdownMenuItem(
                          value: "Main Card",
                          child: Text("Main Card"),
                        ),
                        DropdownMenuItem(value: "Cash", child: Text("Cash")),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => account = value);
                        }
                      },
                      decoration: const InputDecoration(labelText: "Account"),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: frequency,
                      items: const [
                        DropdownMenuItem(value: "daily", child: Text("Daily")),
                        DropdownMenuItem(
                          value: "weekly",
                          child: Text("Weekly"),
                        ),
                        DropdownMenuItem(
                          value: "monthly",
                          child: Text("Monthly"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => frequency = value);
                        }
                      },
                      decoration: const InputDecoration(labelText: "Frequency"),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_repeat),
                      title: Text(DateFormat('dd/MM/yyyy').format(nextRunDate)),
                      onTap: () async {
                        final picked = await showDatePicker(
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
                      title: const Text("Active"),
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() => isActive = value);
                      },
                    ),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: "Notes"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final description = descriptionController.text.trim();
                    final category = categoryController.text.trim();
                    final amount = _parseAmount(amountController.text);
                    if (description.isEmpty ||
                        category.isEmpty ||
                        amount <= 0) {
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
                  child: const Text("Save"),
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
          "Recurring",
          style: TextStyle(color: text, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Add recurring",
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
            return Center(child: Text("Error: ${snapshot.error}"));
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
                        child: const Icon(Icons.event_repeat, color: _primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No recurring transactions",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Create salary, rent, subscriptions, or other repeated transactions.",
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
                          label: const Text("Add Recurring Transaction"),
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
                const Text(
                  "Estimated monthly impact",
                  style: TextStyle(color: Colors.white70),
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
    final isDark = theme.brightness == Brightness.dark;
    final amountColor = item.isExpense ? Colors.red : Colors.green;
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
            backgroundColor: amountColor.withValues(alpha: 0.1),
            child: Icon(Icons.event_repeat, color: amountColor),
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
                  "${item.category} - ${item.frequency} - next ${item.nextRunDate}",
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
                child: const Text("Edit"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
