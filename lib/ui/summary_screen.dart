import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16.h),
              Text(
                "Ringkasan",
                style: GoogleFonts.inter(
                  color: AppColors.primaryGreen,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Yay! Kamu telah menyelesaikan tantangan hari ini.",
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              
              // Top Highlight Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Row(
                  children: [
                    // Mascot Placeholder
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.pets, size: 50.w, color: AppColors.primaryGreen),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Kerja bagus!",
                            style: GoogleFonts.inter(
                              color: AppColors.primaryGreen,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Terus semangat dan kumpulkan lebih banyak poin!",
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 10.sp,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: AppColors.accentYellow, size: 20.w),
                                SizedBox(width: 4.w),
                                Text(
                                  "+100",
                                  style: GoogleFonts.inter(
                                    color: AppColors.primaryGreen,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              
              // Detail List Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: AppColors.borderCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ringkasan Aktivitas",
                      style: GoogleFonts.inter(
                        color: AppColors.primaryGreen,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildSummaryRow(Icons.my_location, "Tantangan", "Misi: Cari Objek", trailing: "1 / 1"),
                    _buildDivider(),
                    _buildSummaryRow(Icons.check_circle_outline, "Objek Ditemukan", "Buaya", trailing: "1"),
                    _buildDivider(),
                    _buildSummaryRow(Icons.access_time, "Waktu Penyelesaian", "02:45", trailing: "02:45", trailingColor: AppColors.primaryGreen),
                    _buildDivider(),
                    Consumer<GameProvider>(
                      builder: (context, provider, child) {
                        return _buildSummaryRow(
                          Icons.star,
                          "Poin Sebelumnya",
                          "${provider.totalPoints - 100}", // Dummy calc for display
                          trailing: "${provider.totalPoints - 100}",
                        );
                      }
                    ),
                    _buildDivider(),
                    _buildSummaryRow(Icons.star_outline, "Poin Didapatkan", "+100", trailing: "+100"),
                    
                    SizedBox(height: 16.h),
                    // Total Box
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Poin",
                            style: GoogleFonts.inter(
                              color: AppColors.primaryGreen,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star, color: AppColors.accentYellow, size: 24.w),
                              SizedBox(width: 8.w),
                              Consumer<GameProvider>(
                                builder: (context, provider, child) {
                                  return Text(
                                    "${provider.totalPoints}",
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              
              // Buttons
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  // Restart the flow by going to Home
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, color: Colors.white, size: 20.w),
                    SizedBox(width: 8.w),
                    Text(
                      "Main Lagi",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              OutlinedButton(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_outlined, color: AppColors.primaryGreen, size: 20.w),
                    SizedBox(width: 8.w),
                    Text(
                      "Kembali ke Beranda",
                      style: GoogleFonts.inter(
                        color: AppColors.primaryGreen,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String subtitle, {String? trailing, Color? trailingColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 20.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != title && subtitle != "+100" && !subtitle.contains(RegExp(r'^\d+$'))) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
                    ),
                  ),
                ]
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: GoogleFonts.inter(
                color: trailingColor ?? AppColors.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.borderCard,
      thickness: 1,
      height: 16.h,
    );
  }
}
