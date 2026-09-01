import 'package:flutter/material.dart';
import 'success_screen.dart';

class SuccessClaimScreen extends StatelessWidget {
  final int pointsEarned;
  final String missionTitle;
  final String missionSubtitle;
  final VoidCallback? onContinue;

  const SuccessClaimScreen({
    super.key,
    this.pointsEarned = 100,
    this.missionTitle = "Tantangan",
    this.missionSubtitle = "Tantangan berhasil diselesaikan",
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SuccessScreen(
      pointsEarned: pointsEarned,
      missionTitle: missionTitle,
      missionSubtitle: missionSubtitle,
      onContinue: onContinue,
      autoClaimPoints: false, // Prevents duplicate claims if caller already awarded points
    );
  }
}
