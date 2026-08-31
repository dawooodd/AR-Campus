import 'package:flutter/material.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hadiah')),
      body: const Center(
        child: Text('Halaman Hadiah / Reward', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
