import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'map_screen.dart';

class CariObjekScreen extends StatelessWidget {
  const CariObjekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    final List<Map<String, dynamic>> targetObjects = [
      {
        "title": "Patung Gerbang Kampus",
        "location": "Plaza Utama Depan Rektorat",
        "points": 100,
        "isFound": true,
        "icon": Icons.account_balance_rounded,
      },
      {
        "title": "Prasasti Pendiri 1964",
        "location": "Lobby Gedung Rektorat Lantai 1",
        "points": 150,
        "isFound": false,
        "icon": Icons.history_edu_rounded,
      },
      {
        "title": "Buku Langka Perpustakaan",
        "location": "Perpustakaan Pusat Lantai 3",
        "points": 200,
        "isFound": false,
        "icon": Icons.menu_book_rounded,
      },
      {
        "title": "Pohon Beringin Bersejarah",
        "location": "Taman Inspirasi Tengah Kampus",
        "points": 120,
        "isFound": false,
        "icon": Icons.park_rounded,
      },
    ];

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
          "Cari Objek AR",
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
              // Info Banner
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.softYellow,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: AppColors.neutralGray),
                ),
                child: Row(
                  children: [
                    const Text("🐱", style: TextStyle(fontSize: 32)),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Misi Detektif Kampus",
                            style: AppTheme.heading2.copyWith(
                              fontSize: 16.sp,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Jelajahi kampus dan temukan objek 3D tersembunyi dengan AR!",
                            style: AppTheme.body.copyWith(
                              fontSize: 12.5.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              Text(
                "Daftar Target Objek",
                style: AppTheme.heading2.copyWith(
                  fontSize: 18.sp,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),

              // Object List
              Expanded(
                child: ListView.builder(
                  itemCount: targetObjects.length,
                  itemBuilder: (context, index) {
                    final item = targetObjects[index];
                    final bool isFound = item["isFound"] as bool;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isFound ? AppColors.lightPinkCream.withValues(alpha: 0.6) : AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isFound ? AppColors.accentGreen : AppColors.neutralGray,
                          width: isFound ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: isFound ? AppColors.accentGreen.withValues(alpha: 0.15) : AppColors.lightPinkCream,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item["icon"] as IconData,
                              color: isFound ? AppColors.accentGreen : AppColors.primaryGreen,
                              size: 26.w,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["title"] as String,
                                  style: AppTheme.heading2.copyWith(
                                    fontSize: 15.sp,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  item["location"] as String,
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
                              color: isFound ? AppColors.accentGreen : AppColors.softYellow,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              isFound ? "Ditemukan ✅" : "+${item["points"]} Poin",
                              style: AppTheme.caption.copyWith(
                                fontSize: 11.5.sp,
                                color: isFound ? Colors.white : AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom CTA
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
                      MaterialPageRoute(builder: (context) => const MapScreen()),
                    );
                  },
                  icon: const Icon(Icons.view_in_ar_rounded, color: Colors.white),
                  label: Text(
                    "Buka Kamera & Peta AR",
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
}
