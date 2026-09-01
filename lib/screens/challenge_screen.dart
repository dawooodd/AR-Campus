import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_card.dart';
import '../theme/app_theme.dart';
import '../helpers/user_info.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
  }

  Future<void> _checkGuestStatus() async {
    bool guest = await UserInfo().isGuest();
    setState(() {
      _isGuest = guest;
    });
  }

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
              if (_isGuest)
                Expanded(
                  child: Center(
                    child: Text(
                      'Fitur terkunci untuk Guest, silakan login.',
                      style: AppTheme.subtitleStyle,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      final challenge = challenges[index];
                      return CustomCard(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            child: Icon(challenge["icon"], color: AppTheme.primaryGreen),
                          ),
                          title: Text(
                            challenge["title"],
                            style: AppTheme.subtitleStyle,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
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
