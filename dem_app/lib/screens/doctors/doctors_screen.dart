import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';

class DoctorsScreen extends StatelessWidget {
	const DoctorsScreen({super.key});

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);

		return Scaffold(
			backgroundColor: AppColors.background,
			appBar: AppBar(title: const Text('Find Doctors')),
			bottomNavigationBar: const NeuraBottomNavBar(currentIndex: 3),
			body: SafeArea(
				child: ListView(
					padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
					children: [
						Text('Neurology Specialists', style: theme.textTheme.titleLarge),
						const SizedBox(height: 6),
						const Text(
							'Connect with verified specialists for dementia and cognitive health care.',
							style: TextStyle(color: AppColors.textSecondary),
						),
						const SizedBox(height: 16),
						_doctorCard(
							context,
							name: 'Dr. Meera Nair',
							specialty: 'Neurologist',
							experience: '12 years experience',
							availability: 'Next available: Today, 4:30 PM',
						),
						_doctorCard(
							context,
							name: 'Dr. Arjun Rao',
							specialty: 'Movement Specialist',
							experience: '9 years experience',
							availability: 'Next available: Tomorrow, 10:00 AM',
						),
					],
				),
			),
		);
	}

	Widget _doctorCard(
		BuildContext context, {
		required String name,
		required String specialty,
		required String experience,
		required String availability,
	}) {
		return Container(
			margin: const EdgeInsets.only(bottom: 14),
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(18),
				border: Border.all(color: AppColors.border),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Container(
								padding: const EdgeInsets.all(10),
								decoration: BoxDecoration(
									color: AppColors.primarySoft,
									borderRadius: BorderRadius.circular(12),
								),
								child: const Icon(
									Icons.medical_services_outlined,
									color: AppColors.primary,
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											name,
											style: const TextStyle(
												fontSize: 16,
												fontWeight: FontWeight.w700,
												color: AppColors.textPrimary,
											),
										),
										const SizedBox(height: 2),
										Text(
											specialty,
											style: const TextStyle(color: AppColors.textSecondary),
										),
									],
								),
							),
						],
					),
					const SizedBox(height: 12),
					Wrap(
						spacing: 8,
						children: [
							_chip(experience),
							_chip('Verified profile'),
						],
					),
					const SizedBox(height: 10),
					Row(
						children: [
							const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
							const SizedBox(width: 6),
							Expanded(
								child: Text(
									availability,
									style: const TextStyle(color: AppColors.textSecondary),
								),
							),
						],
					),
					const SizedBox(height: 12),
					Align(
						alignment: Alignment.centerRight,
						child: FilledButton.icon(
							onPressed: () => context.go('/consultation'),
							icon: const Icon(Icons.calendar_month_rounded, size: 18),
							label: const Text('Book Consultation'),
						),
					),
				],
			),
		);
	}

	Widget _chip(String text) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
			decoration: BoxDecoration(
				color: AppColors.backgroundAlt,
				borderRadius: BorderRadius.circular(999),
			),
			child: Text(
				text,
				style: const TextStyle(
					color: AppColors.textSecondary,
					fontSize: 12,
					fontWeight: FontWeight.w600,
				),
			),
		);
	}
}
