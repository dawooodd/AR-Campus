import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../helpers/user_info.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/warning_dialog.dart';
import 'challenge_screen.dart';
import 'reward_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToReward;

  const HomeScreen({
    super.key,
    this.onNavigateToMap,
    this.onNavigateToReward,
  });

  // Check guest mode and enforce restrictions with WarningDialog
  Future<void> _checkGuestAndExecute(BuildContext context, VoidCallback onAuthorized) async {
    bool isGuest = await UserInfo().isGuest();
    if (!context.mounted) return;

    if (isGuest) {
      showDialog(
        context: context,
        builder: (context) => const WarningDialog(
          description: "Fitur ini tidak tersedia untuk pengguna Guest. Silakan login menggunakan akun Google Anda.",
        ),
      );
    } else {
      onAuthorized();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // Pure white background from Figma
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Header Section (Avatar 85x82 + "Halo, user!" 24px + "Level 1" 15px)
              _buildHeader(context),
              SizedBox(height: 24.h),

              // 2. Points Card (300x100px, #F7FAC7, "Poin Kamu" 15px, "58" 48px, Mascot 92x105px)
              _buildPointsCard(context),
              SizedBox(height: 32.h),

              // 3. Menu Cards Section (4 items, 275x60px each, #F6EFEF)
              _buildMenuSection(context),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // Header Section with User Avatar and Level
  Widget _buildHeader(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Avatar (circular profile picture, tap to view Profile)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: SizedBox(
                width: 70.w,
                height: 70.w,
                child: CircleAvatar(
                  radius: 35.w,
                  backgroundColor: AppColors.softYellow,
                  child: ClipOval(
                    child: _buildAvatarImage(provider),
                  ),
                ),
              ),
            ),
            SizedBox(width: 18.w),

            // Greeting and Level
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Halo, ${provider.userName}!",
                    style: AppTheme.heading1.copyWith(
                      fontSize: 24.sp,
                      color: Colors.black, // Inter Semi Bold 24px, #000000
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          "Level ${provider.level}",
                          style: AppTheme.body.copyWith(
                            fontSize: 13.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatarImage(GameProvider provider) {
    if (provider.profileImagePath != null && File(provider.profileImagePath!).existsSync()) {
      return Image.file(
        File(provider.profileImagePath!),
        width: 64.w,
        height: 64.w,
        fit: BoxFit.cover,
      );
    }
    String assetPath;
    switch (provider.selectedCharacter.toLowerCase()) {
      case 'tiger':
        assetPath = 'assets/images/tiger_mascot.jpg';
        break;
      case 'cat':
        assetPath = 'assets/images/cat_mascot.jpg';
        break;
      case 'dragon':
        assetPath = 'assets/images/dragon_mascot.jpg';
        break;
      case 'crocodile':
      default:
        assetPath = 'assets/images/crocodile_mascot.jpg';
        break;
    }
    return Image.asset(
      assetPath,
      width: 64.w,
      height: 64.w,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.person_rounded,
          size: 38.w,
          color: AppColors.primaryGreen,
        );
      },
    );
  }

  // Centered Points Card (300x100px, Soft Yellow #F7FAC7)
  Widget _buildPointsCard(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        return Container(
          width: 300.w,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.softYellow, // #F7FAC7
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.neutralGray, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left Section: "Poin Kamu" + Score
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Poin Kamu",
                      style: AppTheme.body.copyWith(
                        fontSize: 15.sp,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${provider.totalPoints}",
                      style: AppTheme.scoreBig.copyWith(
                        fontSize: 44.sp,
                        color: AppColors.primaryGreen,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              // Right Section: Star badge icon
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.stars_rounded,
                  size: 36.w,
                  color: AppColors.accentGreen,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Menu Cards (4 items, 275x60px each, #F6EFEF background, 15r radius)
  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        // Card 1: 🎮 "Mulai Game" (Play icon)
        _buildMenuCard(
          context,
          title: "Mulai Game",
          icon: Icons.sports_esports_rounded,
          iconColor: AppColors.accentGreen,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChallengeScreen()),
            );
          },
        ),
        SizedBox(height: 16.h),

        // Card 2: 🏆 "Achievement" (Trophy icon)
        _buildMenuCard(
          context,
          title: "Achievement",
          icon: Icons.emoji_events_rounded,
          iconColor: const Color(0xFFE6A100),
          onTap: () {
            _checkGuestAndExecute(context, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChallengeScreen()),
              );
            });
          },
        ),
        SizedBox(height: 16.h),

        // Card 3: 🎁 "Reward" (Gift icon)
        _buildMenuCard(
          context,
          title: "Reward",
          icon: Icons.card_giftcard_rounded,
          iconColor: const Color(0xFFE65100),
          onTap: () {
            _checkGuestAndExecute(context, () {
              if (onNavigateToReward != null) {
                onNavigateToReward!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RewardScreen()),
                );
              }
            });
          },
        ),
        SizedBox(height: 16.h),

        // Card 4: ⚙️ "Pengaturan" (Gear icon)
        _buildMenuCard(
          context,
          title: "Pengaturan",
          icon: Icons.settings_rounded,
          iconColor: AppColors.primaryGreen,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  // Single Menu Card Component (275x60px, rounded corners ~15px, background #F6EFEF)
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 275.w,
      height: 60.h,
      decoration: BoxDecoration(
        color: AppColors.lightPinkCream, // #F6EFEF
        borderRadius: BorderRadius.circular(15.r), // ~15px
        border: Border.all(color: AppColors.neutralGray, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Row(
              children: [
                // Icon (40x36px container)
                Container(
                  width: 40.w,
                  height: 36.h,
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 28.w),
                ),
                SizedBox(width: 14.w),

                // Text Label (Inter Semi Bold 20px)
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.heading2.copyWith(
                      fontSize: 18.sp,
                      color: AppColors.primaryGreen, // #273826
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Trailing chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.accentGreen,
                  size: 22.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
