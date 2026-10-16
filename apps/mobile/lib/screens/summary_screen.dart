import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'challenge_screen.dart';

class SummaryScreen extends StatefulWidget {
  final String challengeName;
  final String objectFound;
  final String timeElapsed;
  final int? pointsBefore;
  final int pointsEarned;

  const SummaryScreen({
    super.key,
    this.challengeName = "Misi: Cari Objek",
    this.objectFound = "Buaya",
    this.timeElapsed = "02:45",
    this.pointsBefore,
    this.pointsEarned = 100,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _handlePlayAgain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ChallengeScreen()),
    );
  }

  void _handleBackToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final int currentTotal = provider.totalPoints;
    final int effectivePointsBefore = widget.pointsBefore ?? (currentTotal >= widget.pointsEarned ? currentTotal - widget.pointsEarned : 250);
    final int totalPoints = effectivePointsBefore + widget.pointsEarned;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: _handleBackToHome,
        ),
        centerTitle: true,
        title: Text(
          "Ringkasan",
          style: AppTheme.heading1.copyWith(
            fontSize: 22.sp,
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Subtitle
                Text(
                  "Yay! Kamu telah menyelesaikan tantangan hari ini.",
                  style: AppTheme.body.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                // 1. Top Highlight Achievement Card (Gradient Green)
                _buildAchievementCard(),
                SizedBox(height: 24.h),

                // 2. Activity Summary Detail List
                _buildActivitySummaryCard(effectivePointsBefore, totalPoints),
                SizedBox(height: 32.h),

                // 3. "🔄 Main Lagi" (Play Again) Button
                SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen, // #96B55F
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r), // Pill shape
                      ),
                      elevation: 3,
                    ),
                    onPressed: _handlePlayAgain,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: Text(
                      "Main Lagi",
                      style: AppTheme.heading2.copyWith(
                        fontSize: 18.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                // 4. "🏠 Kembali ke Beranda" (Back to Home) Button
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r), // Pill shape
                      ),
                    ),
                    onPressed: _handleBackToHome,
                    icon: const Icon(Icons.home_outlined, color: AppColors.primaryGreen),
                    label: Text(
                      "Kembali ke Beranda",
                      style: AppTheme.heading2.copyWith(
                        fontSize: 17.sp,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Achievement Card (Gradient Green from #96B55F to #273826 with Tiger mascot)
  Widget _buildAchievementCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentGreen, // #96B55F
            AppColors.primaryGreen, // #273826
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tiger Mascot Illustration on left
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
            ),
            child: const Center(
              child: Text("🐯", style: TextStyle(fontSize: 40)),
            ),
          ),
          SizedBox(width: 16.w),

          // Message & Reward Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Kerja bagus!",
                  style: AppTheme.heading1.copyWith(
                    fontSize: 20.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Terus semangat dan kumpulkan lebih banyak poin!",
                  style: AppTheme.body.copyWith(
                    fontSize: 12.5.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.softYellow,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 16),
                      SizedBox(width: 4.w),
                      Text(
                        "+${widget.pointsEarned} Poin Didapatkan",
                        style: AppTheme.caption.copyWith(
                          fontSize: 11.5.sp,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Activity Summary Detail List
  Widget _buildActivitySummaryCard(int effectivePointsBefore, int totalPoints) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.lightPinkCream,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.neutralGray, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🎯 Tantangan
          _buildSummaryRow(
            icon: Icons.track_changes_rounded,
            label: "Tantangan",
            value: "${widget.challengeName} — 1/1",
          ),
          SizedBox(height: 14.h),

          // 🐊 Objek Ditemukan
          _buildSummaryRow(
            icon: Icons.pets_rounded,
            label: "Objek Ditemukan",
            value: widget.objectFound,
          ),
          SizedBox(height: 14.h),

          // ⏱ Waktu Penyelesaian
          _buildSummaryRow(
            icon: Icons.timer_outlined,
            label: "Waktu Penyelesaian",
            value: widget.timeElapsed,
          ),
          SizedBox(height: 14.h),

          // ⭐ Poin Sebelumnya
          _buildSummaryRow(
            icon: Icons.star_border_rounded,
            label: "Poin Sebelumnya",
            value: "$effectivePointsBefore",
          ),
          SizedBox(height: 14.h),

          // ⭐ Poin Didapatkan
          _buildSummaryRow(
            icon: Icons.stars_rounded,
            label: "Poin Didapatkan",
            value: "+${widget.pointsEarned}",
            valueColor: AppColors.accentGreen,
            isBold: true,
          ),
          SizedBox(height: 16.h),

          // Divider Line
          Container(
            height: 1.5.h,
            color: AppColors.neutralGray,
          ),
          SizedBox(height: 16.h),

          // 🏆 Total Poin with Count-Up Animation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Color(0xFFE6A100), size: 24),
                  SizedBox(width: 8.w),
                  Text(
                    "Total Poin",
                    style: AppTheme.heading2.copyWith(
                      fontSize: 17.sp,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: effectivePointsBefore, end: totalPoints),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, child) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.softYellow,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.accentYellow, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 20),
                        SizedBox(width: 4.w),
                        Text(
                          "$animatedValue",
                          style: AppTheme.heading1.copyWith(
                            fontSize: 18.sp,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18.w, color: AppColors.primaryGreen),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppTheme.body.copyWith(
                fontSize: 13.5.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: AppTheme.body.copyWith(
            fontSize: 14.sp,
            color: valueColor ?? AppColors.primaryGreen,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
