import 'package:flutter/material.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),

      /// HEADER
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Transaction History",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),

      /// BODY
      body: SingleChildScrollView(
        child: Column(
          children: [

            /// SUMMARY CARD
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1132D4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [

                  Text(
                    "Total Balance",
                    style: TextStyle(color: Colors.white70),
                  ),

                  SizedBox(height: 6),

                  Text(
                    "\$12,450.80",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 20),

                  Row(
                    children: [

                      Expanded(
                        child: CardStat(
                          title: "Income",
                          value: "+\$4,200",
                          color: Colors.green,
                        ),
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: CardStat(
                          title: "Expenses",
                          value: "-\$2,150",
                          color: Colors.red,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            /// TODAY
            sectionTitle("Today, Oct 24"),

            const TransactionTile(
              icon: Icons.coffee,
              name: "Starbucks Coffee",
              category: "Food & Drinks • 10:30 AM",
              amount: "-\$5.50",
              color: Colors.red,
            ),

            const TransactionTile(
              icon: Icons.payments,
              name: "Monthly Salary",
              category: "Income • 09:00 AM",
              amount: "+\$3,200",
              color: Colors.green,
            ),

            const TransactionTile(
              icon: Icons.directions_car,
              name: "Uber Ride",
              category: "Transport • 08:15 AM",
              amount: "-\$12.40",
              color: Colors.red,
            ),

            /// YESTERDAY
            sectionTitle("Yesterday, Oct 23"),

            const TransactionTile(
              icon: Icons.shopping_bag,
              name: "Amazon Purchase",
              category: "Shopping • 06:45 PM",
              amount: "-\$89.99",
              color: Colors.red,
            ),

            const TransactionTile(
              icon: Icons.subscriptions,
              name: "Netflix Subscription",
              category: "Entertainment • 11:20 AM",
              amount: "-\$15.99",
              color: Colors.red,
            ),

            const TransactionTile(
              icon: Icons.local_mall,
              name: "Whole Foods Market",
              category: "Grocery • 09:15 AM",
              amount: "-\$124.50",
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  /// SECTION TITLE
  static Widget sectionTitle(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.shade200,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    );
  }
}

/// SMALL STAT CARD
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
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// TRANSACTION TILE
class TransactionTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String category;
  final String amount;
  final Color color;

  const TransactionTile({
    super.key,
    required this.icon,
    required this.name,
    required this.category,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  category,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          )
        ],
      ),
    );
  }
}