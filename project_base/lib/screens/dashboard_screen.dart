import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1132D4),
        onPressed: () {},
        child: const Icon(Icons.add),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              /// HEADER
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [

                    const CircleAvatar(
                      radius: 22,
                      backgroundImage:
                          NetworkImage("https://i.pravatar.cc/150?img=3"),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome back,",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "Alex Rivera",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {},
                    )
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// BALANCE CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1132D4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Total Balance",
                      style: TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: const [
                        Text(
                          "\$12,450.00",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Chip(
                          label: Text("+2.4%"),
                          backgroundColor: Colors.white24,
                        )
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "AI Insight",
                                style: TextStyle(color: Colors.white70),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "You're on track to save \$500 more this month.",
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1132D4),
                          ),
                          onPressed: () {},
                          child: const Text("Details"),
                        )
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// INCOME / EXPENSE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [

                    Expanded(
                      child: statCard(
                        icon: Icons.arrow_downward,
                        color: Colors.green,
                        title: "Income",
                        value: "\$4,200",
                        percent: "+12%",
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: statCard(
                        icon: Icons.arrow_upward,
                        color: Colors.red,
                        title: "Expenses",
                        value: "\$2,150",
                        percent: "-5%",
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// SPENDING SUMMARY
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Spending Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text("This Week"),
                          backgroundColor: Color(0x221132D4),
                        )
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        chartBar(40),
                        chartBar(65),
                        chartBar(35),
                        chartBar(85),
                        chartBar(50),
                        chartBar(75),
                        chartBar(95),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// RECENT TRANSACTIONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Recent Transactions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "See All",
                          style: TextStyle(
                            color: Color(0xFF1132D4),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 12),

                    const TransactionItem(
                      icon: Icons.coffee,
                      title: "Starbucks Coffee",
                      category: "Food & Drinks",
                      amount: "-\$5.40",
                    ),

                    const TransactionItem(
                      icon: Icons.local_gas_station,
                      title: "Shell Gas Station",
                      category: "Transport",
                      amount: "-\$42.00",
                    ),

                    const TransactionItem(
                      icon: Icons.shopping_cart,
                      title: "Whole Foods Market",
                      category: "Groceries",
                      amount: "-\$128.50",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  /// STAT CARD
  static Widget statCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String percent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Icon(icon, color: color),

          const SizedBox(height: 8),

          Text(title, style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 4),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          Text(
            percent,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// CHART BAR
  static Widget chartBar(double height) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1132D4).withOpacity(0.6),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String category;
  final String amount;

  const TransactionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.category,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [

          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(icon, color: Colors.blue),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                )
              ],
            ),
          ),

          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}