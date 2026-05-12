import 'package:flutter/material.dart';
import 'package:project_base/utils/category_visuals.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isExpense = true;
  DateTime selectedDate = DateTime.now();

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  final descriptionController = TextEditingController();
  final notesController = TextEditingController();
  final amountController = TextEditingController();
  final customCategoryController = TextEditingController();

  final List<String> categories = [
    "Food & Drink",
    "Shopping",
    "Transport",
    "Coffee",
    "Housing",
    "Entertainment",
    "Salary",
    "Other",
  ];
  String category = "Food & Drink";
  String account = "Main Card";

  @override
  void initState() {
    super.initState();
    _loadExistingCategories();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    notesController.dispose();
    amountController.dispose();
    customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingCategories() async {
    try {
      final loadedCategories = await ApiService().getCategories();
      if (!mounted) return;

      setState(() {
        for (final item in loadedCategories) {
          final matchesType =
              item.type == 'both' ||
              (isExpense && item.type == 'expense') ||
              (!isExpense && item.type == 'income');
          if (matchesType) {
            _addCategoryIfMissing(item.name);
          }
        }
      });
    } catch (_) {
      // The add form still works with default categories if loading fails.
    }
  }

  void _addCategoryIfMissing(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;

    final exists = categories.any(
      (item) => item.toLowerCase() == normalized.toLowerCase(),
    );
    if (!exists) {
      categories.add(normalized);
    }
  }

  Future<void> _addCustomCategory() async {
    final value = customCategoryController.text.trim();
    if (value.isEmpty) return;

    await ApiService().saveCategory(
      name: value,
      type: isExpense ? 'expense' : 'income',
    );

    if (!mounted) return;
    setState(() {
      _addCategoryIfMissing(value);
      category = categories.firstWhere(
        (item) => item.toLowerCase() == value.toLowerCase(),
        orElse: () => value,
      );
      customCategoryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF6F6F8),

      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Add Transaction",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 💰 AMOUNT
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "AMOUNT",
                          style: TextStyle(
                            color: Colors.grey,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "0",
                          ),
                          onChanged: (value) {
                            String numbers = value.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            if (numbers.isEmpty) return;

                            final formatted = NumberFormat.decimalPattern(
                              'vi',
                            ).format(int.parse(numbers));

                            amountController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// TOGGLE
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey[900]
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        /// EXPENSE
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isExpense = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isExpense
                                    ? (isDark ? Colors.grey[800] : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Expense",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isExpense ? Colors.blue : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),

                        /// INCOME
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isExpense = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isExpense
                                    ? (isDark ? Colors.grey[800] : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Income",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !isExpense
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// DESCRIPTION
                  Text(
                    "Description",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: descriptionController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter description",
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// CATEGORY SHORTCUTS
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.take(5).map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _categoryChip(item, isDark),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// CATEGORY
                  Text(
                    "Category",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _card(
                    DropdownButtonFormField(
                      key: ValueKey(category),
                      dropdownColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      initialValue: category,
                      items: categories
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => category = v!),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customCategoryController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addCustomCategory(),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: "Add custom category",
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _addCustomCategory,
                          icon: const Icon(Icons.add),
                          label: const Text("Add"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1132D4),
                            foregroundColor: Colors.white,
                            iconColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  /// DATE + ACCOUNT
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: pickDate,
                          child: _card(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(selectedDate),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _card(
                          DropdownButtonFormField(
                            key: ValueKey(account),
                            dropdownColor: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            initialValue: account,
                            items: const [
                              DropdownMenuItem(
                                value: "Main Card",
                                child: Text("Main Card"),
                              ),
                              DropdownMenuItem(
                                value: "Cash",
                                child: Text("Cash"),
                              ),
                            ],
                            onChanged: (v) => setState(() => account = v!),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// NOTES
                  Text(
                    "Notes (Optional)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Add a note...",
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          /// SAVE BUTTON
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  iconColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  final data = {
                    "description": descriptionController.text,
                    "category": category,
                    "account": account,
                    "amount":
                        double.tryParse(
                          amountController.text.replaceAll(".", ""),
                        ) ??
                        0,
                    "is_expense": isExpense ? 1 : 0,
                    "notes": notesController.text,
                    "date": selectedDate.toString(),
                  };

                  await ApiService().addTransaction(data);

                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  "Save Transaction",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String value, bool isDark) {
    final active = category.toLowerCase() == value.toLowerCase();
    final visual = categoryVisual(value);

    return ChoiceChip(
      avatar: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: visual.color.withValues(alpha: active ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          visual.icon,
          size: 15,
          color: active ? visual.color : visual.color.withValues(alpha: 0.75),
        ),
      ),
      label: Text(visual.label),
      selected: active,
      onSelected: (_) => setState(() => category = value),
      selectedColor: isDark
          ? visual.color.withValues(alpha: 0.2)
          : const Color(0xFFE0E7FF),
      backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
      labelStyle: TextStyle(
        color: active ? const Color(0xFF1132D4) : Colors.grey,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  /// CARD
  Widget _card(Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
