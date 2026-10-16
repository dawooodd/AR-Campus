import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../helpers/user_info.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/warning_dialog.dart';
import 'quiz_screen.dart';
import 'cari_objek.dart';
import 'misi_cepat.dart';
import 'misi_harian.dart';

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
    if (mounted) {
      setState(() {
        _isGuest = guest;
      });
    }
  }

  void _handleChallengeTap(String challengeType, VoidCallback onAuthorized) {
    if (_isGuest) {
      showDialog(
        context: context,
        builder: (context) => const WarningDialog(
          description: "Fitur tantangan tidak tersedia untuk pengguna Guest. Silakan login menggunakan akun Google Anda.",
        ),
      );
    } else {
      onAuthorized();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context, provider.totalPoints),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle
              Text(
                "Pilih tantangan yang ingin kamu mainkan!",
                style: AppTheme.body.copyWith(
                  fontSize: 15.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20.h),

              // 1. 🟢 "Quiz" card
              ChallengeCard(
                title: "Quiz",
                description: "Uji pengetahuanmu tentang kampus dengan menjawab pertanyaan!",
                rewardPoints: "100 - 200 Poin",
                emoji: "🐊",
                accentColor: AppColors.primaryGreen,
                badgeBgColor: AppColors.softYellow,
                badgeTextColor: AppColors.primaryGreen,
                onTap: () {
                  _handleChallengeTap("quiz", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuizScreen()),
                    );
                  });
                },
              ),
              SizedBox(height: 16.h),

              // 2. 🟡 "Cari Objek" card
              ChallengeCard(
                title: "Cari Objek",
                description: "Temukan objek yang tersembunyi di berbagai lokasi kampus!",
                rewardPoints: "150 - 250 Poin",
                emoji: "🐱",
                accentColor: const Color(0xFFE6A100),
                badgeBgColor: const Color(0xFFFFF9C4),
                badgeTextColor: const Color(0xFFB78103),
                onTap: () {
                  _handleChallengeTap("find_object", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CariObjekScreen()),
                    );
                  });
                },
              ),
              SizedBox(height: 16.h),

              // 3. 🟢 "Misi Cepat" card
              ChallengeCard(
                title: "Misi Cepat",
                description: "Selesaikan misi dengan cepat dan dapatkan poin ekstra!",
                rewardPoints: "100 - 300 Poin",
                emoji: "🐯",
                accentColor: AppColors.accentGreen,
                badgeBgColor: AppColors.softYellow,
                badgeTextColor: AppColors.primaryGreen,
                onTap: () {
                  _handleChallengeTap("fast_mission", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MisiCepatScreen()),
                    );
                  });
                },
              ),
              SizedBox(height: 16.h),

              // 4. 🟡 "Misi Harian" card
              ChallengeCard(
                title: "Misi Harian",
                description: "Tantangan harian yang baru setiap hari!",
                rewardPoints: "50 - 150 Poin",
                emoji: "🐉",
                accentColor: const Color(0xFF2E7D32),
                badgeBgColor: const Color(0xFFE8F5E9),
                badgeTextColor: const Color(0xFF2E7D32),
                onTap: () {
                  _handleChallengeTap("daily_mission", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MisiHarianScreen()),
                    );
                  });
                },
              ),
              SizedBox(height: 24.h),

              // Footer Tip Box
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.lightPinkCream,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.neutralGray),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primaryGreen, size: 22),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        "Tips: Selesaikan tantangan untuk mendapatkan poin dan reward menarik.",
                        style: AppTheme.body.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // Header AppBar with back button and points badge
  PreferredSizeWidget _buildAppBar(BuildContext context, int points) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Text(
        "Pilih Tantangan",
        style: AppTheme.heading1.copyWith(
          fontSize: 20.sp,
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.softYellow,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.accentYellow, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 18),
                  SizedBox(width: 4.w),
                  Text(
                    "$points",
                    style: AppTheme.body.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Challenge Card Widget with Scale-on-Tap Animation
class ChallengeCard extends StatefulWidget {
  final String title;
  final String description;
  final String rewardPoints;
  final String emoji;
  final Color accentColor;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final VoidCallback onTap;

  const ChallengeCard({
    super.key,
    required this.title,
    required this.description,
    required this.rewardPoints,
    required this.emoji,
    required this.accentColor,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.onTap,
  });

  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.03,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.neutralGray.withValues(alpha: 0.8), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mascot Avatar Illustration
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: widget.badgeBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.accentColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    widget.emoji,
                    style: TextStyle(fontSize: 32.sp),
                  ),
                ),
              ),
              SizedBox(width: 16.w),

              // Title, Description, and Reward Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTheme.heading2.copyWith(
                        fontSize: 18.sp,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      widget.description,
                      style: AppTheme.body.copyWith(
                        fontSize: 12.5.sp,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    // Reward Point Range Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: widget.badgeBgColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, color: widget.badgeTextColor, size: 14.w),
                          SizedBox(width: 4.w),
                          Text(
                            widget.rewardPoints,
                            style: AppTheme.caption.copyWith(
                              fontSize: 11.5.sp,
                              color: widget.badgeTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron Right Icon
              Icon(
                Icons.chevron_right_rounded,
                color: widget.accentColor,
                size: 24.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
