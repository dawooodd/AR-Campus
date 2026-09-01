import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'ar_mission.dart';

class MisiCepatScreen extends StatelessWidget {
  const MisiCepatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          "Misi Cepat",
          style: AppTheme.heading1.copyWith(
            fontSize: 20.sp,
            color: Colors.black,
            fontWeight: FontWeight.bold,
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
                      "${provider.totalPoints}",
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
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mascot Header
              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: AppColors.softYellow,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.neutralGray),
                ),
                child: Row(
                  children: [
                    const Text("🐯", style: TextStyle(fontSize: 38)),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Scan QR Checkpoint",
                            style: AppTheme.heading2.copyWith(
                              fontSize: 17.sp,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Kunjungi pos checkpoint di kampus dan pindai kode QR untuk bonus poin instan!",
                            style: AppTheme.body.copyWith(
                              fontSize: 13.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              Text(
                "Pos Checkpoint Aktif",
                style: AppTheme.heading2.copyWith(
                  fontSize: 18.sp,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 14.h),

              // Checkpoint cards
              _buildCheckpointCard(
                context,
                title: "Pos 1: Perpustakaan Utama",
                desc: "Pindai QR di meja informasi lantai 1",
                points: 100,
                icon: Icons.local_library_rounded,
              ),
              SizedBox(height: 12.h),

              _buildCheckpointCard(
                context,
                title: "Pos 2: Laboratorium Komputer",
                desc: "Pindai QR di depan pintu Lab 3",
                points: 150,
                icon: Icons.computer_rounded,
              ),
              SizedBox(height: 12.h),

              _buildCheckpointCard(
                context,
                title: "Pos 3: Kantin Mahasiswa",
                desc: "Pindai QR di stan kasir utama",
                points: 80,
                icon: Icons.restaurant_rounded,
              ),

              const Spacer(),

              // Scan Button CTA
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ArMissionScreen()),
                    );
                  },
                  icon: const Icon(Icons.view_in_ar_rounded, color: Colors.white),
                  label: Text(
                    "Mulai AR Camera Mission",
                    style: AppTheme.heading2.copyWith(
                      fontSize: 18.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckpointCard(
    BuildContext context, {
    required String title,
    required String desc,
    required int points,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.lightPinkCream,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.neutralGray),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 24.w),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.heading2.copyWith(
                    fontSize: 15.sp,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  desc,
                  style: AppTheme.body.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.softYellow,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              "+$points Poin",
              style: AppTheme.caption.copyWith(
                fontSize: 11.5.sp,
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
