import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';

class DoctorsScreen extends StatelessWidget {
	const DoctorsScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.background,
			appBar: AppBar(
				title: const Text('Find Doctors'),
				backgroundColor: AppColors.background,
			),
			bottomNavigationBar: const NeuraBottomNavBar(currentIndex: 3),
			body: ListView(
				padding: const EdgeInsets.all(20),
				children: [
					_doctorCard(context, 'Dr. Meera Nair', 'Neurologist • 12 yrs exp'),
					_doctorCard(context, 'Dr. Arjun Rao', 'Movement Specialist • 9 yrs exp'),
				],
			),
		);
	}

	Widget _doctorCard(BuildContext context, String name, String subtitle) {
		return Container(
			margin: const EdgeInsets.only(bottom: 14),
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(16),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
					const SizedBox(height: 4),
					Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
					const SizedBox(height: 12),
					Align(
						alignment: Alignment.centerRight,
						child: TextButton(
							onPressed: () => context.go('/consultation'),
							child: const Text('Book Consultation'),
						),
					),
				],
			),
		);
	}
}
