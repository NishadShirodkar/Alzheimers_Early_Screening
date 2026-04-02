import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedFilter = "All";

  final reports = [
    {
      "date": "Mar 31, 2026",
      "risk": "MEDIUM",
      "scores": [0.5, 0.6, 0.5, 0.7]
    },
    {
      "date": "Mar 15, 2026",
      "risk": "LOW",
      "scores": [0.9, 0.8, 0.85, 0.9]
    },
    {
      "date": "Feb 28, 2026",
      "risk": "LOW",
      "scores": [0.85, 0.8, 0.75, 0.9]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const NeuraBottomNavBar(currentIndex: 1),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "My Reports",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // FILTERS
              Row(
                children: ["All", "This Month", "Last 3 Months"]
                    .map((filter) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => selectedFilter = filter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedFilter == filter
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: selectedFilter == filter
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 25),

              // REPORT CARDS
              Column(
                children: reports
                    .map((report) => _reportCard(report))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportCard(Map report) {
    Color riskColor = report["risk"] == "LOW"
        ? AppColors.success
        : report["risk"] == "MEDIUM"
            ? AppColors.warning
            : AppColors.danger;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                report["date"],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${report["risk"]} RISK",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            ],
          ),

          const SizedBox(height: 15),

          // SCORE BARS
          Row(
            children: (report["scores"] as List<double>)
                .map((score) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade200,
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: score,
                          child: Container(
                            decoration: BoxDecoration(
                              color: riskColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 15),

          // VIEW REPORT
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.go('/assessment/results'),
              child: const Text(
                "View Full Report >",
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          )
        ],
      ),
    );
  }
}