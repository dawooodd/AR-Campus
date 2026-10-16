import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class MisiHarianScreen extends StatefulWidget {
  const MisiHarianScreen({super.key});

  @override
  State<MisiHarianScreen> createState() => _MisiHarianScreenState();
}

class _MisiHarianScreenState extends State<MisiHarianScreen> {
  final List<Map<String, dynamic>> _dailyMissions = [
    {
      "title": "Login Harian Campus Hunto",
      "desc": "Buka aplikasi setiap hari untuk bonus login",
      "points": 50,
      "isClaimed": false,
      "isCompleted": true,
      "progress": "1/1",
      "icon": Icons.calendar_today_rounded,
    },
    {
      "title": "Jelajahi Kampus 500 Meter",
      "desc": "Berjalan mengelilingi area kampus",
      "points": 100,
      "isClaimed": false,
      "isCompleted": true,
      "progress": "500m/500m",
      "icon": Icons.directions_walk_rounded,
    },
    {
      "title": "Selesaikan 1 Sesi Quiz",
      "desc": "Uji wawasan kampusmu di menu Quiz",
      "points": 150,
      "isClaimed": false,
      "isCompleted": false,
      "progress": "0/1",
      "icon": Icons.quiz_rounded,
    },
  ];

  void _claimMission(int index) {
    if (_dailyMissions[index]["isCompleted"] == true && _dailyMissions[index]["isClaimed"] == false) {
      final points = _dailyMissions[index]["points"] as int;
      Provider.of<GameProvider>(context, listen: false).claimPoints(points);

      setState(() {
        _dailyMissions[index]["isClaimed"] = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🎉 Selamat! Kamu berhasil mengklaim +$points Poin."),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      );
    }
  }

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
          "Misi Harian",
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
              // Dragon Banner
              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: AppColors.softYellow,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.neutralGray),
                ),
                child: Row(
                  children: [
                    const Text("🐉", style: TextStyle(fontSize: 38)),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tantangan Harian Baru",
                            style: AppTheme.heading2.copyWith(
                              fontSize: 17.sp,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Selesaikan semua misi sebelum pukul 00:00 untuk bonus harian maksimal!",
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
              SizedBox(height: 24.h),

              Text(
                "Misi Hari Ini",
                style: AppTheme.heading2.copyWith(
                  fontSize: 18.sp,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 14.h),

              // Missions List
              Expanded(
                child: ListView.builder(
                  itemCount: _dailyMissions.length,
                  itemBuilder: (context, index) {
                    final mission = _dailyMissions[index];
                    final bool isCompleted = mission["isCompleted"] as bool;
                    final bool isClaimed = mission["isClaimed"] as bool;

                    return Container(
                      margin: EdgeInsets.only(bottom: 14.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isClaimed ? AppColors.lightPinkCream.withValues(alpha: 0.5) : AppColors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: isClaimed ? AppColors.neutralGray : AppColors.neutralGray.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                        boxShadow: isClaimed
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: isCompleted ? AppColors.softYellow : AppColors.lightPinkCream,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              mission["icon"] as IconData,
                              color: isCompleted ? AppColors.primaryGreen : Colors.grey,
                              size: 24.w,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mission["title"] as String,
                                  style: AppTheme.heading2.copyWith(
                                    fontSize: 15.sp,
                                    color: isClaimed ? Colors.grey : AppColors.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  mission["desc"] as String,
                                  style: AppTheme.body.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  "Progress: ${mission["progress"]}",
                                  style: AppTheme.caption.copyWith(
                                    fontSize: 11.5.sp,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isClaimed
                                  ? AppColors.neutralGray
                                  : isCompleted
                                      ? AppColors.accentGreen
                                      : AppColors.neutralGray,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              elevation: isCompleted && !isClaimed ? 2 : 0,
                            ),
                            onPressed: (isCompleted && !isClaimed) ? () => _claimMission(index) : null,
                            child: Text(
                              isClaimed
                                  ? "Klaim ✅"
                                  : isCompleted
                                      ? "Klaim +${mission["points"]}"
                                      : "+${mission["points"]} Poin",
                              style: AppTheme.caption.copyWith(
                                fontSize: 12.sp,
                                color: (isCompleted && !isClaimed) ? Colors.white : Colors.black54,
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
            ],
          ),
        ),
      ),
    );
  }
}
