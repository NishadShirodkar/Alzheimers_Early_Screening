import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';

class NeuraBottomNavBar extends StatelessWidget {
	final int currentIndex;

	const NeuraBottomNavBar({
		super.key,
		required this.currentIndex,
	});

	@override
	Widget build(BuildContext context) {
		return BottomNavigationBar(
			currentIndex: currentIndex,
			selectedItemColor: AppColors.primary,
			unselectedItemColor: Colors.grey,
			type: BottomNavigationBarType.fixed,
			onTap: (index) {
				const routes = [
					'/dashboard',
					'/reports',
					'/medications',
					'/doctors',
					'/profile',
				];

				if (index != currentIndex) {
					context.go(routes[index]);
				}
			},
			items: const [
				BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
				BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Reports'),
				BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Meds'),
				BottomNavigationBarItem(
					icon: Icon(Icons.local_hospital),
					label: 'Doctors',
				),
				BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
			],
		);
	}
}
