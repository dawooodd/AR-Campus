import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../helpers/user_info.dart';
import '../widgets/warning_dialog.dart';
import 'challenge_screen.dart';
import 'reward_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToMap;
  const HomeScreen({super.key, this.onNavigateToMap});

  void _checkGuestAndNavigate(BuildContext context, Widget screen) async {
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    _buildMenuCard(
                      context,
                      title: "Mulai Game",
                      icon: Icons.play_circle_fill,
                      onTap: () {
                        if (onNavigateToMap != null) {
                          onNavigateToMap!();
                        }
                      },
                    ),
                    SizedBox(height: 16.h),
                    _buildMenuCard(
                      context,
                      title: "Pencapaian",
                      icon: Icons.emoji_events,
                      onTap: () {
                        _checkGuestAndNavigate(context, const ChallengeScreen());
                      },
                    ),
                    SizedBox(height: 16.h),
                    _buildMenuCard(
                      context,
                      title: "Hadiah",
                      icon: Icons.card_giftcard,
                      onTap: () {
                        _checkGuestAndNavigate(context, const RewardScreen());
                      },
                    ),
                    SizedBox(height: 16.h),
                    _buildMenuCard(
                      context,
                      title: "Pengaturan",
                      icon: Icons.settings,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 60.h, left: 24.w, right: 24.w, bottom: 30.h),
      color: AppColors.primaryGreen,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.backgroundWhite,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.pets,
                        size: 30.w,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<GameProvider>(
                        builder: (context, provider, child) {
                          return Text(
                            "Halo, ${provider.userName}!",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.star, color: AppColors.accentYellow, size: 16.w),
                          SizedBox(width: 4.w),
                          Consumer<GameProvider>(
                            builder: (context, provider, child) {
                              return Text(
                                "${provider.totalPoints} Poin",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 12.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shield, color: Colors.white, size: 12.w),
                                SizedBox(width: 4.w),
                                Consumer<GameProvider>(
                                  builder: (context, provider, child) {
                                    return Text(
                                      "Level ${provider.level}",
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Stack(
                children: [
                  Icon(Icons.notifications_none, color: Colors.white, size: 28.w),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: AppColors.errorRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "3",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryGreen, size: 28.w),
                SizedBox(width: 16.w),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppColors.outlineGreen, size: 24.w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
