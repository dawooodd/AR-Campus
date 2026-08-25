import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../theme/app_colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    // 10 seconds duration for splash screen
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_progressController)
      ..addListener(() {
        setState(() {});
      });

    _progressController.forward().then((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent.shade100, // Placeholder for the colorful background
      body: Stack(
        children: [
          // Background Placeholder (Would be an image)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF63B8FF), Color(0xFFE0F2F1)],
                ),
              ),
            ),
          ),
          
          // Mascots Placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield, size: 60.w, color: AppColors.primaryGreen),
                SizedBox(height: 10.h),
                Text(
                  "CAMPUS",
                  style: GoogleFonts.bungee(
                    color: AppColors.primaryGreen,
                    fontSize: 48.sp,
                    shadows: [
                      Shadow(color: Colors.white, blurRadius: 10, offset: Offset(2, 2)),
                    ],
                  ),
                ),
                Text(
                  "HUNT",
                  style: GoogleFonts.bungee(
                    color: AppColors.accentYellow,
                    fontSize: 48.sp,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2)),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    "EXPLORE • LEARN • PLAY",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
                // Characters placeholder
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 60.w, color: Colors.orange),
                    SizedBox(width: 10.w),
                    Icon(Icons.pets, size: 80.w, color: Colors.green),
                    SizedBox(width: 10.w),
                    Icon(Icons.pets, size: 60.w, color: Colors.blue),
                  ],
                ),
              ],
            ),
          ),
          
          // Progress Bar at Bottom
          Positioned(
            bottom: 50.h,
            left: 30.w,
            right: 30.w,
            child: Column(
              children: [
                Text(
                  "MEMUAT PETUALANGAN... ${(_progressAnimation.value * 100).toInt()}%",
                  style: GoogleFonts.inter(
                    color: AppColors.primaryGreen,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  height: 20.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.primaryGreen, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: AppColors.accentYellow, size: 16.w),
                    SizedBox(width: 8.w),
                    Text(
                      "Setiap langkahmu, adalah cerita baru!",
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.star, color: AppColors.accentYellow, size: 16.w),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
