import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_card.dart';
import '../theme/app_theme.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> challenges = [
      {"title": "Quiz", "icon": Icons.quiz, "reward": "+ XP"},
      {"title": "Cari Objek", "icon": Icons.search, "reward": "+ XP"},
      {"title": "Misi Cepat", "icon": Icons.flash_on, "reward": "+ XP"},
      {"title": "Scan QR", "icon": Icons.qr_code_scanner, "reward": "+ XP"}
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomHeader(title: 'Pilih Tantangan'),
              Expanded(
                child: ListView.builder(
                  itemCount: challenges.length,
                  itemBuilder: (context, index) {
                    final challenge = challenges[index];
                    return CustomCard(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                          child: Icon(challenge["icon"], color: AppTheme.primaryGreen),
                        ),
                        title: Text(
                          challenge["title"],
                          style: AppTheme.subtitleStyle,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            challenge["reward"],
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () {
                          // Placeholder action
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
