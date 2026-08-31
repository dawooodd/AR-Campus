import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'reward_screen.dart';
import 'profile_screen.dart';
import 'challenge_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/warning_dialog.dart';
import '../helpers/user_info.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
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

  void _onNavTapped(int index) {
    if (index == 2 && _isGuest) {
      showDialog(
        context: context,
        builder: (context) => const WarningDialog(
          description: "Fitur ini hanya untuk pengguna terdaftar",
        ),
      );
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNavigateToMap: () {
              _onNavTapped(1);
            },
          ),
          const MapScreen(),
          const RewardScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          _onNavTapped(index);
        },
      ),
    );
  }
}
