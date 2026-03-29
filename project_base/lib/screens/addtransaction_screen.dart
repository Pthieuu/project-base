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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Add Transaction",
          style: TextStyle(color: Colors.black),
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
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
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

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
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
                                color: isExpense ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Expense",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isExpense
                                      ? const Color(0xFF2563EB)
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
                                color: !isExpense ? Colors.white : Colors.transparent,
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
                  const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  TextField(
                    controller: description_controller,
                    decoration: InputDecoration(
                      hintText: "Enter description",
                      filled: true,
                      fillColor: Colors.white,
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
                      _tag("✨ Food & Drink", true),
                      const SizedBox(width: 8),
                      _tag("☕ Coffee", false),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// CATEGORY
                  const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  _card(
                    DropdownButtonFormField(
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
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(selected_date),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_drop_down)
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10, height: 20),

                      Expanded(
                        child: _card(
                          DropdownButtonFormField(
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
                  const Text("Notes (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  TextField(
                    controller: notes_controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Add a note...",
                      filled: true,
                      fillColor: Colors.white,
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
                    "date": DateTime.now().toString()
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

  /// TAG UI
  Widget _tag(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE0E7FF) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? const Color(0xFF1D4ED8) : Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// CARD UI
  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}