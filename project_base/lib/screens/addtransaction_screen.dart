import 'package:flutter/material.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {

  bool isExpense = true;

  final description_controller = TextEditingController();
  final notes_controller = TextEditingController();

  String category = "Food & Drink";
  String account = "Main Card";

  String amount = "12.50";

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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 20),

                  /// AMOUNT
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Amount",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "\$$amount",
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// EXPENSE / INCOME TOGGLE
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [

                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isExpense = true;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isExpense ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Expense",
                                style: TextStyle(
                                  color: isExpense
                                      ? const Color(0xFF1132D4)
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isExpense = false;
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                "Income",
                                style: TextStyle(
                                  color: !isExpense
                                      ? const Color(0xFF1132D4)
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// DESCRIPTION
                  const Text(
                    "Description",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: description_controller,
                    decoration: InputDecoration(
                      hintText: "e.g. Starbucks Coffee",
                      prefixIcon: const Icon(Icons.edit),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// CATEGORY
                  const Text(
                    "Category",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField(
                    value: category,
                    items: const [
                      DropdownMenuItem(value: "Food & Drink", child: Text("Food & Drink")),
                      DropdownMenuItem(value: "Shopping", child: Text("Shopping")),
                      DropdownMenuItem(value: "Transport", child: Text("Transport")),
                      DropdownMenuItem(value: "Entertainment", child: Text("Entertainment")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        category = value!;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.restaurant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [

                      /// DATE
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            const Text(
                              "Date",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 8),

                            TextField(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.calendar_today),
                                hintText: "Today",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// ACCOUNT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            const Text(
                              "Account",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 8),

                            DropdownButtonFormField(
                              value: account,
                              items: const [
                                DropdownMenuItem(value: "Main Card", child: Text("Main Card")),
                                DropdownMenuItem(value: "Savings", child: Text("Savings")),
                                DropdownMenuItem(value: "Cash", child: Text("Cash")),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  account = value!;
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.credit_card),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// NOTES
                  const Text(
                    "Notes",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: notes_controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Add a note...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
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
                  backgroundColor: const Color(0xFF1132D4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {},
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
}