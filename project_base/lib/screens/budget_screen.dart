import 'package:flutter/material.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF6F6F8),

      appBar: AppBar(
        backgroundColor:
            isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 0,
        leading: Icon(
          Icons.arrow_back,
          color: isDark ? theme.iconTheme.color : Colors.black,
        ),
        title: Text(
          "Monthly Budget",
          style: TextStyle(
            color: isDark ? theme.textTheme.titleLarge?.color : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.more_vert,
              color: isDark ? theme.iconTheme.color : Colors.black,
            ),
          )
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// TOTAL BUDGET CARD
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1132D4).withOpacity(0.15)
                    : const Color(0xFF1132D4).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [

                  Text(
                    "Total Spent",
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "\$2,450.00",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  const Text(
                    "of \$3,000.00 budget",
                    style: TextStyle(
                      color: Color(0xFF1132D4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Overall Progress",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const Text(
                        "82%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1132D4),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 10),

                  LinearProgressIndicator(
                    value: 0.82,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF1132D4),
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey.shade300,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Text(
                        "\$550.00 remaining",
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey,
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning,
                                size: 14, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              "Near limit",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),

            /// CATEGORY TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Category Budgets",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Text(
                    "Edit All",
                    style: TextStyle(
                      color: Color(0xFF1132D4),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// LIST
            budgetItem(context,
              icon: Icons.restaurant,
              title: "Food & Dining",
              spent: "\$828 spent of \$900",
              percent: 0.92,
              color: Colors.orange,
            ),

            budgetItem(context,
              icon: Icons.home,
              title: "Housing",
              spent: "\$1,200 spent of \$1,600",
              percent: 0.75,
              color: const Color(0xFF1132D4),
            ),

            budgetItem(context,
              icon: Icons.movie,
              title: "Entertainment",
              spent: "\$176 spent of \$200",
              percent: 0.88,
              color: Colors.red,
            ),

            budgetItem(context,
              icon: Icons.shopping_bag,
              title: "Shopping",
              spent: "\$126 spent of \$300",
              percent: 0.42,
              color: Colors.green,
            ),

            const SizedBox(height: 80)
          ],
        ),
      ),
    );
  }

  /// ITEM
  static Widget budgetItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String spent,
    required double percent,
    required Color color,
  }) {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [

          Row(
            children: [

              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color), // giữ nguyên icon
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          "${(percent * 100).toInt()}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        )
                      ],
                    ),

                    Text(
                      spent,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            borderRadius: BorderRadius.circular(20),
            color: color,
            backgroundColor:
                isDark ? Colors.grey[800] : Colors.grey.shade300,
          )
        ],
      ),
    );
  }
}