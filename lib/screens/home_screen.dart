import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_card.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomHeader(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Halo, user!',
                      style: AppTheme.titleStyle,
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                      child: const Icon(Icons.person, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
              ),
              const CustomCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 32),
                      SizedBox(width: 16),
                      Text(
                        '58',
                        style: AppTheme.titleStyle,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Misi Aktif',
                style: AppTheme.subtitleStyle,
              ),
              const SizedBox(height: 8),
              // 4 Empty Slots
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return const CustomCard(
                    style: CardStyle.emptySlot,
                    padding: EdgeInsets.symmetric(vertical: 24),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
