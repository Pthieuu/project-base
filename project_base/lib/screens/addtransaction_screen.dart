import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {

  bool isExpense = true;
  DateTime selected_date = DateTime.now();

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selected_date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selected_date = picked;
      });
    }
  }

  final description_controller = TextEditingController();
  final notes_controller = TextEditingController();
  final amount_controller = TextEditingController();

  String category = "Food & Drink";
  String account = "Main Card";

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF6F6F8),

      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Add Transaction",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
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
                          controller: amount_controller,
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
                            String numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
                            if(numbers.isEmpty) return;

                            final formatted = NumberFormat.decimalPattern('vi')
                                .format(int.parse(numbers));

                            amount_controller.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
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
                                    ? (isDark
                                        ? Colors.grey[800]
                                        : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Expense",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isExpense
                                      ? Colors.blue
                                      : Colors.grey,
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
                                    ? (isDark
                                        ? Colors.grey[800]
                                        : Colors.white)
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
                    controller: description_controller,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black),
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

                  /// TAG
                  Row(
                    children: [
                      _tag("✨ Food & Drink", true, isDark),
                      const SizedBox(width: 8),
                      _tag("☕ Coffee", false, isDark),
                    ],
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
                      dropdownColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      value: category,
                      items: const [
                        DropdownMenuItem(value: "Food & Drink", child: Text("Food & Drink")),
                        DropdownMenuItem(value: "Shopping", child: Text("Shopping")),
                        DropdownMenuItem(value: "Transport", child: Text("Transport")),
                      ],
                      onChanged: (v) => setState(() => category = v!),
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
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
                                    Icon(Icons.calendar_today,
                                        size: 16,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(selected_date),
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_drop_down)
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _card(
                          DropdownButtonFormField(
                            dropdownColor: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            value: account,
                            items: const [
                              DropdownMenuItem(value: "Main Card", child: Text("Main Card")),
                              DropdownMenuItem(value: "Cash", child: Text("Cash")),
                            ],
                            onChanged: (v) => setState(() => account = v!),
                            decoration: const InputDecoration(border: InputBorder.none),
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
                    controller: notes_controller,
                    maxLines: 3,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {

                  final data = {
                    "description": description_controller.text,
                    "category": category,
                    "account": account,
                    "amount": double.tryParse(
                      amount_controller.text.replaceAll(".", "")
                    ) ?? 0,
                    "is_expense": isExpense ? 1 : 0,
                    "notes": notes_controller.text,
                    "date": selected_date.toString()
                  };

                  await ApiService().add_transaction(data);

                  if(context.mounted){
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
          )
        ],
      ),
    );
  }

  /// TAG
  Widget _tag(String text, bool active, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? (isDark
                ? Colors.blue.withOpacity(0.2)
                : const Color(0xFFE0E7FF))
            : (isDark
                ? Colors.grey[800]
                : const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.blue : Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// CARD
  Widget _card(Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}