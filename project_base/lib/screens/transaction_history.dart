import 'package:flutter/material.dart';
import 'package:project_base/models/transaction_model.dart';
import 'package:project_base/services/api_service.dart';
import 'package:project_base/services/user_session.dart';
import 'package:project_base/utils/app_date_picker.dart';
import 'package:project_base/utils/category_visuals.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<TransactionModel>> futureTransactions;
  final TextEditingController searchController = TextEditingController();
  String typeFilter = 'All';
  String categoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    if (UserSession.user_id != null) {
      futureTransactions = ApiService().getTransactions(UserSession.user_id!);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _reloadTransactions() {
    if (UserSession.user_id == null) return;
    setState(() {
      futureTransactions = ApiService().getTransactions(UserSession.user_id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark
            ? theme.appBarTheme.backgroundColor
            : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? theme.iconTheme.color : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Transaction History",
          style: TextStyle(
            color: isDark ? theme.textTheme.titleLarge?.color : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: UserSession.user_id == null
          ? const Center(child: Text("User not logged in"))
          : FutureBuilder<List<TransactionModel>>(
              future: futureTransactions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No transactions found."));
                }

                final allTransactions = [...snapshot.data!]
                  ..sort(
                    (a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)),
                  );
                final categories = _extractCategories(allTransactions);
                final transactions = _filterTransactions(allTransactions);
                final groupedTransactions = _groupTransactionsByDate(
                  transactions,
                );

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      buildSummaryCard(allTransactions),
                      _buildFilters(categories, isDark),
                      if (transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text("No transactions match your filters."),
                        ),
                      for (final group in groupedTransactions.entries) ...[
                        sectionTitle(_sectionLabel(group.key), isDark),
                        ...group.value.map(
                          (tx) => TransactionTile.fromModel(
                            tx,
                            onTap: () => _showTransactionActions(tx),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Map<String, List<TransactionModel>> _groupTransactionsByDate(
    List<TransactionModel> transactions,
  ) {
    final grouped = <String, List<TransactionModel>>{};
    for (final tx in transactions) {
      final date = _parseDate(tx.date);
      final key = DateFormat('yyyy-MM-dd').format(date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  List<String> _extractCategories(List<TransactionModel> transactions) {
    final categories =
        transactions
            .map((tx) => tx.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...categories];
  }

  List<TransactionModel> _filterTransactions(
    List<TransactionModel> transactions,
  ) {
    final query = searchController.text.trim().toLowerCase();
    return transactions.where((tx) {
      final matchesSearch =
          query.isEmpty ||
          tx.description.toLowerCase().contains(query) ||
          tx.category.toLowerCase().contains(query) ||
          tx.notes.toLowerCase().contains(query) ||
          tx.amount.toString().contains(query);

      final matchesType =
          typeFilter == 'All' ||
          (typeFilter == 'Income' && !tx.isExpense) ||
          (typeFilter == 'Expense' && tx.isExpense);

      final matchesCategory =
          categoryFilter == 'All' ||
          tx.category.toLowerCase() == categoryFilter.toLowerCase();

      return matchesSearch && matchesType && matchesCategory;
    }).toList();
  }

  Widget _buildFilters(List<String> categories, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: "Search description, category, note...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? const Color(0xFF111111) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _filterDropdown(
                  value: typeFilter,
                  items: const ['All', 'Income', 'Expense'],
                  onChanged: (value) => setState(() => typeFilter = value),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _filterDropdown(
                  value: categories.contains(categoryFilter)
                      ? categoryFilter
                      : 'All',
                  items: categories,
                  onChanged: (value) => setState(() => categoryFilter = value),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF111111) : Colors.white,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }

  String _sectionLabel(String dateKey) {
    final date = DateTime.tryParse(dateKey);
    if (date == null) return dateKey;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);

    if (day == today) return "Today";
    if (day == today.subtract(const Duration(days: 1))) {
      return "Yesterday";
    }

    return DateFormat('dd/MM/yyyy').format(day);
  }

  static DateTime _parseDate(String value) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _showTransactionActions(TransactionModel tx) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tx.description.isEmpty ? tx.category : tx.description,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${tx.category} • ${DateFormat('dd/MM/yyyy HH:mm').format(_parseDate(tx.date))}",
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditTransactionDialog(tx);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit"),
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
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteTransaction(tx);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text("Delete"),
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
  }

  Future<void> _showEditTransactionDialog(TransactionModel tx) async {
    if (tx.id == null) return;

    final descriptionController = TextEditingController(text: tx.description);
    final categoryController = TextEditingController(text: tx.category);
    final accountController = TextEditingController(text: tx.account);
    final amountController = TextEditingController(
      text: tx.amount.toStringAsFixed(0),
    );
    final notesController = TextEditingController(text: tx.notes);
    var isExpense = tx.isExpense;
    var selectedDate = _parseDate(tx.date);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final visual = categoryVisual(categoryController.text);
            final primary = const Color(0xFF1132D4);
            final sheetColor = isDark ? theme.cardColor : Colors.white;

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  6,
                  16,
                  MediaQuery.viewInsetsOf(context).bottom + 16,
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: sheetColor,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: visual.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(visual.icon, color: visual.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Edit transaction",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                Text(
                                  visual.label,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF151827)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _typeSegment(
                              label: "Expense",
                              icon: Icons.arrow_downward,
                              active: isExpense,
                              activeColor: const Color(0xFFDC2626),
                              onTap: () {
                                setDialogState(() => isExpense = true);
                              },
                            ),
                            _typeSegment(
                              label: "Income",
                              icon: Icons.arrow_upward,
                              active: !isExpense,
                              activeColor: const Color(0xFF059669),
                              onTap: () {
                                setDialogState(() => isExpense = false);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _editField(
                        controller: descriptionController,
                        label: "Description",
                        icon: Icons.notes,
                      ),
                      _editField(
                        controller: categoryController,
                        label: "Category",
                        icon: Icons.category_outlined,
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      _editField(
                        controller: accountController,
                        label: "Account",
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      _editField(
                        controller: amountController,
                        label: "Amount",
                        icon: Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      _editField(
                        controller: notesController,
                        label: "Notes",
                        icon: Icons.sticky_note_2_outlined,
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final picked = await showAppDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                selectedDate.hour,
                                selectedDate.minute,
                              );
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF151827)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(selectedDate),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          iconColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          final amount =
                              double.tryParse(
                                amountController.text
                                    .replaceAll(".", "")
                                    .replaceAll(",", ""),
                              ) ??
                              0;

                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Số tiền phải lớn hơn 0đ."),
                              ),
                            );
                            return;
                          }

                          await ApiService().updateTransaction({
                            "id": tx.id,
                            "description": descriptionController.text.trim(),
                            "category": categoryController.text.trim(),
                            "account": accountController.text.trim(),
                            "amount": amount,
                            "is_expense": isExpense ? 1 : 0,
                            "notes": notesController.text.trim(),
                            "date": selectedDate.toString(),
                          });

                          if (!sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          _reloadTransactions();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text(
                          "Save changes",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    descriptionController.dispose();
    categoryController.dispose();
    accountController.dispose();
    amountController.dispose();
    notesController.dispose();
  }

  Widget _typeSegment({
    required String label,
    required IconData icon,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: active ? Colors.white : activeColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : activeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1132D4)),
          filled: true,
          fillColor: isDark ? const Color(0xFF151827) : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF1132D4), width: 1.4),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(TransactionModel tx) async {
    if (tx.id == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete transaction?"),
          content: const Text("This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await ApiService().deleteTransaction(tx.id!);
    _reloadTransactions();
  }

  // Build summary card
  Widget buildSummaryCard(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    double carriedBalance = 0;
    double monthlyIncome = 0;
    double monthlyExpense = 0;

    for (var tx in transactions) {
      final txDate = _parseDate(tx.date);
      final txMonth = DateTime(txDate.year, txDate.month);
      final signedAmount = tx.isExpense ? -tx.amount : tx.amount;

      if (txMonth.isBefore(currentMonth)) {
        carriedBalance += signedAmount;
      } else if (txMonth == currentMonth) {
        if (tx.isExpense) {
          monthlyExpense += tx.amount;
        } else {
          monthlyIncome += tx.amount;
        }
      }
    }

    final monthBalance = carriedBalance + monthlyIncome - monthlyExpense;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final monthLabel = DateFormat('MM/yyyy').format(now);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1132D4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Balance for $monthLabel",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            formatter.format(monthBalance),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 82,
            child: Row(
              children: [
                Expanded(
                  child: CardStat(
                    title: "Income",
                    value: formatter.format(monthlyIncome),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CardStat(
                    title: "Expense",
                    value: formatter.format(monthlyExpense),
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CardStat(
                    title: "Carried",
                    value: formatter.format(carriedBalance),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget sectionTitle(String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? Colors.grey[850] : Colors.grey.shade200,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: isDark ? Colors.grey[400] : Colors.grey,
        ),
      ),
    );
  }
}

/// Small card stat
class CardStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const CardStat({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String category;
  final String amount;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.category,
    required this.amount,
    this.onTap,
  });

  factory TransactionTile.fromModel(
    TransactionModel tx, {
    VoidCallback? onTap,
  }) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final categoryStyle = _categoryStyle(tx.category);
    final displayCategory = _displayCategory(tx.category);
    final displayName = displayCategory == "Food & Dining"
        ? "Food & Dining"
        : tx.description;

    return TransactionTile(
      icon: categoryStyle.icon,
      iconColor: categoryStyle.color,
      name: displayName,
      category: "$displayCategory • ${tx.date.substring(11, 16)}",
      amount: "${tx.isExpense ? '-' : '+'}${formatter.format(tx.amount)}",
      onTap: onTap,
    );
  }

  static String _displayCategory(String category) {
    return displayCategoryName(category);
  }

  static _CategoryStyle _categoryStyle(String category) {
    final visual = categoryVisual(category);
    return _CategoryStyle(icon: visual.icon, color: visual.color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    /// 🔥 xác định income / expense
    final isExpense = amount.startsWith('-');

    /// 🎨 màu số tiền theo income / expense
    final amountColor = isExpense
        ? (isDark ? Colors.red[300]! : Colors.red)
        : (isDark ? Colors.green[300]! : Colors.green);

    /// 🎨 background icon
    final bgColor = iconColor.withValues(alpha: isDark ? 0.2 : 0.1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: bgColor,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(fontWeight: FontWeight.bold, color: amountColor),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStyle {
  final IconData icon;
  final Color color;

  const _CategoryStyle({required this.icon, required this.color});
}
