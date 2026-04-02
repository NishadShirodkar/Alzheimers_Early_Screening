import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/bottom_nav_bar.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      bottomNavigationBar: const NeuraBottomNavBar(currentIndex: 0),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0E8F8F)],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Good Morning,\nRamesh 👋",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Last Assessment: 3 days ago",
                            style: TextStyle(color: Colors.white70),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          _circleIcon(Icons.notifications),
                          const SizedBox(width: 10),
                          _circleAvatar("R"),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  // RISK CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        // FAKE PROGRESS RING
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 70,
                              width: 70,
                              child: CircularProgressIndicator(
                                value: 0.8,
                                strokeWidth: 6,
                                color: AppColors.success,
                                backgroundColor: Colors.grey.shade200,
                              ),
                            ),
                            const Text("82/100",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Low Risk",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 5),
                              Text(
                                "Your neurological health looks great.\nKeep it up!",
                                style: TextStyle(fontSize: 13),
                              ),
                              SizedBox(height: 5),
                              GestureDetector(
                                onTap: () => context.go('/reports'),
                                child: Text("View full report >",
                                    style: TextStyle(
                                        color: AppColors.primary)),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // CTA CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A65), AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ready for today's check-in?",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    const Text("4 tests • ~15 minutes",
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () => context.go('/assessment'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text("Start Assessment >"),
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // QUICK ACTIONS
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Quick Actions",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _actionCard(context, Icons.description, "View Reports", "/reports"),
                    _actionCard(context, Icons.medication, "Medications", "/medications"),
                    _actionCard(context, Icons.local_hospital, "Find Doctors", "/doctors"),
                    _actionCard(context, Icons.mic, "Voice Assistant", "/voice-assistant"),
                  ],
                )
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white24,
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _circleAvatar(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white24,
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _actionCard(
  BuildContext context,
  IconData icon,
  String title,
  String route,
) {
  return GestureDetector(
    onTap: () {
      context.go(route);
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500))
        ],
      ),
    ),
  );
}
}