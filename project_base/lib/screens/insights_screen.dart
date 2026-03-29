import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF6F6F8),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        title: Text(
          "AI Insights",
          style: TextStyle(
            color: isDark ? theme.textTheme.titleLarge?.color : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.notifications_none,
              color: isDark ? theme.iconTheme.color : Colors.black,
            ),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// SPENDING ALERT CARD
            Container(
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [

                  Container(
                    height: 120,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.red],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.warning,
                          size: 50, color: Colors.white),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Spending Alert",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
                            Text("Today",
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey)),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Coffee spending is up 15%",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "You've spent \$45 more on coffee this month compared to your 3-month average.",
                          style: TextStyle(
                            color:
                                isDark ? Colors.grey[400] : Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [

                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF1132D4),
                                ),
                                onPressed: () {},
                                child: const Text("Analyze Habits"),
                              ),
                            ),

                            const SizedBox(width: 10),

                            OutlinedButton(
                              onPressed: () {},
                              child: Text(
                                "Dismiss",
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// SAVING SUGGESTION
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: const [
                      CircleAvatar(
                        backgroundColor: Color(0xFFDFF5E1),
                        child: Icon(Icons.savings, color: Colors.green),
                      ),
                      SizedBox(width: 10),
                      Text("Saving Suggestion",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Move \$120 to your Japan Trip goal to reach 85% progress.",
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.75,
                      minHeight: 10,
                      backgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey.shade300,
                      color: const Color(0xFF1132D4),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1132D4),
                      ),
                      onPressed: () {},
                      child: const Text("Transfer \$120 Now"),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// MONTHLY FORECAST
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Monthly Forecast",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ForecastBar(height: 80, label: "W1"),
                      ForecastBar(height: 110, label: "W2"),
                      ForecastBar(height: 140, label: "W3", active: true),
                      ForecastBar(height: 120, label: "W4"),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [

                      Column(
                        children: [
                          Text("Actual Spend",
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey)),
                          Text("\$2,140",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color)),
                        ],
                      ),

                      const Column(
                        children: [
                          Text("Predicted",
                              style: TextStyle(color: Colors.grey)),
                          Text("\$3,200",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF1132D4),
                                  fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1132D4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Color(0xFF1132D4)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You'll end the month 5% under budget.",
                            style: TextStyle(fontSize: 12),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// FORECAST BAR (giữ nguyên gần như 100%)
class ForecastBar extends StatelessWidget {
  final double height;
  final String label;
  final bool active;

  const ForecastBar({
    super.key,
    required this.height,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Column(
      children: [

        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF1132D4)
                : const Color(0xFF1132D4).withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: theme.textTheme.bodySmall?.color,
          ),
        )
      ],
    );
  }
}