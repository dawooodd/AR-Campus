import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'summary_screen.dart';

class SuccessScreen extends StatefulWidget {
  final int pointsEarned;
  final String missionTitle;
  final String missionSubtitle;
  final VoidCallback? onContinue;
  final bool autoClaimPoints;

  const SuccessScreen({
    super.key,
    this.pointsEarned = 100,
    this.missionTitle = "Tantangan",
    this.missionSubtitle = "Tantangan berhasil diselesaikan",
    this.onContinue,
    this.autoClaimPoints = true,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Confetti Controller (celebration particle animation)
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    // Fade-in & slide-up animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();

    // Automatically update points if configured
    if (widget.autoClaimPoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<GameProvider>(context, listen: false).claimPoints(widget.pointsEarned);
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SummaryScreen()),
      );
    }
  }

  void _handleBackToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 1. Decorative botanical corner accents
          _buildCornerDecorations(),

          // 2. Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 10.h),

                        // Success Checkmark Icon (Green circle with white checkmark)
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentGreen, // #96B55F
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGreen.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                        SizedBox(height: 18.h),

                        // Title: "Berhasil!" (Inter Semi Bold 24px, #273826)
                        Text(
                          "Berhasil!",
                          style: AppTheme.heading1.copyWith(
                            fontSize: 26.sp,
                            color: AppColors.primaryGreen, // #273826
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 6.h),

                        // Subtitle: "Tantangan berhasil diselesaikan"
                        Text(
                          widget.missionSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTheme.body.copyWith(
                            fontSize: 15.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Reward Section Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
                          decoration: BoxDecoration(
                            color: AppColors.softYellow.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(22.r),
                            border: Border.all(color: AppColors.accentYellow.withValues(alpha: 0.8), width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Kamu mendapatkan:",
                                style: AppTheme.body.copyWith(
                                  fontSize: 14.sp,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 36),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "+${widget.pointsEarned} Poin",
                                    style: AppTheme.heading1.copyWith(
                                      fontSize: 32.sp,
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Happy Crocodile Mascot Illustration (Centered)
                        Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.lightPinkCream,
                            border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/crocodile_mascot.jpg',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Text("🐊", style: TextStyle(fontSize: 50)),
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Motivation Text Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: AppColors.lightPinkCream,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.neutralGray),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text("🎁", style: TextStyle(fontSize: 22)),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  "Terus selesaikan misi lainnya dan kumpulkan lebih banyak poin!",
                                  style: AppTheme.body.copyWith(
                                    fontSize: 12.5.sp,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 28.h),

                        // "Lanjutkan" (Continue) Button (Accent Green, Pill Shape)
                        SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGreen, // #96B55F
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r), // Pill shape
                              ),
                              elevation: 3,
                            ),
                            onPressed: _handleContinue,
                            child: Text(
                              "Lanjutkan",
                              style: AppTheme.heading2.copyWith(
                                fontSize: 18.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // "Kembali ke Beranda" (Back to Home) Button (Outline Style)
                        SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                            onPressed: _handleBackToHome,
                            child: Text(
                              "Kembali ke Beranda",
                              style: AppTheme.heading2.copyWith(
                                fontSize: 17.sp,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Confetti Celebration Cannon (Emits from top-center)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // shoot downwards
              maxBlastForce: 6,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.25,
              colors: const [
                AppColors.accentGreen,
                AppColors.softYellow,
                AppColors.accentYellow,
                AppColors.primaryGreen,
                Colors.orangeAccent,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Botanical Leaf Corner Accents
  Widget _buildCornerDecorations() {
    return IgnorePointer(
      child: Stack(
        children: [
          // Top Left Leaf Decoration
          Positioned(
            top: -20.h,
            left: -20.w,
            child: Opacity(
              opacity: 0.18,
              child: Icon(
                Icons.eco_rounded,
                size: 90.w,
                color: AppColors.accentGreen,
              ),
            ),
          ),
          // Top Right Leaf Decoration
          Positioned(
            top: -15.h,
            right: -15.w,
            child: Opacity(
              opacity: 0.18,
              child: Icon(
                Icons.spa_rounded,
                size: 80.w,
                color: AppColors.accentGreen,
              ),
            ),
          ),
          // Bottom Left Leaf Decoration
          Positioned(
            bottom: -20.h,
            left: -15.w,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.park_rounded,
                size: 85.w,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          // Bottom Right Leaf Decoration
          Positioned(
            bottom: -20.h,
            right: -20.w,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.eco_rounded,
                size: 90.w,
                color: AppColors.accentGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
