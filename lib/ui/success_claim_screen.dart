import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import 'summary_screen.dart';

class SuccessClaimScreen extends StatefulWidget {
  const SuccessClaimScreen({super.key});

  @override
  State<SuccessClaimScreen> createState() => _SuccessClaimScreenState();
}

class _SuccessClaimScreenState extends State<SuccessClaimScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false).claimPoints(100);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40.h),
              
              // Success Checkmark
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 50.w),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              
              Text(
                "Berhasil!",
                style: GoogleFonts.inter(
                  color: AppColors.primaryGreen,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Tantangan berhasil diselesaikan",
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 32.h),
              
              // Mascot Placeholder
              Container(
                width: 200.w,
                height: 200.w,
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.pets, size: 100.w, color: AppColors.primaryGreen),
                ),
              ),
              SizedBox(height: 32.h),
              
              // Points Box
              Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                padding: EdgeInsets.symmetric(vertical: 24.h),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    Text(
                      "Kamu mendapatkan",
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: AppColors.accentYellow, size: 36.w),
                        SizedBox(width: 8.w),
                        Text(
                          "+100 Poin",
                          style: GoogleFonts.inter(
                            color: AppColors.primaryGreen,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              
              // Dynamic Reward Box (Tukarkan Saldo)
              Consumer<GameProvider>(
                builder: (context, provider, child) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 24.w),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: provider.totalPoints >= 100 ? AppColors.accentYellow : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderCard),
                          ),
                          child: Icon(Icons.card_giftcard, color: AppColors.primaryGreen, size: 24.w),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            provider.totalPoints >= 100 
                                ? "Selamat! Kamu bisa menukarkan Saldo Rp 50.000"
                                : "Terus selesaikan misi lainnya dan kumpulkan lebih banyak poin!",
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 32.h),
              
              // Action Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SummaryScreen()),
                    );
                  },
                  child: Text(
                    "Lanjutkan",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    side: const BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text(
                    "Kembali ke Beranda",
                    style: GoogleFonts.inter(
                      color: AppColors.primaryGreen,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}
