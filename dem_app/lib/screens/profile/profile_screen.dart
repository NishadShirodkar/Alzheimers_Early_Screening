import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/common/neura_button.dart';

class ProfileScreen extends StatelessWidget {
	const ProfileScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.background,
			appBar: AppBar(
				title: const Text('My Profile'),
				backgroundColor: AppColors.background,
			),
			bottomNavigationBar: const NeuraBottomNavBar(currentIndex: 4),
			body: Padding(
				padding: const EdgeInsets.all(20),
				child: Column(
					children: [
						const CircleAvatar(
							radius: 46,
							backgroundColor: AppColors.primary,
							child: Text('R', style: TextStyle(fontSize: 32, color: Colors.white)),
						),
						const SizedBox(height: 14),
						const Text(
							'Ramesh Kumar',
							style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
						),
						const SizedBox(height: 24),
						_profileTile('Phone', '+91 98765 43210'),
						_profileTile('Emergency Contact', 'Sita Kumar'),
						_profileTile('Gender', 'Male'),
						const Spacer(),
						NeuraButton(
							text: 'Edit Profile',
							onTap: () => context.go('/profile-setup'),
						),
					],
				),
			),
		);
	}

	Widget _profileTile(String label, String value) {
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
					Text(label, style: const TextStyle(color: AppColors.textSecondary)),
					Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
				],
			),
		);
	}
}
