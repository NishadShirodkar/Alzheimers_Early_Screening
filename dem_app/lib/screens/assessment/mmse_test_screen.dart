import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/common/neura_button.dart';

class MmseTestScreen extends StatelessWidget {
	const MmseTestScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.background,
			appBar: AppBar(
				title: const Text('MMSE Test'),
				backgroundColor: AppColors.background,
			),
			body: Padding(
				padding: const EdgeInsets.all(20),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const Text(
							'What is today\'s date?',
							style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
						),
						const SizedBox(height: 12),
						TextField(
							decoration: InputDecoration(
								hintText: 'Enter response',
								filled: true,
								fillColor: Colors.white,
								border: OutlineInputBorder(
									borderRadius: BorderRadius.circular(14),
									borderSide: BorderSide.none,
								),
							),
						),
						const Spacer(),
						NeuraButton(
							text: 'Save & Continue',
							onTap: () => context.go('/assessment/voice-analysis'),
						),
					],
				),
			),
		);
	}
}
