import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/common/neura_button.dart';

class MedicationsScreen extends StatelessWidget {
	const MedicationsScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.background,
			appBar: AppBar(
				title: const Text('Medications'),
				backgroundColor: AppColors.background,
			),
			bottomNavigationBar: const NeuraBottomNavBar(currentIndex: 2),
			body: Padding(
				padding: const EdgeInsets.all(20),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const Text(
							'Today\'s Plan',
							style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
						),
						const SizedBox(height: 12),
						_medTile('Levodopa', '8:00 AM'),
						_medTile('Donepezil', '8:00 PM'),
						const Spacer(),
						NeuraButton(
							text: 'Schedule Consultation',
							onTap: () => context.go('/consultation'),
						),
					],
				),
			),
		);
	}

	Widget _medTile(String name, String time) {
		return Container(
			margin: const EdgeInsets.only(bottom: 10),
			padding: const EdgeInsets.all(14),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(14),
			),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: [
					Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
					Text(time, style: const TextStyle(color: AppColors.textSecondary)),
				],
			),
		);
	}
}
